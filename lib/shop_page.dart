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
import 'widgets/glift_pull_to_refresh.dart';
import 'widgets/filter_modal.dart';
import 'widgets/glift_sort_dropdown.dart';
import 'widgets/offer_details_modal.dart';

import 'services/filter_service.dart';
import 'theme/glift_theme.dart';

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
  static const List<Map<String, String>> _sortOptions = [
    {'value': 'relevance', 'label': 'Pertinence'},
    {'value': 'newest', 'label': 'Nouveauté'},
    {'value': 'expiration', 'label': 'Expiration'},
  ];

  late final ShopRepository _repository;
  List<ShopOffer> _offers = [];
  bool _isLoading = true;
  final Set<String> _selectedTypes = {};
  late String _selectedSort;
  Map<String, Set<String>> _filterOptionsBySection = {
    'Sexe': {'Femme', 'Homme'},
    'Sport': {'Boxe', 'Musculation'},
  };

  String? _userGender;
  String? _userGoal;
  String? _userSupplements;

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
    _selectedSort = filterService.shopSort == 'popularity' ? 'relevance' : filterService.shopSort;

    _loadOffers();
    _loadUserProfile();
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

  Future<void> _loadUserProfile() async {
    try {
      final userId = widget.supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await widget.supabase
          .from('profiles')
          .select('gender, main_goal, supplements')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _userGender = data['gender'] as String?;
          _userGoal = data['main_goal'] as String?;
          _userSupplements = data['supplements'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
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

        // Helper to check if we should filter by a section
        bool shouldFilter(String section) {
          if (!selectedFilters.containsKey(section)) return false;
          final selected = selectedFilters[section]!;
          if (selected.isEmpty) return true; // Selected nothing -> matches nothing
          
          final available = _filterOptionsBySection[section] ?? {};
          // If all available options are selected, don't filter (show items even if they don't have the tag)
          if (selected.length == available.length && available.isNotEmpty) return false;
          
          return true;
        }

        // Sexe
        if (shouldFilter('Sexe')) {
          final selected = selectedFilters['Sexe']!;
          if (selected.isEmpty) {
            matches = false;
          } else {
            final gender = offer.gender?.toLowerCase();
            
            // Wildcard check
            final isWildcard = gender != null && 
                (gender == 'tous' || gender == 'mixte' || gender == 'unisexe');

            if (isWildcard) {
               matches = true;
            } else {
               // Match against selection
               if (gender == null || !selected.any((s) => s.toLowerCase() == gender)) {
                 matches = false;
               }
            }
          }
        }

        // Catégorie
        if (matches && shouldFilter('Catégorie')) {
          final selected = selectedFilters['Catégorie']!;
           if (selected.isEmpty) {
            matches = false;
          } else if (!offer.type.any((type) => selected.contains(type))) {
            matches = false;
          }
        }

        // Sport
        if (matches && shouldFilter('Sport')) {
          final selected = selectedFilters['Sport']!;
           if (selected.isEmpty) {
            matches = false;
          } else if (!offer.type.any((type) => selected.contains(type))) {
            matches = false;
          }
        }

        // Boutique
        if (matches && shouldFilter('Boutique')) {
          final selected = selectedFilters['Boutique']!;
           if (selected.isEmpty) {
            matches = false;
          } else if (offer.shop == null || !selected.contains(offer.shop)) {
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
      case 'relevance':
        filtered.sort((a, b) {
          // Rules:
          // 1. Gender: +5 if strict match, +3 if wildcard (for non-binary)
          // 2. Supplements: +5 if user has supplements='Oui' and offer type='Compléments'
          // 3. Boost: +5 if offer.boost is true
          // 4. Expiration: +2 if <= 24h, +1 if <= 72h

          int scoreA = 0;
          int scoreB = 0;

          // 1. Gender Rules
          if (_userGender != null) {
            final userG = _userGender!.toLowerCase();
            
            int getGenderScore(String? offerG) {
              if (offerG == null) return 0;
              final g = offerG.toLowerCase();
              final isWildcard = g == 'tous' || g == 'mixte' || g == 'unisexe';

              if (userG == 'homme') {
                 if (g == 'homme' || isWildcard) return 5;
                 if (g == 'femme') return -5;
              } else if (userG == 'femme') {
                 if (g == 'femme' || isWildcard) return 5;
                 if (g == 'homme') return -5;
              } else if (userG == 'non binaire' || userG == 'non-binaire') {
                 if (isWildcard) return 3;
              }
              return 0;
            }

            scoreA += getGenderScore(a.gender);
            scoreB += getGenderScore(b.gender);
          }

          // 2. Supplements Rule
          if (_userSupplements == 'Oui') {
             if (a.type.any((t) => t.toLowerCase().contains('complément'))) scoreA += 5;
             if (b.type.any((t) => t.toLowerCase().contains('complément'))) scoreB += 5;
          } else if (_userSupplements == 'Non') {
             if (a.type.any((t) => t.toLowerCase().contains('complément'))) scoreA -= 5;
             if (b.type.any((t) => t.toLowerCase().contains('complément'))) scoreB -= 5;
          }

          // 3. Boost Rule
          if (a.boost) scoreA += 5;
          if (b.boost) scoreB += 5;

          // 4. Expiration Rule
          int getExpirationScore(String? endDateStr) {
            if (endDateStr == null) return 0;
            final end = DateTime.tryParse(endDateStr);
            if (end == null) return 0;
            
            final diff = end.difference(DateTime.now());
            if (diff.inHours <= 24 && !diff.isNegative) return 2;
            if (diff.inHours > 24 && diff.inHours <= 72) return 1;
            return 0;
          }

          scoreA += getExpirationScore(a.endDate);
          scoreB += getExpirationScore(b.endDate);

          if (scoreA != scoreB) {
            return scoreB.compareTo(scoreA); // Descending score
          }

          // Tie-breaker 1: Expiration Date (Ascending - ends soonest first)
          final dateA = DateTime.tryParse(a.endDate ?? '') ?? DateTime(2100);
          final dateB = DateTime.tryParse(b.endDate ?? '') ?? DateTime(2100);
          
          final dateCompare = dateA.compareTo(dateB);
          if (dateCompare != 0) {
            return dateCompare;
          }

          // Tie-breaker 2: Name (Alphabetical)
          return a.name.compareTo(b.name);
        });
        break;
      default:
        // Default order
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
      barrierColor: GliftTheme.barrierColor,
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
        scrollable: false,
        title: 'Glift Shop',
        subtitle: 'Offres régulièrement mises à jour',
        padding: EdgeInsets.zero,
        child: GliftPullToRefresh(
          onRefresh: () async {
            await _loadOffers();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              top: 20,
              bottom: 30,
            ),
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
                                        child: GliftSortDropdown(
                                          options: _sortOptions,
                                          selectedValue: _selectedSort,
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedSort = value;
                                              FilterService().shopSort = value;
                                            });
                                          },
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
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 40),
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
                                    supabase: widget.supabase,
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
          ),
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
  final SupabaseClient supabase;

  const _ShopOfferCard({required this.offer, required this.supabase});

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
                  (offer.imageMobile != null && offer.imageMobile!.isNotEmpty)
                      ? offer.imageMobile!
                      : offer.image,
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
                      showDialog(
                        context: context,
                        builder: (context) => OfferDetailsModal(
                          offer: offer,
                          supabase: supabase,
                        ),
                      );
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
