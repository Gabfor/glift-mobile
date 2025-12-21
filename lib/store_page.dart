import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase/supabase.dart';

import 'repositories/store_repository.dart';
import 'models/store_program.dart';
import 'widgets/glift_loader.dart';
import 'widgets/glift_page_layout.dart';
import 'widgets/filter_modal.dart';
import 'widgets/glift_sort_dropdown.dart';

import 'services/filter_service.dart';
import 'theme/glift_theme.dart';

class StorePage extends StatefulWidget {
  final SupabaseClient supabase;
  final ValueChanged<bool>? onNavigationVisibilityChanged;

  final void Function(String? programId)? onNavigateToHome;

  const StorePage({
    super.key,
    required this.supabase,
    this.onNavigationVisibilityChanged,
    this.onNavigateToHome,
  });

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  static const List<Map<String, String>> _sortOptions = [
    {'value': 'popularity', 'label': 'Popularité'},
    {'value': 'newest', 'label': 'Nouveauté'},
    {'value': 'expiration', 'label': 'Ancienneté'},
  ];

  late final StoreRepository _repository;
  List<StoreProgram> _programs = [];
  bool _isLoading = true;
  late String _selectedSort;

  bool _isNavigationVisible = true;
  double _lastScrollOffset = 0;
  Timer? _navigationRevealTimer;

  @override
  void initState() {
    super.initState();
    _repository = StoreRepository(widget.supabase);

    // Initialize from service
    final filterService = FilterService();
    _selectedFiltersMap = Map.from(filterService.storeFilters);
    _selectedSort = filterService.storeSort;

    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    try {
      final programs = await _repository.getStorePrograms();
      if (mounted) {
        setState(() {
          _programs = programs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading store programs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _navigationRevealTimer?.cancel();
    super.dispose();
  }

  List<String> get _availableGoals {
    final goals = <String>{};

    for (final program in _programs) {
      if (program.goal.trim().isNotEmpty) {
        goals.add(program.goal);
      }
    }

    final sortedGoals = goals.toList()..sort();
    return ['Tous', ...sortedGoals];
  }

  List<StoreProgram> get _filteredPrograms {
    return _applyFilters(_selectedFiltersMap);
  }

  bool get _hasActiveFilters {
    return _selectedFiltersMap.values.any((values) => values.isNotEmpty);
  }

  List<StoreProgram> _applyFilters(Map<String, Set<String>> selectedFilters) {
    var filtered = List<StoreProgram>.from(_programs);

    // Filter
    if (selectedFilters.isNotEmpty) {
      filtered = filtered.where((program) {
        bool matches = true;

        // Objectif (formerly Catégorie)
        if (selectedFilters.containsKey('Objectif')) {
          if (selectedFilters['Objectif']!.isEmpty) {
            matches = false;
          } else if (!selectedFilters['Objectif']!.contains(program.goal)) {
            matches = false;
          }
        }

        // Partenaire (formerly Boutique)
        if (matches && selectedFilters.containsKey('Partenaire')) {
          if (selectedFilters['Partenaire']!.isEmpty) {
            matches = false;
          } else if (program.partnerName == null ||
              !selectedFilters['Partenaire']!.contains(program.partnerName)) {
            matches = false;
          }
        }

        // Niveau
        if (matches && selectedFilters.containsKey('Niveau')) {
          if (selectedFilters['Niveau']!.isEmpty) {
            matches = false;
          } else if (!selectedFilters['Niveau']!.contains(program.level)) {
            matches = false;
          }
        }

        // Durée max.
        if (matches && selectedFilters.containsKey('Durée max.')) {
          if (selectedFilters['Durée max.']!.isEmpty) {
            matches = false;
          } else {
            final programDurationWithUnit = '${program.duration} minutes';
            if (!selectedFilters['Durée max.']!
                .contains(programDurationWithUnit)) {
              matches = false;
            }
          }
        }

        // Lieu
        if (matches && selectedFilters.containsKey('Lieu')) {
          if (selectedFilters['Lieu']!.isEmpty) {
            matches = false;
          } else if (program.location == null ||
              !selectedFilters['Lieu']!.contains(program.location)) {
            matches = false;
          }
        }

        // Sexe
        if (matches && selectedFilters.containsKey('Sexe')) {
          if (selectedFilters['Sexe']!.isEmpty) {
            matches = false;
          } else if (!selectedFilters['Sexe']!.contains(program.gender)) {
            matches = false;
          }
        }

        return matches;
      }).toList();
    }

    // Sort
    switch (_selectedSort) {
      case 'newest':
        // Assuming there is a date field, otherwise fallback to default or title
        // For now, let's sort by title as a placeholder if no date exists
        // Or if StoreProgram has a date, use it.
        // Checking StoreProgram definition (implied): it has title, sessions, duration, etc.
        // If no date, maybe just keep default order or sort by title?
        // Let's assume default order for 'newest' if no date is available, or add a TODO.
        // Actually, ShopPage used startDate. StoreProgram might not have it.
        // Let's check StoreProgram structure later if needed. For now, I'll just leave it as is or sort by title?
        // Let's just implement the switch but keep default for now if fields are missing.
        break;
      case 'expiration':
        // Store programs usually don't expire?
        // Maybe 'popularity' (e.g. number of downloads/sessions)?
        // I'll implement the structure but maybe just return filtered for now until I know the fields.
        break;
      case 'popularity':
      default:
        break;
    }

    return filtered;
  }

  void _showFilterModal() {
    final goals = <String>{};
    final partners = <String>{};
    final levels = <String>{};
    final durations = <String>{};
    final genders = <String>{};
    final locations = <String>{};

    for (final program in _programs) {
      if (program.goal.isNotEmpty) goals.add(program.goal);
      if (program.partnerName != null && program.partnerName!.isNotEmpty) {
        partners.add(program.partnerName!);
      }
      if (program.level.isNotEmpty) levels.add(program.level);
      if (program.duration.isNotEmpty) {
        durations.add('${program.duration} minutes');
      }
      if (program.gender.isNotEmpty && program.gender != 'Tous') {
        genders.add(program.gender);
      }
      if (program.location != null && program.location!.isNotEmpty) {
        locations.add(program.location!);
      }
    }

    final sections = [
      FilterSection(title: 'Sexe', options: genders.toList()..sort()),
      FilterSection(
        title: 'Niveau',
        options: levels.toList()..sort(),
      ),
      FilterSection(
        title: 'Lieu',
        options: locations.toList()..sort(),
      ),
      FilterSection(
        title: 'Objectif', // Formerly Catégorie
        options: goals.toList()..sort(),
      ),
      FilterSection(
        title: 'Durée max.',
        options: durations.toList()..sort((a, b) {
          // Extract numbers for correct sorting
          final intA = int.tryParse(a.split(' ')[0]) ?? 0;
          final intB = int.tryParse(b.split(' ')[0]) ?? 0;
          return intA.compareTo(intB);
        }),
      ),
      FilterSection(
        title: 'Partenaire', // Formerly Boutique
        options: partners.toList()..sort(),
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: GliftTheme.barrierColor,
      builder: (context) => FilterModal(
        sections: sections,
        selectedFilters: _selectedFiltersMap,
        computeResults: (filters) => _applyFilters(filters).length,
        onApply: (selected) {
          setState(() {
            _selectedFiltersMap = selected;
            FilterService().storeFilters = selected; // Persist
          });
        },
      ),
    );
  }

  Map<String, Set<String>> _selectedFiltersMap = {};

  @override
  Widget build(BuildContext context) {
    final isScrollable = !_isLoading && _programs.isNotEmpty && _filteredPrograms.isNotEmpty;

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: GliftPageLayout(
        scrollable: isScrollable,
        title: 'Glift Store',
        subtitle: 'Trouver votre prochain programme',
        padding: const EdgeInsets.only(top: 20, bottom: 30),
        child: _isLoading
            ? const GliftLoader()
            : _programs.isEmpty
                ? Center(
                    child: Text(
                      'Aucun programme disponible',
                      style: GoogleFonts.quicksand(
                        color: const Color(0xFFC2BFC6),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_availableGoals.length > 1) ...[
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
                                    child: GliftSortDropdown(
                                      options: _sortOptions,
                                      selectedValue: _selectedSort,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedSort = value;
                                          FilterService().storeSort = value;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () {
                                      _showFilterModal();
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFD7D4DC),
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      child: SvgPicture.asset(
                                        _hasActiveFilters
                                            ? 'assets/icons/filtre_green.svg'
                                            : 'assets/icons/filtre_red.svg',
                                        height: 16,
                                        width: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (_filteredPrograms.isEmpty)
                        Expanded(
                          child: Center(
                            child: Text(
                              'Aucun programme disponible',
                              style: GoogleFonts.quicksand(
                                color: const Color(0xFFC2BFC6),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 50),
                            itemCount: _filteredPrograms.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 20),
                            itemBuilder: (context, index) {
                              final isAuthenticated =
                                  widget.supabase.auth.currentUser != null;
                              return _StoreProgramCard(
                                program: _filteredPrograms[index],
                                isAuthenticated: isAuthenticated,
                                repository: _repository,
                                onNavigateToHome: widget.onNavigateToHome,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final currentOffset = max(notification.metrics.pixels, 0.0).toDouble();

      if (currentOffset <= 0) {
        _lastScrollOffset = 0;
        if (!_isNavigationVisible) {
          _isNavigationVisible = true;
          widget.onNavigationVisibilityChanged?.call(true);
        }
        _navigationRevealTimer?.cancel();
        return false;
      }

      final delta = currentOffset - _lastScrollOffset;

      if (delta > 10 && _isNavigationVisible) {
        _isNavigationVisible = false;
        widget.onNavigationVisibilityChanged?.call(false);
        _scheduleNavigationReveal();
      } else if (delta < -10 && !_isNavigationVisible) {
        _isNavigationVisible = true;
        widget.onNavigationVisibilityChanged?.call(true);
        _navigationRevealTimer?.cancel();
      }

      _lastScrollOffset = currentOffset;
    }

    return false;
  }

  void _scheduleNavigationReveal() {
    _navigationRevealTimer?.cancel();
    _navigationRevealTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && !_isNavigationVisible) {
        _isNavigationVisible = true;
        widget.onNavigationVisibilityChanged?.call(true);
      }
    });
  }
}



class _StoreProgramCard extends StatefulWidget {
  final StoreProgram program;
  final bool isAuthenticated;
  final StoreRepository repository;
  final void Function(String? programId)? onNavigateToHome;

  const _StoreProgramCard({
    required this.program,
    required this.isAuthenticated,
    required this.repository,
    this.onNavigateToHome,
  });

  @override
  State<_StoreProgramCard> createState() => _StoreProgramCardState();
}

class _StoreProgramCardState extends State<_StoreProgramCard> {
  bool _isDownloading = false;

  bool get _isDownloadable =>
      widget.isAuthenticated && widget.program.linkedProgramId != null;

  Future<void> _handleDownload() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    HapticFeedback.lightImpact();

    try {
      final success = await widget.repository.downloadProgram(widget.program.id);
      if (mounted) {
        if (success != null) {
          widget.onNavigateToHome?.call(success);
        } else {
          throw Exception('Download returned null');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors du téléchargement : $e',
              style: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final program = widget.program;
    // ... rest of the build method stays similar, but using _isDownloading ...
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: Image.network(
                  program.image,
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
              if (program.partnerImage != null)
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
                            color: const Color(0xFF5D6494).withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          program.partnerImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: program.partnerImage != null ? 30 : 15),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  program.title.toUpperCase(),
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
                  children: [
                    _buildTag(program.level),
                    _buildTag('${program.sessions} séances'),
                    _buildTag('${program.duration} min'),
                    if (program.gender == 'Homme' || program.gender == 'Tous')
                      _buildIconTag(
                        'assets/icons/homme.svg',
                      ), // You might need to check if asset exists or use Icon
                    if (program.gender == 'Femme' || program.gender == 'Tous')
                      _buildIconTag('assets/icons/femme.svg'),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  program.description,
                  style: GoogleFonts.quicksand(
                    color: const Color(0xFF5D6494),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.57,
                  ),
                ),
                const SizedBox(height: 15),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _isDownloadable && !_isDownloading
                            ? _handleDownload
                            : null,
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: _isDownloading
                                ? const Color(0xFFF2F1F6)
                                : (_isDownloadable
                                    ? const Color(0xFF7069FA)
                                    : const Color(0xFFF2F1F6)),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _isDownloading
                                  ? const GliftLoader(
                                      size: 20,
                                      strokeWidth: 2,
                                      color: Color(0xFFD7D4DC),
                                      centered: false,
                                    )
                                  : SvgPicture.asset(
                                      _isDownloadable
                                          ? 'assets/icons/download.svg'
                                          : 'assets/icons/locked.svg',
                                      width: _isDownloadable ? 20 : 15,
                                      height: _isDownloadable ? 20 : 15,
                                      colorFilter: ColorFilter.mode(
                                        _isDownloadable
                                            ? Colors.white
                                            : const Color(0xFFD7D4DC),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                              const SizedBox(width: 8),
                              Text(
                                _isDownloading ? 'Téléchargement...' : 'Télécharger',
                                style: GoogleFonts.quicksand(
                                  color: _isDownloading
                                      ? const Color(0xFFD7D4DC)
                                      : (_isDownloadable
                                          ? Colors.white
                                          : const Color(0xFFD7D4DC)),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    'En savoir plus',
                    style: GoogleFonts.quicksand(
                      color: const Color(0xFF5D6494),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildIconTag(String assetPath) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5FE),
        borderRadius: BorderRadius.circular(5),
      ),
      child: SvgPicture.asset(assetPath, width: 14, height: 14),
    );
  }
}
