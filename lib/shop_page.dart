import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase/supabase.dart';

import 'repositories/shop_repository.dart';
import 'models/shop_offer.dart';
import 'widgets/glift_page_layout.dart';

class ShopPage extends StatefulWidget {
  final SupabaseClient supabase;

  const ShopPage({super.key, required this.supabase});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late final ShopRepository _repository;
  List<ShopOffer> _offers = [];
  bool _isLoading = true;
  Set<String> _selectedTypes = {};
  String _selectedSort = 'newest'; // 'newest', 'popularity', 'expiration'

  @override
  void initState() {
    super.initState();
    _repository = ShopRepository(widget.supabase);
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    try {
      final offers = await _repository.getShopOffers();
      if (mounted) {
        setState(() {
          _offers = offers;
          _selectedTypes = _availableTypeSet;
          _isLoading = false;
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

  Set<String> get _availableTypeSet =>
      _availableFilters.where((filter) => filter != 'Tous').toSet();

  List<ShopOffer> _filterAndSortOffers({Set<String>? selection}) {
    final appliedSelection = selection ?? _selectedTypes;
    final availableTypes = _availableTypeSet;
    final activeSelection = appliedSelection.intersection(availableTypes);

    var filtered = _offers;

    if (activeSelection.isNotEmpty && activeSelection.length != availableTypes.length) {
      filtered = filtered
          .where((offer) => offer.type.any((t) => activeSelection.contains(t)))
          .toList();
    }

    switch (_selectedSort) {
      case 'newest':
        filtered = [...filtered]
          ..sort((a, b) {
            final dateA = DateTime.tryParse(a.startDate ?? '') ?? DateTime(0);
            final dateB = DateTime.tryParse(b.startDate ?? '') ?? DateTime(0);
            return dateB.compareTo(dateA); // Descending
          });
        break;
      case 'expiration':
        filtered = [...filtered]
          ..sort((a, b) {
            final dateA = DateTime.tryParse(a.endDate ?? '') ?? DateTime(2100);
            final dateB = DateTime.tryParse(b.endDate ?? '') ?? DateTime(2100);
            return dateA.compareTo(dateB); // Ascending (soonest first)
          });
        break;
      case 'popularity':
      default:
        filtered = [...filtered];
        break;
    }

    return filtered;
  }

  List<ShopOffer> get _filteredOffers {
    return _filterAndSortOffers();
  }

  void _openFilters() {
    final availableTypes = _availableTypeSet;
    final initialSelection = _selectedTypes.isEmpty
        ? availableTypes
        : _selectedTypes.intersection(availableTypes);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        Set<String> tempSelection = {...initialSelection};

        return StatefulBuilder(
          builder: (context, setModalState) {
            final previewCount = _filterAndSortOffers(selection: tempSelection).length;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filtres',
                        style: GoogleFonts.quicksand(
                          color: const Color(0xFF3A416F),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() => tempSelection = {...availableTypes});
                        },
                        child: Text(
                          'Réinitialiser',
                          style: GoogleFonts.quicksand(
                            color: const Color(0xFF7069FA),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...availableTypes.map(
                    (type) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: tempSelection.contains(type),
                      onChanged: (checked) {
                        setModalState(() {
                          if (checked ?? false) {
                            tempSelection.add(type);
                          } else {
                            tempSelection.remove(type);
                          }

                          if (tempSelection.isEmpty) {
                            tempSelection = {...availableTypes};
                          }
                        });
                      },
                      title: Text(
                        type,
                        style: GoogleFonts.quicksand(
                          color: const Color(0xFF3A416F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      activeColor: const Color(0xFF7069FA),
                      checkboxShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7069FA),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        setState(() => _selectedTypes = tempSelection);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Afficher $previewCount résultat${previewCount > 1 ? 's' : ''}',
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GliftPageLayout(
      title: 'Glift Shop',
      subtitle: 'Offres régulièrement mises à jour',
      padding: const EdgeInsets.only(top: 20, bottom: 30), // Remove horizontal padding
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offers.isEmpty
              ? Center(
                  child: Text(
                    'Aucune offre trouvée',
                    style: GoogleFonts.quicksand(
                      color: const Color(0xFF3A416F),
                      fontSize: 16,
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
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(color: const Color(0xFFD7D4DC)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedSort,
                                        isExpanded: true,
                                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF3A416F)),
                                        items: const [
                                          DropdownMenuItem(value: 'popularity', child: Text('Pertinence')),
                                          DropdownMenuItem(value: 'newest', child: Text('Nouveauté')),
                                          DropdownMenuItem(value: 'expiration', child: Text('Expiration')),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() => _selectedSort = value);
                                          }
                                        },
                                        selectedItemBuilder: (context) {
                                          return [
                                            'popularity',
                                            'newest',
                                            'expiration'
                                          ].map((String value) {
                                            return Row(
                                              children: [
                                                SvgPicture.asset('assets/icons/tri.svg', width: 20, height: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  value == 'popularity' ? 'Pertinence' :
                                                  value == 'newest' ? 'Nouveauté' : 'Expiration',
                                                  style: GoogleFonts.quicksand(
                                                    color: const Color(0xFF3A416F),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList();
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: _openFilters,
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFD7D4DC)),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: SvgPicture.asset('assets/icons/filtre_red.svg'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SizedBox(height: 20),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 50),
                        itemCount: _filteredOffers.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          return _ShopOfferCard(offer: _filteredOffers[index]);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _FiltersRow extends StatelessWidget {
  const _FiltersRow({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20), // Add padding here
      child: Row(
        children: options
            .map(
              (option) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: FilterChip(
                  label: Text(
                    option,
                    style: GoogleFonts.quicksand(
                      color: selected.contains(option) ? Colors.white : const Color(0xFF3A416F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  selected: selected.contains(option),
                  selectedColor: const Color(0xFF7069FA),
                  backgroundColor: const Color(0xFFF2F1F6),
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                    side: BorderSide.none,
                  ),
                  onSelected: (_) => onSelected(option),
                ),
              ),
            )
            .toList(),
      ),
    );
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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
                            color: const Color(0xFF5D6494).withValues(alpha: 0.25),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

          SizedBox(height: offer.brandImage != null ? 45 : 15),

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
                const SizedBox(height: 20),
                
                // Info Lines
                _buildInfoLine(
                  icon: Icons.check_circle_outline,
                  label: 'Valide depuis le :',
                  value: _formatDate(offer.startDate),
                  valueColor: const Color(0xFF3A416F),
                ),
                const SizedBox(height: 8),
                _ExpirationCountdown(endDateStr: offer.endDate),
                const SizedBox(height: 8),
                _buildShippingInfo(offer.shipping),

                const SizedBox(height: 20),
                
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
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF00D591)), // Using green check for now
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
          const Icon(Icons.cancel_outlined, size: 20, color: Color(0xFFEF4F4E)),
          const SizedBox(width: 8),
          Text(
            'La livraison n’est pas offerte',
            style: GoogleFonts.quicksand(
              color: const Color(0xFFD7D4DC),
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
          const Icon(Icons.check_circle_outline, size: 20, color: Color(0xFF00D591)),
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
          const Icon(Icons.check_circle_outline, size: 20, color: Color(0xFF00D591)),
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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculateTimeLeft());
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
          const Icon(Icons.check_circle_outline, size: 20, color: Color(0xFF00D591)),
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
          const Icon(Icons.cancel_outlined, size: 20, color: Color(0xFFEF4F4E)), // Cross icon
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
      IconData icon = Icons.check_circle_outline;
      Color iconColor = const Color(0xFF00D591);

      if (days <= 3) {
        valueColor = const Color(0xFFF0C863); // Yellowish for warning
        icon = Icons.access_time; // Or specific icon
        iconColor = const Color(0xFFF0C863);
      }

      return Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
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
        const Icon(Icons.access_time, size: 20, color: Color(0xFFEF4F4E)), // Red clock
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
