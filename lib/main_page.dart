import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';
import 'home_page.dart';
import 'dashboard_page.dart';
import 'store_page.dart';
import 'shop_page.dart';
import 'settings_page.dart';
import 'auth/auth_repository.dart';
import 'auth/biometric_auth_service.dart';
import 'services/offline_sync_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({
    super.key,
    required this.supabase,
    required this.authRepository,
    required this.biometricAuthService,
    this.initialProgramId,
    this.initialTrainingId,
    this.initialIndex,
  });

  final SupabaseClient supabase;
  final AuthRepository authRepository;
  final BiometricAuthService biometricAuthService;
  final String? initialProgramId;
  final String? initialTrainingId;
  final int? initialIndex;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int _currentIndex = 1; // Default to 'Séances'
  bool _isBottomNavVisible = true;
  final GlobalKey<DashboardPageState> _dashboardKey = GlobalKey();
  final GlobalKey<HomePageState> _homeKey = GlobalKey();

  final Set<int> _loadedTabs = {};
  final Map<int, Widget> _pageCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _triggerSync();
    
    // Use Dashboard as default if an initial program ID is provided
    if (widget.initialIndex != null) {
      _currentIndex = widget.initialIndex!;
    } else if (widget.initialProgramId != null) {
      _currentIndex = 0;
    }
    _loadedTabs.add(_currentIndex);
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return DashboardPage(
          key: _dashboardKey,
          supabase: widget.supabase,
          authRepository: widget.authRepository,
          biometricAuthService: widget.biometricAuthService,
          initialProgramId: widget.initialProgramId,
          initialTrainingId: widget.initialTrainingId,
          onNavigationVisibilityChanged: _handleNavigationVisibilityChanged,
          onNavigateToStore: _navigateToStore,
        );
      case 1:
        return HomePage(
          key: _homeKey,
          supabase: widget.supabase,
          authRepository: widget.authRepository,
          biometricAuthService: widget.biometricAuthService,
          initialProgramId: widget.initialProgramId,
          onNavigateToDashboard: _navigateToDashboard,
          onNavigationVisibilityChanged: _handleNavigationVisibilityChanged,
          onNavigateToStore: _navigateToStore,
        );
      case 2:
        return StorePage(
          supabase: widget.supabase,
          onNavigationVisibilityChanged: _handleNavigationVisibilityChanged,
          onNavigateToHome: (programId) => _navigateToHome(programId: programId),
        );
      case 3:
        return ShopPage(
          supabase: widget.supabase,
          onNavigationVisibilityChanged: _handleNavigationVisibilityChanged,
        );
      case 4:
        return SettingsPage(
          supabase: widget.supabase,
          authRepository: widget.authRepository,
          biometricAuthService: widget.biometricAuthService,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _getPage(int index) {
    if (!_loadedTabs.contains(index)) {
      return const SizedBox.shrink();
    }
    return _pageCache.putIfAbsent(index, () => _buildPage(index));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _triggerSync();
    }
  }

  void _triggerSync() {
    OfflineSyncService.instance.syncPendingSessions(widget.supabase);
  }

  void _navigateToDashboard({String? programId, String? trainingId}) {
    _loadedTabs.add(0);
    setState(() {
      _currentIndex = 0;
      _isBottomNavVisible = true;
    });
    // Slight delay to ensure the widget is built/visible before refreshing
    Future.delayed(const Duration(milliseconds: 100), () {
      _dashboardKey.currentState?.refreshData(
        programId: programId,
      );
    });
  }

  void _navigateToHome({String? programId}) {
    _loadedTabs.add(1);
    setState(() {
      _currentIndex = 1;
      _isBottomNavVisible = true;
    });
    
    // Refresh Dashboard as well so it's ready when user switches to it
    _dashboardKey.currentState?.refreshData(programId: programId);

    // Use post-frame callback to ensure widget is built if it wasn't, but minimize delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeKey.currentState?.refresh(programId: programId);
    });
  }

  void _navigateToStore() {
    _loadedTabs.add(2);
    setState(() {
      _currentIndex = 2; // Index of StorePage
      _isBottomNavVisible = true;
    });
  }

  void _onItemTapped(int index) {
    if (_currentIndex == 1 && index != 1) {
      _homeKey.currentState?.clearNewIndicator();
    }
    _loadedTabs.add(index);
    setState(() {
      _currentIndex = index;
      _isBottomNavVisible = true;
    });
  }

  void _handleNavigationVisibilityChanged(bool isVisible) {
    if (_isBottomNavVisible == isVisible) return;

    setState(() {
      _isBottomNavVisible = isVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(5, _getPage),
      ),
      bottomNavigationBar: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          return SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: _isBottomNavVisible
            ? Container(
                key: const ValueKey('bottom-nav'),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFECE9F1), width: 1),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0, 'Progrès', 'progress'),
                        _buildNavItem(1, 'Séances', 'dumbbell'),
                        _buildNavItem(2, 'Store', 'store'),
                        _buildNavItem(3, 'Shop', 'shop'),
                        _buildNavItem(4, 'Réglages', 'settings'),
                      ],
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(key: ValueKey('bottom-nav-hidden')),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, String iconName) {
    final isSelected = _currentIndex == index;
    final textColor = isSelected
        ? const Color(0xFF7069FA)
        : const Color(0xFFC2BFC6);
    final iconPath = isSelected
        ? 'assets/icons/${iconName}_active.svg'
        : 'assets/icons/$iconName.svg';

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 66,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(iconPath, width: 24, height: 24),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
