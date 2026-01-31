import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:glift_mobile/login_page.dart';
import 'package:glift_mobile/auth/auth_repository.dart';
import 'package:glift_mobile/auth/biometric_auth_service.dart';
import 'package:glift_mobile/widgets/connect_button.dart';
import 'package:glift_mobile/widgets/embedded_raster_image.dart';
import 'package:glift_mobile/theme/glift_theme.dart';

import 'supabase_credentials.dart';
import 'package:supabase/supabase.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  debugPrint('DEBUG: Starting main()');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('DEBUG: WidgetsFlutterBinding initialized');
  
  await initializeDateFormatting('fr_FR', null);
  debugPrint('DEBUG: Date formatting initialized');
  
  await NotificationService.instance.initialize();
  debugPrint('DEBUG: NotificationService initialized');
  
  await SettingsService.instance.init();
  debugPrint('DEBUG: SettingsService initialized');
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  debugPrint('DEBUG: Orientation set');

  final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);
  debugPrint('DEBUG: Supabase client created');

  SettingsService.instance.initSupabase(supabase);
  
  final authRepository = SupabaseAuthRepository(supabase);
  final biometricAuthService = BiometricAuthService(
    supabase: supabase,
    localAuth: LocalAuthentication(),
    secureStorage: const FlutterSecureStorage(),
  );
  debugPrint('DEBUG: Services created, calling runApp');

  runApp(GliftApp(
    supabase: supabase,
    authRepository: authRepository,
    biometricAuthService: biometricAuthService,
  ));
  debugPrint('DEBUG: runApp called');
}

class GliftApp extends StatelessWidget {
  const GliftApp({
    super.key,
    required this.supabase,
    required this.authRepository,
    required this.biometricAuthService,
  });

  final SupabaseClient supabase;
  final AuthRepository authRepository;
  final BiometricAuthService biometricAuthService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glift',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      theme: GliftTheme.buildTheme(),
      home: SplashToOnboarding(
        supabase: supabase,
        authRepository: authRepository,
        biometricAuthService: biometricAuthService,
      ),
    );
  }
}

class SplashToOnboarding extends StatefulWidget {
  const SplashToOnboarding({
    super.key,
    required this.supabase,
    required this.authRepository,
    required this.biometricAuthService,
  });

  final SupabaseClient supabase;
  final AuthRepository authRepository;
  final BiometricAuthService biometricAuthService;

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

    return OnboardingFlow(
      authRepository: widget.authRepository,
      supabase: widget.supabase,
      biometricAuthService: widget.biometricAuthService,
    );
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
  const OnboardingFlow({
    super.key,
    required this.authRepository,
    required this.supabase,
    required this.biometricAuthService,
  });

  final AuthRepository authRepository;
  final SupabaseClient supabase;
  final BiometricAuthService biometricAuthService;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isConnecting = false;

  static final List<OnboardingPageData> _pages = [
    const OnboardingPageData(
      tagline: 'OUTIL DE CRÉATION',
      title: 'Créez et personnalisez facilement vos programmes de musculation',
      description:
          'Créez vos programmes de musculation rapidement ou optez pour un de nos programmes prêt à l\'emploi.',
      imageAsset: 'assets/images/onboarding_creer.svg',
      imageScale: 1.35,
    ),
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
          'Notez vos performances et vos sensations. Ajustez vos entraînements afin de toujours progresser.',
      imageAsset: 'assets/images/onboarding_noter.svg',
    ),
    const OnboardingPageData(
      tagline: 'OUTIL DE VISUALISATION',
      title:
          'Visualisez votre progression séance après séance et restez motivé pour longtemps',
      description:
          'Visualisez vos progrès dans votre tableau de bord, soyez toujours plus ambitieux et sortez de votre zone de confort.',
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

  Future<void> _handleConnect(BuildContext context) async {
    HapticFeedback.lightImpact();
    setState(() {
      _isConnecting = true;
    });

    // Allow the UI to display the loading state before navigating away
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LoginPage(
            authRepository: widget.authRepository,
            supabase: widget.supabase,
            biometricAuthService: widget.biometricAuthService,
          ),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
      });
    }
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mediaQuery = MediaQuery.of(context);
            final bottomPadding = mediaQuery.padding.bottom;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                0,
                24,
                bottomPadding,
              ),
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
                  const SizedBox(height: 5),
                  _PageIndicator(
                    currentPage: _currentPage,
                    totalPages: _pages.length,
                  ),
                  const SizedBox(height: 25),
                  ConnectButton(
                    isEnabled: !_isConnecting,
                    isLoading: _isConnecting,
                    onPressed: () => _handleConnect(context),
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
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: _openSignup,
                          child: Text(
                            'Créer un compte',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: GliftTheme.accent,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
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
    this.imageScale,
  });

  final String tagline;
  final String title;
  final String description;
  final String imageAsset;
  final double? imageScale;
}

class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({super.key, required this.data});

  final OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final availableWidth = constraints.maxWidth;





        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                SizedBox(
                  height: 340,
                  child: Center(
                    child: Transform.scale(
                      scale: data.imageScale ?? 1.0,
                      child: EmbeddedRasterImage(
                        svgAsset: data.imageAsset,
                        width: 320,
                        height: 320,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 42),
                Text(
                  data.tagline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  data.description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: (availableHeight * 0.05).clamp(16.0, 32.0)),
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
            color: isActive
                ? GliftTheme.pageIndicatorActive
                : GliftTheme.pageIndicatorInactive,
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
    final logoUrl = SettingsService.instance.getLogoUrl();

    Widget logo;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      if (logoUrl.toLowerCase().endsWith('.svg')) {
        logo = SvgPicture.network(
          logoUrl,
          fit: BoxFit.contain,
          placeholderBuilder: (BuildContext context) => SvgPicture.asset(
            'assets/images/logo_app.svg',
            fit: BoxFit.contain,
          ),
        );
      } else {
         logo = Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return SvgPicture.asset(
              'assets/images/logo_app.svg',
              fit: BoxFit.contain,
            );
          },
        );
      }
    } else {
      logo = SvgPicture.asset(
        'assets/images/logo_app.svg',
        fit: BoxFit.contain,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: logo,
    );
  }
}
