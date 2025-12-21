import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase/supabase.dart';
import '../models/shop_offer.dart';

class OfferDetailsModal extends StatefulWidget {
  final ShopOffer offer;
  final SupabaseClient supabase;

  const OfferDetailsModal({
    super.key,
    required this.offer,
    required this.supabase,
  });

  @override
  State<OfferDetailsModal> createState() => _OfferDetailsModalState();
}

class _OfferDetailsModalState extends State<OfferDetailsModal> {
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _incrementClick();
  }

  Future<void> _incrementClick() async {
    try {
      await widget.supabase.rpc('increment_offer_click', params: {
        'offer_id': widget.offer.id,
      });
    } catch (e) {
      debugPrint('Error incrementing offer click: $e');
    }
  }

  void _handleCopy() async {
    if (widget.offer.code == null) return;
    await Clipboard.setData(ClipboardData(text: widget.offer.code!));
    HapticFeedback.lightImpact();
    if (mounted) {
      setState(() => _copied = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return "";
    try {
      final date = DateTime.parse(dateString);
      final months = [
        "janvier", "février", "mars", "avril", "mai", "juin",
        "juillet", "août", "septembre", "octobre", "novembre", "décembre"
      ];
      return "${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}";
    } catch (_) {
      return dateString;
    }
  }

  String? _getParsedCondition() {
    String? condition = widget.offer.condition;
    if (condition == null) return null;

    final cleanedSite = (widget.offer.shopWebsite ?? "")
        .replaceFirst(RegExp(r'^https?://'), "")
        .replaceFirst(RegExp(r'^www\.'), "")
        .replaceFirst(RegExp(r'^fr\.'), "")
        .replaceFirst(RegExp(r'/.*$'), "");

    return condition
        .replaceAll(
            RegExp(r'\{date\}', caseSensitive: false), _formatDate(widget.offer.endDate))
        .replaceAll(RegExp(r'\{site\}', caseSensitive: false), cleanedSite);
  }

  Future<void> _launchURL() async {
    final url = widget.offer.shopLink ?? widget.offer.shopWebsite;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsedCondition = _getParsedCondition();
    final isWithCode = widget.offer.modal == "Avec code";

    return Dialog(
      backgroundColor: Colors.transparent,
      alignment: Alignment.bottomCenter,
      insetPadding: const EdgeInsets.fromLTRB(20, 40, 20, 60),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header with close button
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF3A416F),
                      size: 24,
                    ),
                  ),
                ),

                // Brand Logo
                if (widget.offer.brandImage != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 20),
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5D6494).withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        widget.offer.brandImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.store, size: 35),
                      ),
                    ),
                  ),

                // Offer Name
                Text(
                  widget.offer.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    color: const Color(0xFF3A416F),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Instructions
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Comment profiter de cette offre ?",
                        style: GoogleFonts.quicksand(
                          color: const Color(0xFF3A416F),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isWithCode
                            ? "Pour profiter immédiatement de cette offre, copiez le code de réduction ci-dessous et collez-le dans votre panier."
                            : "Aucun code n'est nécessaire pour profiter de cette offre. Cliquez sur le bouton ci-dessous pour être automatiquement redirigé vers le site partenaire.",
                        style: GoogleFonts.quicksand(
                          color: const Color(0xFF5D6494),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Code Field
                if (isWithCode && widget.offer.code != null) ...[
                  GestureDetector(
                    onTap: _handleCopy,
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: const Color(0xFFD7D4DC)),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Text(
                            widget.offer.code!,
                            style: GoogleFonts.quicksand(
                              color: const Color(0xFF5D6494),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Positioned(
                            right: 12,
                            child: SvgPicture.asset(
                              _copied ? 'assets/icons/check.svg' : 'assets/icons/copy.svg',
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                _copied
                                    ? const Color(0xFF00D591)
                                    : const Color(0xFFA1A5FD),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          if (_copied)
                            Positioned(
                              right: 22, // Centered above the 20px icon (12 + 20/2 = 22 for center)
                              top: -45, // Positioned above the icon
                              child: const FractionalTranslation(
                                translation: Offset(0.5, 0),
                                child: _TooltipWithArrow(
                                  backgroundColor: Color(0xFF2D2E32),
                                  label: 'Copié !',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Conditions
                if (parsedCondition != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Conditions de l'offre",
                          style: GoogleFonts.quicksand(
                            color: const Color(0xFF3A416F),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          parsedCondition,
                          style: GoogleFonts.quicksand(
                            color: const Color(0xFF5D6494),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _launchURL,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7069FA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Aller sur le site",
                          style: GoogleFonts.quicksand(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SvgPicture.asset(
                          'assets/icons/arrow.svg',
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TooltipWithArrow extends StatelessWidget {
  final Color backgroundColor;
  final String label;

  const _TooltipWithArrow({required this.backgroundColor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(12, 6),
          painter: _TooltipArrowPainter(backgroundColor),
        ),
      ],
    );
  }
}

class _TooltipArrowPainter extends CustomPainter {
  final Color color;

  const _TooltipArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
