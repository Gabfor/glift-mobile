import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';
import 'package:url_launcher/url_launcher.dart';

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
        final logoSize = constraints.maxWidth * 0.56;
        return Center(
          child: _Logo(size: logoSize),
        );
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
      title: 'Entraînez-vous efficacement et tirer profits de chaque minute d’entraînement',
      description:
          'Nous avons créé une expérience simple et intuitive pour vous permettre d’optimiser votre temps d’entraînement.',
      imageAsset: 'assets/images/onboarding_tracking.svg',
    ),
    const OnboardingPageData(
      tagline: 'OUTIL DE NOTATION',
      title: 'Notez facilement vos performances et assurez-vous de toujours progresser',
      description:
          'Notez vos performances et vos sensations. Ajustez vos entraînements en temps réel ou plus tard afin de toujours progresser.',
      imageAsset: 'assets/images/onboarding_rating.svg',
    ),
    const OnboardingPageData(
      tagline: 'OUTIL DE VISUALISATION',
      title: 'Visualisez votre progression séance après séance et restez motivé pour longtemps',
      description:
          'Visualisez vos progrès dans votre tableau de bord, fixez-vous des objectifs toujours plus ambitieux et sortez de votre zone de confort.',
      imageAsset: 'assets/images/onboarding_visualization.svg',
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
      const SnackBar(
        content: Text('Connexion prochainement disponible.'),
      ),
    );
  }

  Future<void> _openSignup() async {
    final uri = Uri.parse('https://glift.io/tarifs/');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’ouvrir la page d’inscription.')),
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
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: _handlePageChanged,
            itemBuilder: (context, index) {
              final data = _pages[index];
              return OnboardingPage(
                data: data,
                currentPage: _currentPage,
                totalPages: _pages.length,
                onConnectTap: () => _handleConnect(context),
                onSignupTap: _openSignup,
              );
            },
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

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.data,
    required this.currentPage,
    required this.totalPages,
    required this.onConnectTap,
    required this.onSignupTap,
  });

  final OnboardingPageData data;
  final int currentPage;
  final int totalPages;
  final VoidCallback onConnectTap;
  final Future<void> Function() onSignupTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    _PageIndicator(
                      currentPage: currentPage,
                      totalPages: totalPages,
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: SvgPicture.asset(
                        data.imageAsset,
                        width: 300,
                        height: 300,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      data.tagline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
                      style: const TextStyle(
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _gliftBodyColor,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onConnectTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gliftAccentColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 22,
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
                          const Text(
                            'Pas encore inscrit ? ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _gliftBodyColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              onSignupTap();
                            },
                            child: const Text(
                              'Créer un compte',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _gliftAccentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 14 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? _gliftAccentColor
                : _gliftAccentColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
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
    return SvgPicture.asset(
      'assets/images/logo_app.svg',
      width: size,
      height: size,
    );
  }
}
