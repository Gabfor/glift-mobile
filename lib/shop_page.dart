import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';

import 'repositories/shop_repository.dart';
import 'models/shop_offer.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Purple Background Top
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            height: 250,
            child: Container(
              color: const Color(0xFF7069FA),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Glift Shop',
                        style: GoogleFonts.quicksand(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sélection d’offres régulièrement mises à jour',
                        style: GoogleFonts.quicksand(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Filters
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFFD7D4DC)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.only(right: 8),
                                child: const Icon(Icons.sort, size: 20, color: Color(0xFF3A416F)),
                              ),
                              Text(
                                'Nouveauté',
                                style: GoogleFonts.quicksand(
                                  color: const Color(0xFF3A416F),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFFD7D4DC)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.only(right: 8),
                                child: const Icon(Icons.filter_list, size: 20, color: Color(0xFF3A416F)),
                              ),
                              Text(
                                'Voir les filtres',
                                style: GoogleFonts.quicksand(
                                  color: const Color(0xFF3A416F),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Offer List
                Expanded(
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
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                              itemCount: _offers.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 20),
                              itemBuilder: (context, index) {
                                return _ShopOfferCard(offer: _offers[index]);
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
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
