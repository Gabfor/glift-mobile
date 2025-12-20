import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase/supabase.dart';

import 'repositories/shop_repository.dart';
import 'models/shop_offer.dart';
import 'widgets/glift_loader.dart';
import 'widgets/glift_page_layout.dart';
import 'widgets/filter_modal.dart';

import 'services/filter_service.dart';

class ShopPage extends StatefulWidget {
  final SupabaseClient supabase;
  final ValueChanged<bool>? onNavigationVisibilityChanged;

  const ShopPage({
    super.key,
    required this.supabase,
    this.onNavigationVisibilityChanged,
  });

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late final ShopRepository _repository;
  List<ShopOffer> _offers = [];
  bool _isLoading = true;
  final Set<String> _selectedTypes = {};
  late String _selectedSort;
  Map<String, Set<String>> _filterOptionsBySection = {
    'Sexe': {'Femme', 'Homme'},
    'Sport': {'Boxe', 'Musculation'},
  };

  bool _isNavigationVisible = true;
  double _lastScrollOffset = 0;
  Timer? _navigationRevealTimer;

  @override
  void initState() {
    super.initState();
    _repository = ShopRepository(widget.supabase);
    _selectedTypes.add('Tous');

    // Initialize from service
    final filterService = FilterService();
    _selectedFiltersMap = Map.from(filterService.shopFilters);
    _selectedSort = filterService.shopSort;

    _loadOffers();
  }

  @override
  void dispose() {
    _navigationRevealTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOffers() async {
    try {
      final offers = await _repository.getShopOffers();
      final categories = <String>{};
      final shops = <String>{};

      for (final offer in offers) {
        categories.addAll(offer.type.where((t) => t.isNotEmpty));
        if (offer.shop != null && offer.shop!.isNotEmpty) {
          shops.add(offer.shop!);
        }
      }

      if (mounted) {
        setState(() {
          _offers = offers;
          _isLoading = false;
          _filterOptionsBySection = {
            ..._filterOptionsBySection,
            'Catégorie': categories,
            'Boutique': shops,
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading shop offers: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> get _availableFilters {
    final filters = <String>{};

    for (final offer in _offers) {
      filters.addAll(offer.type.where((type) => type.trim().isNotEmpty));
    }

    final sortedFilters = filters.toList()..sort();
    return ['Tous', ...sortedFilters];
  }

  List<ShopOffer> get _filteredOffers {
    return _applyFilters(_selectedFiltersMap);
  }

  List<ShopOffer> _applyFilters(Map<String, Set<String>> selectedFilters) {
    var filtered = List<ShopOffer>.from(_offers);

    // Filter
    if (selectedFilters.isNotEmpty) {
      filtered = filtered.where((offer) {
        bool matches = true;

        // General logic for all filters:
        // If the filter key is present in selectedFilters, it implies the filter is ACTIVE.
        // If the set of selected values for that filter is EMPTY, it means "Match MUST be in {}", which is impossible.
        // So, if key exists && value is empty => match = false.

        // Sexe
        if (selectedFilters.containsKey('Sexe')) {
          if (selectedFilters['Sexe']!.isEmpty) {
            matches = false;
          } else if (!offer.type
              .any((type) => selectedFilters['Sexe']!.contains(type))) {
            matches = false;
          }
        }

        // Catégorie
        if (matches && selectedFilters.containsKey('Catégorie')) {
          if (selectedFilters['Catégorie']!.isEmpty) {
            matches = false;
          } else if (!offer.type
              .any((type) => selectedFilters['Catégorie']!.contains(type))) {
            matches = false;
          }
        }

        // Sport
        if (matches && selectedFilters.containsKey('Sport')) {
          if (selectedFilters['Sport']!.isEmpty) {
            matches = false;
          } else if (!offer.type
              .any((type) => selectedFilters['Sport']!.contains(type))) {
            matches = false;
          }
        }

        // Boutique
        if (matches && selectedFilters.containsKey('Boutique')) {
          if (selectedFilters['Boutique']!.isEmpty) {
            matches = false;
          } else if (offer.shop == null ||
              !selectedFilters['Boutique']!.contains(offer.shop)) {
            matches = false;
          }
        }

        return matches;
      }).toList();
    }

    // Sort
    switch (_selectedSort) {
      case 'newest':
        filtered.sort((a, b) {
          final dateA = DateTime.tryParse(a.startDate ?? '') ?? DateTime(0);
          final dateB = DateTime.tryParse(b.startDate ?? '') ?? DateTime(0);
          return dateB.compareTo(dateA); // Descending
        });
        break;
      case 'expiration':
        filtered.sort((a, b) {
          final dateA = DateTime.tryParse(a.endDate ?? '') ?? DateTime(2100);
          final dateB = DateTime.tryParse(b.endDate ?? '') ?? DateTime(2100);
          return dateA.compareTo(dateB); // Ascending (soonest first)
        });
        break;
      case 'popularity':
      default:
        // Default order (as received from DB or specific logic if available)
        break;
    }

    return filtered;
  }

  void _showFilterModal() {
    final sections = [
      FilterSection(
        title: 'Sexe',
        options: (_filterOptionsBySection['Sexe'] ?? {}).toList()..sort(),
      ),
      FilterSection(
        title: 'Catégorie',
        options: (_filterOptionsBySection['Catégorie'] ?? {}).toList()..sort(),
      ),
      FilterSection(
        title: 'Sport',
        options: (_filterOptionsBySection['Sport'] ?? {}).toList()..sort(),
      ),
      FilterSection(
        title: 'Boutique',
        options: (_filterOptionsBySection['Boutique'] ?? {}).toList()..sort(),
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterModal(
        sections: sections,
        selectedFilters: _selectedFiltersMap,
        computeResults: (filters) => _applyFilters(filters).length,
        onApply: (selected) {
          setState(() {
            _selectedFiltersMap = selected;
            FilterService().shopFilters = selected; // Persist
          });
        },
      ),
    );
  }

  Map<String, Set<String>> _selectedFiltersMap = {};

  bool get _hasActiveFilters {
    for (final entry in _selectedFiltersMap.entries) {
      final options = _filterOptionsBySection[entry.key];
      final isFiltering = options == null
          ? entry.value.isNotEmpty
          : entry.value.length != options.length;
      if (isFiltering) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isScrollable = !_isLoading && _offers.isNotEmpty && _filteredOffers.isNotEmpty;

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: GliftPageLayout(
        scrollable: isScrollable,
        title: 'Glift Shop',
        subtitle: 'Offres régulièrement mises à jour',
        padding: const EdgeInsets.only(
          top: 20,
          bottom: 30,
        ), // Remove horizontal padding
        child: _isLoading
            ? const GliftLoader()
            : _offers.isEmpty
                ? Center(
                    child: Text(
                      'Aucune offre disponible',
                      style: GoogleFonts.quicksand(
                        color: const Color(0xFFC2BFC6),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_availableFilters.length > 1) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Trier par',
                                  style: GoogleFonts.quicksand(
                                    color: const Color(0xFF3A416F),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 40,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: const Color(0xFFD7D4DC),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: _selectedSort,
                                                isExpanded: true,
                                                icon: const SizedBox.shrink(),
                                                items: [
                                                  DropdownMenuItem(
                                                    value: 'popularity',
                                                    child: Text(
                                                      'Pertinence',
                                                      style: GoogleFonts.quicksand(
                                                        color: const Color(
                                                          0xFF3A416F,
                                                        ),
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'newest',
                                                    child: Text(
                                                      'Nouveauté',
                                                      style: GoogleFonts.quicksand(
                                                        color: const Color(
                                                          0xFF3A416F,
                                                        ),
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'expiration',
                                                    child: Text(
                                                      'Expiration',
                                                      style: GoogleFonts.quicksand(
                                                        color: const Color(
                                                          0xFF3A416F,
                                                        ),
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                onChanged: (value) {
                                                  if (value != null) {
                                                    setState(() {
                                                      _selectedSort = value;
                                                      FilterService().shopSort =
                                                          value; // Persist
                                                    });
                                                  }
                                                },
                                                selectedItemBuilder: (context) {
                                                  return [
                                                    'popularity',
                                                    'newest',
                                                    'expiration',
                                                  ].map((String value) {
                                                    return Row(
                                                      children: [
                                                        SvgPicture.asset(
                                                          'assets/icons/tri.svg',
                                                          width: 15,
                                                          height: 15,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          value == 'popularity'
                                                              ? 'Pertinence'
                                                              : value ==
                                                                      'newest'
                                                                  ? 'Nouveauté'
                                                                  : 'Expiration',
                                                          style: GoogleFonts
                                                              .quicksand(
                                                            color: const Color(
                                                              0xFF3A416F,
                                                            ),
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  }).toList();
                                                },
                                              ),
                                            ),
                                          ),
                                          SvgPicture.asset(
                                            'assets/icons/chevron.svg',
                                            width: 9,
                                            height: 7,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () {
                                      _showFilterModal();
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFD7D4DC),
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      child: SvgPicture.asset(
                                        _hasActiveFilters
                                            ? 'assets/icons/filtre_green.svg'
                                            : 'assets/icons/filtre_red.svg',
                                        height: 16,
                                        width: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (_filteredOffers.isEmpty)
                        Expanded(
                          child: Center(
                            child: Text(
                              'Aucune offre disponible',
                              style: GoogleFonts.quicksand(
                                color: const Color(0xFFC2BFC6),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 50),
                            itemCount: _filteredOffers.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 20),
                            itemBuilder: (context, index) {
                              return _ShopOfferCard(
                                offer: _filteredOffers[index],
                              );
                            },
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final currentOffset = max(notification.metrics.pixels, 0.0).toDouble();

      if (currentOffset <= 0) {
        _lastScrollOffset = 0;
        if (!_isNavigationVisible) {
          _isNavigationVisible = true;
          widget.onNavigationVisibilityChanged?.call(true);
        }
        _navigationRevealTimer?.cancel();
        return false;
      }

      final delta = currentOffset - _lastScrollOffset;

      if (delta > 10 && _isNavigationVisible) {
        _isNavigationVisible = false;
        widget.onNavigationVisibilityChanged?.call(false);
        _scheduleNavigationReveal();
      } else if (delta < -10 && !_isNavigationVisible) {
        _isNavigationVisible = true;
        widget.onNavigationVisibilityChanged?.call(true);
        _navigationRevealTimer?.cancel();
      }

      _lastScrollOffset = currentOffset;
    }

    return false;
  }

  void _scheduleNavigationReveal() {
    _navigationRevealTimer?.cancel();
    _navigationRevealTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && !_isNavigationVisible) {
        _isNavigationVisible = true;
        widget.onNavigationVisibilityChanged?.call(true);
      }
    });
  }
}



class _ShopOfferCard extends StatelessWidget {
  final ShopOffer offer;

  const _ShopOfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD7D4DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: Image.network(
                  offer.image,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Center(child: Icon(Icons.image_not_supported)),
                  ),
                ),
              ),
              if (offer.brandImage != null)
                Positioned(
                  bottom: -35,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF5D6494,
                            ).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          offer.brandImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.store),
                        ),
                      ),
                    ),
                  ),
                ),
              if (offer.premium)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF7069FA),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      'PREMIUM',
                      style: GoogleFonts.quicksand(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: offer.brandImage != null ? 30 : 0),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.name.toUpperCase(),
                  style: GoogleFonts.quicksand(
                    color: const Color(0xFF3A416F),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: offer.type.map((t) => _buildTag(t)).toList(),
                ),
                const SizedBox(height: 15),

                // Info Lines
                _buildInfoLine(
                  iconAsset: 'assets/icons/check_green.svg',
                  label: 'Valide depuis le :',
                  value: _formatDate(offer.startDate),
                  valueColor: const Color(0xFF3A416F),
                ),
                const SizedBox(height: 8),
                _ExpirationCountdown(endDateStr: offer.endDate),
                const SizedBox(height: 8),
                _buildShippingInfo(offer.shipping),

                const SizedBox(height: 15),

                // Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement offer click logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7069FA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Profiter de cette offre',
                      style: GoogleFonts.quicksand(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5FE),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: GoogleFonts.redHatText(
          color: const Color(0xFFA1A5FD),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoLine({
    required String iconAsset,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        _buildStatusIcon(iconAsset),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.quicksand(
            color: const Color(0xFF5D6494),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.quicksand(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildShippingInfo(String? shipping) {
    if (shipping == null || shipping.isEmpty) {
      return Row(
        children: [
          _buildStatusIcon('assets/icons/check_grey.svg'),
          const SizedBox(width: 8),
          Text(
            'La livraison n’est pas offerte',
            style: GoogleFonts.quicksand(
              color: const Color(0xFF5D6494),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    final shippingValue = double.tryParse(shipping.replaceAll(',', '.'));

    if (shippingValue == 0) {
      return Row(
        children: [
          _buildStatusIcon('assets/icons/check_green.svg'),
          const SizedBox(width: 8),
          Text(
            'Livraison offerte',
            style: GoogleFonts.quicksand(
              color: const Color(0xFF5D6494),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (shippingValue != null && shippingValue > 0) {
      return Row(
        children: [
          _buildStatusIcon('assets/icons/check_green.svg'),
          const SizedBox(width: 8),
          Text(
            'Livraison offerte à partir de :',
            style: GoogleFonts.quicksand(
              color: const Color(0xFF5D6494),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '${shippingValue.toStringAsFixed(shippingValue.truncateToDouble() == shippingValue ? 0 : 2)} €',
            style: GoogleFonts.quicksand(
              color: const Color(0xFF3A416F),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildStatusIcon(String assetPath) {
    return SvgPicture.asset(assetPath, width: 20, height: 20);
  }
}

class _ExpirationCountdown extends StatefulWidget {
  final String? endDateStr;

  const _ExpirationCountdown({required this.endDateStr});

  @override
  State<_ExpirationCountdown> createState() => _ExpirationCountdownState();
}

class _ExpirationCountdownState extends State<_ExpirationCountdown> {
  Timer? _timer;
  Duration? _timeLeft;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _calculateTimeLeft(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateTimeLeft() {
    if (widget.endDateStr == null) return;
    try {
      final endDate = DateTime.parse(widget.endDateStr!);
      final now = DateTime.now();
      final difference = endDate.difference(now);

      if (mounted) {
        setState(() {
          _timeLeft = difference;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (widget.endDateStr == null) {
      return Row(
        children: [
          SvgPicture.asset(
            'assets/icons/check_green.svg',
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Aucune date d\'expiration',
            style: GoogleFonts.quicksand(
              color: const Color(0xFF5D6494),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (_timeLeft == null || _timeLeft!.isNegative) {
      return Row(
        children: [
          SvgPicture.asset('assets/icons/check_red.svg', width: 20, height: 20),
          const SizedBox(width: 8),
          Text(
            'Offre expirée',
            style: GoogleFonts.quicksand(
              color: const Color(0xFF5D6494),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    final days = _timeLeft!.inDays;

    if (days >= 1) {
      Color valueColor = const Color(0xFF3A416F);
      String iconAsset = 'assets/icons/check_green.svg';

      if (days <= 3) {
        valueColor = const Color(0xFFF0C863); // Yellowish for warning
        iconAsset = 'assets/icons/check_yellow.svg';
      }

      return Row(
        children: [
          SvgPicture.asset(iconAsset, width: 20, height: 20),
          const SizedBox(width: 8),
          Text(
            'L’offre expire dans :',
            style: GoogleFonts.quicksand(
              color: const Color(0xFF5D6494),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '$days jours',
            style: GoogleFonts.quicksand(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    // Less than 1 day
    final hours = _timeLeft!.inHours;
    final minutes = _timeLeft!.inMinutes % 60;
    final seconds = _timeLeft!.inSeconds % 60;

    return Row(
      children: [
        SvgPicture.asset('assets/icons/check_red.svg', width: 20, height: 20),
        const SizedBox(width: 8),
        Text(
          'L’offre expire dans :',
          style: GoogleFonts.quicksand(
            color: const Color(0xFF5D6494),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s',
          style: GoogleFonts.quicksand(
            color: const Color(0xFFEF4F4E),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
