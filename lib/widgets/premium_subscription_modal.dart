import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/settings_service.dart';

class PremiumSubscriptionModal extends StatelessWidget {
  const PremiumSubscriptionModal({super.key});

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://glift.io/compte#mon-abonnement');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasUsedTrial = SettingsService.instance.getHasUsedTrial();
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Diamond Icon from glift-web
                Center(
                  child: SvgPicture.string(
                    '''<svg width="42" height="35" viewBox="0 0 42 35" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M11.1927 11H0.756078C0.539324 11 0.425271 10.743 0.570694 10.5823L9.33524 0.895144C9.47734 0.73808 9.73815 0.817837 9.76811 1.02752L11.1927 11Z" fill="#FFF7CB" stroke="#E2BA00"/>
                      <path d="M30.1927 11H40.6294C40.8462 11 40.9602 10.743 40.8148 10.5823L32.0503 0.895144C31.9082 0.73808 31.6473 0.817837 31.6174 1.02752L30.1927 11Z" fill="#FFF7CB" stroke="#E2BA00"/>
                      <path d="M11.1927 11H0.751428C0.535405 11 0.421072 11.2555 0.565015 11.4166L20.1829 33.3699C20.3713 33.5808 20.7101 33.3657 20.5993 33.1054L11.1927 11Z" fill="#FFED85" stroke="#E2BA00"/>
                      <path d="M30.1927 11H40.6341C40.8501 11 40.9644 11.2555 40.8205 11.4166L21.2026 33.3699C21.0142 33.5808 20.6754 33.3657 20.7862 33.1054L30.1927 11Z" fill="#FFED85" stroke="#E2BA00"/>
                      <path d="M30.1927 11H11.1927L20.4632 32.4685C20.5501 32.6697 20.8354 32.6697 20.9223 32.4685L30.1927 11Z" fill="#FFF3AD" stroke="#E2BA00"/>
                      <path d="M31.4045 0.5H9.981C9.82886 0.5 9.712 0.634747 9.73351 0.785356L11.1927 11H30.1927L31.652 0.785355C31.6735 0.634747 31.5566 0.5 31.4045 0.5Z" fill="#FFF3AD" stroke="#E2BA00"/>
                      <path d="M30.6927 11H10.6927L20.5117 0.690086C20.6102 0.586638 20.7753 0.586638 20.8738 0.690086L30.6927 11Z" fill="#FFF7CB" stroke="#E2BA00"/>
                    </svg>''',
                    height: 35,
                    width: 42,
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  'Abonnement Premium',
                  style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3A416F),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '2,49 €',
                      style: GoogleFonts.quicksand(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF3A416F),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/mois',
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A416F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Features list
                _buildFeatureItem(
                  boldText: 'Un nombre illimité',
                  normalText: ' d’entraînements',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  boldText: 'Un nombre illimité',
                  normalText: ' d’exercices',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  boldText: '',
                  normalText: 'Un tableau de bord personnalisé',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  boldText: 'Accès aux programmes du Glift Store',
                  normalText: '',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  boldText: 'Accès aux bons plans de la Glift Shop',
                  normalText: '',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  boldText: '',
                  normalText: 'Annulation gratuite à tout moment',
                ),
                const SizedBox(height: 28),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _launchURL();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7069FA),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Tester gratuitement',
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                if (!hasUsedTrial) ...[
                  const SizedBox(height: 12),
                  // Trial subtext
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '30 jours pour tester, puis 2,49 € /mois',
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5D6494),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Close Button (Top Right)
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              icon: const Icon(Icons.close),
              color: const Color(0xFF3A416F),
              iconSize: 24,
              onPressed: () => Navigator.of(context).pop(),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required String boldText,
    required String normalText,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.string(
          '''<svg width="30" height="30" viewBox="0 0 30 30" fill="none" xmlns="http://www.w3.org/2000/svg">
            <mask id="mask0_180_650" style="mask-type:luminance" maskUnits="userSpaceOnUse" x="6" y="8" width="18" height="14">
              <path fill-rule="evenodd" clip-rule="evenodd" d="M6 14.6866C8.1791 16.8657 10.3433 19.0299 12.4328 21.1194C15.9701 17.597 19.5522 14.0448 23.1045 10.5075C22.3134 9.70149 21.4776 8.8806 20.6119 8C17.8955 10.7164 15.1791 13.4328 12.3881 16.2239C11.0746 14.8955 9.74627 13.5821 8.43284 12.2687C7.62687 13.0746 6.80597 13.8806 6 14.6866Z" fill="white"/>
            </mask>
            <g mask="url(#mask0_180_650)">
              <rect width="30" height="30" fill="#00D591"/>
            </g>
          </svg>''',
          width: 24,
          height: 24,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  color: const Color(0xFF5D6494),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                children: [
                  if (boldText.isNotEmpty)
                    TextSpan(
                      text: boldText,
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3A416F),
                      ),
                    ),
                  if (normalText.isNotEmpty)
                    TextSpan(
                      text: normalText,
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5D6494),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
