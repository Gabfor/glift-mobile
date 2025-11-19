import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:glift_mobile/widgets/embedded_raster_image.dart';

import 'supabase_credentials.dart';

const _gliftBackgroundColor = Color(0xFFF9FAFB);
const _gliftAccentColor = Color(0xFF7069FA);
const _gliftTitleColor = Color(0xFF3A416F);
const _gliftBodyColor = Color(0xFF5D6494);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);

  runApp(GliftApp(supabase: supabase));
}

class GliftApp extends StatelessWidget {
  const GliftApp({super.key, required this.supabase});

  final SupabaseClient supabase;

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _gliftAccentColor,
        surface: _gliftBackgroundColor,
      ),
      scaffoldBackgroundColor: _gliftBackgroundColor,
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Glift',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.quicksandTextTheme(baseTheme.textTheme),
      ),
      home: SplashToOnboarding(supabase: supabase),
    );
  }
}

class SplashToOnboarding extends StatefulWidget {
  const SplashToOnboarding({super.key, required this.supabase});

  final SupabaseClient supabase;

  @override
  State<SplashToOnboarding> createState() => _SplashToOnboardingState();
}

class _SplashToOnboardingState extends State<SplashToOnboarding> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    debugPrint('Supabase client ready: $supabaseUrl');
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    return const OnboardingFlow();
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _gliftBackgroundColor,
      body: _SplashLogo(),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const maxLogoSize = 220.0;
        final availableWidth = constraints.maxWidth * 0.6;
        final availableHeight = constraints.maxHeight;
        final logoSize = math.min(
          maxLogoSize,
          math.min(availableWidth, availableHeight),
        );
        return Center(child: _Logo(size: logoSize));
      },
    );
  }
}

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static final List<OnboardingPageData> _pages = [
    const OnboardingPageData(
      tagline: 'OUTIL DE SUIVI',
      title:
          'Entraînez-vous efficacement et tirer profits de chaque minute d’entraînement',
      description:
          'Nous avons créé une expérience simple et intuitive pour vous permettre d’optimiser votre temps d’entraînement.',
      imageAsset: 'assets/images/onboarding_suivre.svg',
    ),
    const OnboardingPageData(
      tagline: 'OUTIL DE NOTATION',
      title:
          'Notez facilement vos performances et assurez-vous de toujours progresser',
      description:
          'Notez vos performances et vos sensations. Ajustez vos entraînements en temps réel ou plus tard afin de toujours progresser.',
      imageAsset: 'assets/images/onboarding_noter.svg',
    ),
    const OnboardingPageData(
      tagline: 'OUTIL DE VISUALISATION',
      title:
          'Visualisez votre progression séance après séance et restez motivé pour longtemps',
      description:
          'Visualisez vos progrès dans votre tableau de bord, fixez-vous des objectifs toujours plus ambitieux et sortez de votre zone de confort.',
      imageAsset: 'assets/images/onboarding_visualiser.svg',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handlePageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _handleConnect(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connexion prochainement disponible.')),
    );
  }

  Future<void> _openSignup() async {
    final uri = Uri.parse('https://glift.io/tarifs/');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d’ouvrir la page d’inscription.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _gliftBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: _handlePageChanged,
                  itemBuilder: (context, index) {
                    final data = _pages[index];
                    return OnboardingSlide(data: data);
                  },
                ),
              ),
              const SizedBox(height: 24),
              _PageIndicator(
                currentPage: _currentPage,
                totalPages: _pages.length,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _handleConnect(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gliftAccentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    textStyle:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ) ??
                            const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                  child: const Text('Se connecter'),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Pas encore inscrit ? ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _gliftBodyColor,
                          ) ??
                          const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _gliftBodyColor,
                          ),
                    ),
                    GestureDetector(
                      onTap: _openSignup,
                      child: Text(
                        'Créer un compte',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _gliftAccentColor,
                                ) ??
                                const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _gliftAccentColor,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPageData {
  const OnboardingPageData({
    required this.tagline,
    required this.title,
    required this.description,
    required this.imageAsset,
  });

  final String tagline;
  final String title;
  final String description;
  final String imageAsset;
}

class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({super.key, required this.data});

  final OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 100),
                Center(
                  child: EmbeddedRasterImage(
                    svgAsset: data.imageAsset,
                    width: 300,
                    height: 300,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  data.tagline,
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: _gliftAccentColor,
                      ) ??
                      const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: _gliftAccentColor,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _gliftTitleColor,
                        height: 1.3,
                      ) ??
                      const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _gliftTitleColor,
                        height: 1.3,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  data.description,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _gliftBodyColor,
                        height: 1.5,
                      ) ??
                      const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _gliftBodyColor,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.currentPage, required this.totalPages});

  final int currentPage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final bool isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color:
                isActive ? const Color(0xFFA1A5FD) : const Color(0xFFECE9F1),
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        'assets/images/logo_app.svg',
        fit: BoxFit.contain,
      ),
    );
  }
}
