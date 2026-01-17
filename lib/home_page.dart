import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';

import 'auth/auth_repository.dart';
import 'auth/biometric_auth_service.dart';
import 'login_page.dart';
import 'models/program.dart';
import 'models/training.dart';
import 'package:glift_mobile/widgets/unlock_training_modal.dart';
import 'repositories/program_repository.dart';
import 'theme/glift_theme.dart';
import 'services/settings_service.dart';
import 'training_details_page.dart';
import 'widgets/glift_loader.dart';
import 'widgets/glift_page_layout.dart';
import 'widgets/glift_pull_to_refresh.dart';
import 'widgets/empty_programs_widget.dart';

enum SyncStatus { loading, synced, notSynced }

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.supabase,
    required this.authRepository,
    required this.biometricAuthService,
    this.onNavigateToDashboard,
    this.initialProgramId,
    this.onNavigationVisibilityChanged,
    this.onNavigateToStore,
  });

  final String? initialProgramId;

  final SupabaseClient supabase;
  final AuthRepository authRepository;
  final BiometricAuthService biometricAuthService;
  final void Function({String? programId, String? trainingId})?
      onNavigateToDashboard;
  final ValueChanged<bool>? onNavigationVisibilityChanged;
  final VoidCallback? onNavigateToStore;

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late final ProgramRepository _programRepository;
  late PageController _pageController;
  late final ScrollController _programScrollController;
  final List<GlobalKey> _programKeys = [];
  final GlobalKey _pageViewKey = GlobalKey(); // Key to preserve PageView state
  List<Program>? _programs;

  String? _selectedProgramId;
  String? _pendingProgramId;
  String? _newlyDownloadedId;
  bool _isLoading = true;
  SyncStatus _syncStatus = SyncStatus.loading;
  String? _error;

  bool _isNavigationVisible = true;
  double _lastScrollOffset = 0;
  Timer? _navigationInactivityTimer;


  @override
  void initState() {
    super.initState();
    _programRepository = ProgramRepository(widget.supabase);
    // Initialize PageController. Initial page will be set correctly when _programs loads.
    _pageController = PageController();
    _programScrollController = ScrollController();
    _selectedProgramId = widget.initialProgramId;

    _fetchPrograms();
  }

  void clearNewIndicator() {
    if (_newlyDownloadedId != null) {
      setState(() {
        _newlyDownloadedId = null;
      });
    }
  }

  void refresh({String? programId}) {
    if (programId != null) {
      _selectedProgramId = programId;
      _pendingProgramId = programId;
      _newlyDownloadedId = programId;
      // Force loading state when switching programs or after download
      setState(() {
        _isLoading = true;
      });
    }
    _fetchPrograms();
  }

  @override
  void dispose() {
    _navigationInactivityTimer?.cancel();
    _pageController.dispose();
    _programScrollController.dispose();
    super.dispose();
  }

  void _ensureSelectedProgramVisible() {
    if (_programs == null || _selectedProgramId == null) return;

    final index = _programs!.indexWhere((p) => p.id == _selectedProgramId);
    if (index == -1) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onProgramSelected(index, forceScroll: true);
    });
  }



  Future<void> _handleRefresh() async {
    setState(() {
      _syncStatus = SyncStatus.loading;
    });
    // Sync settings first or concurrently
    await SettingsService.instance.syncFromSupabase();
    await _fetchPrograms();
  }

  Future<void> _fetchPrograms() async {
    // 1. Load local cache first
    try {
      final localPrograms = await _programRepository.getLocalPrograms();
      if (mounted && localPrograms.isNotEmpty) {
        setState(() {
          _programs = localPrograms;
          _programKeys
            ..clear()
            ..addAll(List.generate(localPrograms.length, (_) => GlobalKey()));
          if (_selectedProgramId == null) {
            _selectedProgramId = localPrograms.first.id;
          }
          // _isLoading = false; // Intentionally keeping loading state to prevent flash of deleted programs
        });
      }
    } catch (e) {
      debugPrint('Error loading local programs: $e');
    }

    // 2. Fetch remote data (Background Sync)
    if (mounted) {
      setState(() {
        _syncStatus = SyncStatus.loading;
      });
    }

    try {
      await SettingsService.instance.syncFromSupabase();
      final programs = await _programRepository.getPrograms();

      if (mounted) {
        setState(() {
          _programs = programs;
          _programKeys
            ..clear()
            ..addAll(List.generate(programs.length, (_) => GlobalKey()));

          // Clear new indicator if the program is no longer visible
          if (_newlyDownloadedId != null &&
              !programs.any((p) => p.id == _newlyDownloadedId)) {
            _newlyDownloadedId = null;
          }
            
          // If we had no selection or selection is invalid, select first
          if (_selectedProgramId == null ||
              !programs.any((p) => p.id == _selectedProgramId)) {
            if (programs.isNotEmpty) _selectedProgramId = programs.first.id;
          }

          _isLoading = false;
          _syncStatus = SyncStatus.synced;

          if (_pendingProgramId != null) {
            final targetId = _pendingProgramId!;
            _pendingProgramId = null;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              debugPrint('Looking for program with ID: $targetId');
              debugPrint('Programs list: ${programs.map((p) => '${p.name} (${p.id})').join(', ')}');
              final targetIndex = programs.indexWhere((p) => p.id == targetId);
              debugPrint('Found at index: $targetIndex');
              if (targetIndex != -1) {
                // Slight delay to ensure keys are bound and layout is ready
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    _onProgramSelected(targetIndex, alignment: 1.0, forceScroll: true);
                  }
                });
              }
            });
          } else {
            _ensureSelectedProgramVisible();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _programs == null ? e.toString() : null; // Only show full error if no cache
          _isLoading = false;
          _syncStatus = SyncStatus.notSynced;
        });
      }
    }
  }

  void _onProgramSelected(int index, {double alignment = 0.5, bool forceScroll = false}) {
    if (_programs != null) {
      final selectedId = _programs![index].id;
      if (selectedId != _selectedProgramId || forceScroll) {
        final isDifferentProgram = selectedId != _selectedProgramId;
        
        // Handle layout change logic BEFORE updating state/jumping
        // If layout needs to change (e.g. Fixed -> Scrollable), we might need a new controller
        final currentScrollable = _shouldUseFullPageScroll(_selectedProgramId);
        final nextScrollable = _shouldUseFullPageScroll(selectedId);
        
        if (currentScrollable != nextScrollable) {
           _pageController.dispose();
           _pageController = PageController(initialPage: index);
           // We don't jump because the new controller starts at 'index'
        } else {
           _pageController.jumpToPage(index);
        }

        setState(() {
          _selectedProgramId = selectedId;
          if (isDifferentProgram && !forceScroll) {
            _newlyDownloadedId = null;
          }
        });
        
        _scrollProgramIntoView(index, alignment: alignment);
      }
    }
  }

  void _onPageChanged(int index) {
      if (_programs == null) return;
      
      final newProgramId = _programs![index].id;
      final currentScrollable = _shouldUseFullPageScroll(_selectedProgramId);
      final nextScrollable = _shouldUseFullPageScroll(newProgramId);

      // If layout changes, we must replace the controller to avoid offset issues / NestedScrollView crashes
      // when PageView is reparented without a GlobalKey.
      if (currentScrollable != nextScrollable) {
         _pageController.dispose();
         _pageController = PageController(initialPage: index);
      }

    setState(() {
      _selectedProgramId = newProgramId;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollProgramIntoView(index);
      }
    });
  }

  void _scrollProgramIntoView(int index, {double alignment = 0.5}) {
    if (_programScrollController.hasClients && index < _programKeys.length) {
      final context = _programKeys[index].currentContext;

      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: alignment,
        );
      } else {
        _programScrollController.animateTo(
          _programScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  bool _shouldUseFullPageScroll(String? programId) {
    if (_programs == null || programId == null) return false;
    final index = _programs!.indexWhere((p) => p.id == programId);
    if (index == -1) return false;
    return _programs![index].trainings.length > 4;
  }

  void _showNavigation() {
    if (_isNavigationVisible) return;

    setState(() {
      _isNavigationVisible = true;
    });

    widget.onNavigationVisibilityChanged?.call(true);
  }

  void _hideNavigation() {
    if (!_isNavigationVisible) return;

    setState(() {
      _isNavigationVisible = false;
    });

    widget.onNavigationVisibilityChanged?.call(false);
  }

  void _resetNavigationInactivityTimer() {
    _navigationInactivityTimer?.cancel();
    _navigationInactivityTimer = Timer(
      const Duration(seconds: 2),
      _showNavigation,
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) return false;

    // Ignore horizontal scrolls
    if (notification.metrics.axis == Axis.horizontal) {
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      _resetNavigationInactivityTimer();

      final currentOffset = max(notification.metrics.pixels, 0.0).toDouble();

      if (currentOffset <= 0) {
       _lastScrollOffset = 0;
       _showNavigation();
       return false;
      }

      final delta = currentOffset - _lastScrollOffset;

      if (delta > 10) {
        _hideNavigation();
      } else if (delta < -10) {
        _showNavigation();
      }

      _lastScrollOffset = currentOffset;
    }

    return false;
  }



  @override
  Widget build(BuildContext context) {
    final isPageScrollable = _shouldUseFullPageScroll(_selectedProgramId);

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: GliftPageLayout(
        header: _buildHeader(),
        scrollable: false,
        fullPageScroll: isPageScrollable,
        padding: EdgeInsets.zero,
        headerPadding: EdgeInsets.zero,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildHeader() {
    final programCount = _programs?.length ?? 0;
    final programTitle = programCount == 1 ? 'Programme' : 'Programmes';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
          child: Text(
            programTitle,
            style: GoogleFonts.quicksand(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (_programs != null && _programs!.isNotEmpty) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
          key: const PageStorageKey('program_header_scroll'),
          scrollDirection: Axis.horizontal,
            controller: _programScrollController,
            child: Row(
              children: [
                const SizedBox(width: 20),
                ..._programs!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final program = entry.value;
                  final isSelected = program.id == _selectedProgramId;
                  final isNew = program.id == _newlyDownloadedId;

                  return GestureDetector(
                    key: _programKeys[index],
                    onTap: () => _onProgramSelected(index),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isNew)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF00D591),
                                shape: BoxShape.circle,
                              ),
                            ),
                          Text(
                            program.name,
                            style: GoogleFonts.quicksand(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 8),
            child: Text(
              'Aucun programme',
              style: GoogleFonts.quicksand(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Stack(
        children: [
          const GliftLoader(),
          // Pre-cache vital icons while loading
          Offstage(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset('assets/icons/training_calendar.svg', width: 0, height: 0),
                SvgPicture.asset('assets/icons/training_dumbell.svg', width: 0, height: 0),
                SvgPicture.asset('assets/icons/training_clock.svg', width: 0, height: 0),
                SvgPicture.asset('assets/icons/check_green.svg', width: 0, height: 0),
                SvgPicture.asset('assets/icons/notgood.svg', width: 0, height: 0),
              ],
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return Center(child: Text('Erreur: $_error'));
    }

    if (_programs == null || _programs!.isEmpty) {
      return GliftPullToRefresh(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: _TopBouncingScrollPhysics(),
          ),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: widget.onNavigateToStore != null
                  ? EmptyProgramsWidget(onGoToStore: widget.onNavigateToStore!)
                  : Center(
                      child: Text(
                        'Aucun programme disponible',
                        style: GoogleFonts.quicksand(
                            fontSize: 16, color: GliftTheme.body),
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    return PageView.builder(
      // key: _pageViewKey, // Removed to avoid NestedScrollView assertion issues on reparenting
      controller: _pageController,
      physics: const AlwaysScrollableScrollPhysics(), // Horizontal scrolling
      onPageChanged: _onPageChanged,
      itemCount: _programs!.length,
      itemBuilder: (context, index) {
        final program = _programs![index];
        return GliftPullToRefresh(
          onRefresh: _handleRefresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
              parent: const _TopBouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
            itemCount: program.trainings.length + 1,
            separatorBuilder: (context, separatorIndex) =>
                SizedBox(height: separatorIndex == 0 ? 10 : 16),
            itemBuilder: (context, itemIndex) {
              if (itemIndex == 0) {
                return Text(
                  'Entraînement',
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GliftTheme.title,
                  ),
                );
              }

              final training = program.trainings[itemIndex - 1];
              return _TrainingCard(
                training: training,
                syncStatus: _syncStatus,
                onTap: () async {
                  if (training.locked) {
                     await showDialog(
                      context: context,
                      builder: (context) => const UnlockTrainingModal(),
                    );
                    return;
                  }

                  final result = await Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => TrainingDetailsPage(
                        training: training,
                        supabase: widget.supabase,
                        authRepository: widget.authRepository,
                        biometricAuthService: widget.biometricAuthService,
                      ),
                      transitionsBuilder:
                          (_, animation, secondaryAnimation, child) {
                        const begin = Offset(0, 1);
                        const end = Offset.zero;
                        const curve = Curves.ease;

                        final tween = Tween(
                          begin: begin,
                          end: end,
                        ).chain(CurveTween(curve: curve));

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                    ),
                  );

                  if (result == true) {
                    // Reload programs to refresh stats (last session, average time)
                    _fetchPrograms();
                    widget.onNavigateToDashboard?.call(
                      programId: program.id,
                      trainingId: training.id,
                    );
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _TopBouncingScrollPhysics extends BouncingScrollPhysics {
  const _TopBouncingScrollPhysics({super.parent});

  @override
  _TopBouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _TopBouncingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // If overscrolling at the bottom (value > maxScrollExtent)
    if (value > position.maxScrollExtent) {
      // Apply clamping logic for bottom
      if (value > position.pixels &&
          position.pixels >= position.maxScrollExtent) {
        return value - position.pixels;
      }
      if (position.maxScrollExtent < value &&
          position.pixels < position.maxScrollExtent) {
        return value - position.maxScrollExtent;
      }
    }
    // Allow top overscroll (bounce)
    return super.applyBoundaryConditions(position, value);
  }
}

class _TrainingCard extends StatelessWidget {
  const _TrainingCard({
    required this.training,
    required this.onTap,
    required this.syncStatus,
  });

  final Training training;
  final VoidCallback onTap;
  final SyncStatus syncStatus;

  @override
  Widget build(BuildContext context) {
    // Determine dynamic display info
    String lastSessionText = '-';
    String averageTimeText = '-';

    if (training.lastSessionDate != null) {
      lastSessionText = _formatRelativeTime(training.lastSessionDate!);
    }
    
    if (training.averageDurationMinutes != null) {
      final hours = training.averageDurationMinutes! ~/ 60;
      final minutes = training.averageDurationMinutes! % 60;
      
      if (hours > 0) {
        averageTimeText = '${hours}h${minutes.toString().padLeft(2, '0')} min';
      } else {
        averageTimeText = '$minutes min';
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD7D4DC)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    training.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3A416F),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildStatusIcon(),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    iconPath: 'assets/icons/training_calendar.svg',
                    value: lastSessionText,
                    label: 'Dernière fois',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    iconPath: 'assets/icons/training_dumbell.svg',
                    value: '${training.sessionCount ?? 0} x',
                    label: (training.sessionCount ?? 0) > 1 ? 'Effectuées' : 'Effectué',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    iconPath: 'assets/icons/training_clock.svg',
                    value: averageTimeText,
                    label: 'Durée moyenne',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String iconPath,
    required String value,
    required String label,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          iconPath,
          width: 24,
          height: 24,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A416F),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: GoogleFonts.quicksand(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5D6494),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon() {
    if (training.locked) {
      return SvgPicture.asset(
        'assets/icons/locked.svg',
        width: 20,
        height: 20,
      );
    }

    switch (syncStatus) {
      case SyncStatus.loading:
        return const _RotatingLoader();
      case SyncStatus.synced:
        return SvgPicture.asset(
          'assets/icons/check_green.svg',
          width: 20,
          height: 20,
        );
      case SyncStatus.notSynced:
        return SvgPicture.asset('assets/icons/notgood.svg', width: 24, height: 24);
    }
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '+1 an';
    }

    String formatUnit(int value, String singular, String plural) {
      return value == 1 ? singular : plural;
    }

    if (difference.inDays > 0) {
      final days = difference.inDays;
      return '$days ${formatUnit(days, 'jour', 'jours')}';
    } else if (difference.inHours > 0) {
      final hours = difference.inHours;
      return '$hours ${formatUnit(hours, 'heure', 'heures')}';
    } else if (difference.inMinutes > 0) {
      final minutes = difference.inMinutes;
      return '$minutes ${formatUnit(minutes, 'min', 'min')}';
    } else {
      return 'À l\'instant';
    }
  }
}

class _RotatingLoader extends StatefulWidget {
  const _RotatingLoader();

  @override
  State<_RotatingLoader> createState() => _RotatingLoaderState();
}

class _RotatingLoaderState extends State<_RotatingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: SvgPicture.asset(
        'assets/icons/loader.svg',
        width: 20,
        height: 20,
      ),
    );
  }
}
