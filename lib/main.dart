import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:glift_mobile/login_page.dart';
import 'package:glift_mobile/auth/auth_repository.dart';
import 'package:glift_mobile/widgets/embedded_raster_image.dart';
import 'package:glift_mobile/theme/glift_theme.dart';

import 'supabase_credentials.dart';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);
  final authRepository = SupabaseAuthRepository(supabase);

  runApp(GliftApp(
    supabase: supabase,
    authRepository: authRepository,
  ));
}

class GliftApp extends StatelessWidget {
  const GliftApp({
    super.key,
    required this.supabase,
    required this.authRepository,
  });

  final SupabaseClient supabase;
  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glift',
      debugShowCheckedModeBanner: false,
      theme: GliftTheme.buildTheme(),
      home: SplashToOnboarding(
        supabase: supabase,
        authRepository: authRepository,
      ),
    );
  }
}

class SplashToOnboarding extends StatefulWidget {
  const SplashToOnboarding({
    super.key,
    required this.supabase,
    required this.authRepository,
  });

  final SupabaseClient supabase;
  final AuthRepository authRepository;

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

    return OnboardingFlow(authRepository: widget.authRepository);
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
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
  const OnboardingFlow({super.key, required this.authRepository});

  final AuthRepository authRepository;

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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginPage(authRepository: widget.authRepository),
      ),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: GliftTheme.onboardingBackground,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 48,
                    child: SvgPicture.asset('assets/images/logo_app.svg'),
                  ),
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 12),
                _PageIndicator(
                  currentPage: _currentPage,
                  totalPages: _pages.length,
                ),
                const SizedBox(height: 28),
                GliftPrimaryButton(
                  label: 'Se connecter',
                  onPressed: () => _handleConnect(context),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Pas encore inscrit ? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: _openSignup,
                        child: Text(
                          'Créer un compte',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: GliftTheme.accent,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: GliftTheme.cardShadow,
                        blurRadius: 30,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Center(
                      child: EmbeddedRasterImage(
                        svgAsset: data.imageAsset,
                        width: 240,
                        height: 240,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  data.tagline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
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
          width: isActive ? 26 : 10,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? GliftTheme.pageIndicatorActive
                : GliftTheme.pageIndicatorInactive,
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}

class GliftPrimaryButton extends StatelessWidget {
  const GliftPrimaryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: GliftTheme.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33403F68),
              blurRadius: 18,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPressed,
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
      ),
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
