import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'repositories/dashboard_repository.dart';
import 'models/program.dart';
import 'models/training_row.dart';
import 'widgets/glift_page_layout.dart';

class DashboardPage extends StatefulWidget {
  final SupabaseClient supabase;
  final ValueChanged<bool>? onNavigationVisibilityChanged;

  const DashboardPage({
    super.key,
    required this.supabase,
    this.onNavigationVisibilityChanged,
  });

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  late final DashboardRepository _repository;
  late final PageController _programPageController;
  late final ScrollController _programScrollController;
  final List<GlobalKey> _programKeys = [];
  
  List<Program> _programs = [];
  String? _selectedProgramId;
  
  List<Map<String, dynamic>> _trainings = [];
  int _selectedTrainingIndex = 0;
  
  List<TrainingRow> _exercises = [];
  bool _isLoading = true;

  bool _isNavigationVisible = true;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _repository = DashboardRepository(widget.supabase);
    _programPageController = PageController();
    _programScrollController = ScrollController();
    _loadData();
  }

  @override
  void dispose() {
    _programPageController.dispose();
    _programScrollController.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    setState(() => _isLoading = true);
    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = widget.supabase.auth.currentUser?.id;
      if (userId == null) return;

      final programs = await _repository.getDashboardPrograms(userId);
      if (programs.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _programs = programs;
        _selectedProgramId = programs.first.id;
        _programKeys
          ..clear()
          ..addAll(List.generate(programs.length, (_) => GlobalKey()));
      });

      await _loadTrainings(_selectedProgramId!);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTrainings(String programId) async {
    try {
      final trainings = await _repository.getDashboardTrainings(programId);
      if (trainings.isEmpty) {
        setState(() {
          _trainings = [];
          _exercises = [];
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _trainings = trainings;
        _selectedTrainingIndex = 0;
      });

      await _loadExercises(trainings[0]['id']);
    } catch (e) {
      debugPrint('Error loading trainings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExercises(String trainingId) async {
    try {
      final exercises = await _repository.getDashboardExercises(trainingId);
      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading exercises: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onProgramSelected(String programId) {
    if (_selectedProgramId == programId) return;
    setState(() {
      _selectedProgramId = programId;
      _isLoading = true;
    });
    final targetIndex = _programs.indexWhere((program) => program.id == programId);
    if (targetIndex != -1) {
      _programPageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    _loadTrainings(programId);
    _scrollProgramIntoView(programId);
  }

  void _onProgramPageChanged(int index) {
    if (index < 0 || index >= _programs.length) return;

    final programId = _programs[index].id;
    if (_selectedProgramId == programId) return;

    setState(() {
      _selectedProgramId = programId;
      _isLoading = true;
    });

    _scrollProgramIntoView(programId);
    _loadTrainings(programId);
  }

  void _scrollProgramIntoView(String programId) {
    final index = _programs.indexWhere((program) => program.id == programId);
    if (index == -1) return;

    if (_programScrollController.hasClients && index < _programKeys.length) {
      final context = _programKeys[index].currentContext;

      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: 0.5,
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

  void _onTrainingChanged(int delta) {
    if (_trainings.isEmpty) return;

    final newIndex = _selectedTrainingIndex + delta;
    if (newIndex >= 0 && newIndex < _trainings.length) {
      setState(() {
        _selectedTrainingIndex = newIndex;
        _isLoading = true;
      });
      _loadExercises(_trainings[newIndex]['id']);
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final currentOffset = notification.metrics.pixels;
      final delta = currentOffset - _lastScrollOffset;

      if (delta > 10 && _isNavigationVisible) {
        _isNavigationVisible = false;
        widget.onNavigationVisibilityChanged?.call(false);
      } else if (delta < -10 && !_isNavigationVisible) {
        _isNavigationVisible = true;
        widget.onNavigationVisibilityChanged?.call(true);
      }

      _lastScrollOffset = currentOffset;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: GliftPageLayout(
        header: _buildHeader(),
        scrollable: false,
        padding: EdgeInsets.zero,
        headerPadding: EdgeInsets.zero,
        child: _buildProgramPager(),
      ),
    );
  }

  Widget _buildProgramPager() {
    if (_isLoading && _programs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_programs.isEmpty) {
      return Center(
        child: Text(
          'Aucun programme disponible',
          style: GoogleFonts.quicksand(
            color: const Color(0xFF3A416F),
            fontSize: 16,
          ),
        ),
      );
    }

    return PageView.builder(
      controller: _programPageController,
      onPageChanged: _onProgramPageChanged,
      itemCount: _programs.length,
      itemBuilder: (context, index) {
        final programId = _programs[index].id;
        final isCurrentProgram = programId == _selectedProgramId;

        if (!isCurrentProgram) {
          return const SizedBox.shrink();
        }

        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          children: [
            if (_trainings.isNotEmpty)
              Row(
                children: [
                  _buildArrowButton(
                    icon: Icons.chevron_left,
                    onTap: _selectedTrainingIndex > 0
                        ? () => _onTrainingChanged(-1)
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      _trainings[_selectedTrainingIndex]['name'],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.quicksand(
                        color: const Color(0xFF3A416F),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  _buildArrowButton(
                    icon: Icons.chevron_right,
                    onTap: _selectedTrainingIndex < _trainings.length - 1
                        ? () => _onTrainingChanged(1)
                        : null,
                  ),
                ],
              ),
            if (_trainings.isNotEmpty) const SizedBox(height: 20),
            if (_exercises.isEmpty)
              Center(
                child: Text(
                  'Aucun exercice trouvé',
                  style: GoogleFonts.quicksand(
                    color: const Color(0xFF3A416F),
                    fontSize: 16,
                  ),
                ),
              )
            else
              ..._exercises.asMap().entries.map((entry) {
                final exercise = entry.value;
                final isLast = entry.key == _exercises.length - 1;

                return Column(
                  children: [
                    _ExerciseChartCard(
                      key: ValueKey(exercise.id),
                      exercise: exercise,
                      repository: _repository,
                      userId: widget.supabase.auth.currentUser!.id,
                    ),
                    if (!isLast) const SizedBox(height: 20),
                  ],
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
          child: Text(
            'Tableau de bord',
            style: GoogleFonts.quicksand(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (_programs.isNotEmpty) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _programScrollController,
            child: Row(
              children: [
                const SizedBox(width: 20),
                ..._programs.asMap().entries.map((entry) {
                final index = entry.key;
                final program = entry.value;
                final isSelected = program.id == _selectedProgramId;
                return GestureDetector(
                  onTap: () => _onProgramSelected(program.id),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Text(
                      program.name,
                      key: _programKeys[index],
                      style: GoogleFonts.quicksand(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildArrowButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD7D4DC)),
        ),
        child: Icon(
          icon,
          color: onTap != null ? const Color(0xFF3A416F) : const Color(0xFFD7D4DC),
          size: 20,
        ),
      ),
    );
  }
}

class _ExerciseChartCard extends StatefulWidget {
  final TrainingRow exercise;
  final DashboardRepository repository;
  final String userId;

  const _ExerciseChartCard({
    super.key,
    required this.exercise,
    required this.repository,
    required this.userId,
  });

  @override
  State<_ExerciseChartCard> createState() => _ExerciseChartCardState();
}

class _ExerciseChartCardState extends State<_ExerciseChartCard> {
  static const double _tooltipWidth = 72;
  static const double _tooltipHeight = 34;
  static const double _tooltipVerticalOffset = 10;

  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  LineBarSpot? _touchedSpot;
  Offset? _touchPosition;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await widget.repository.getExerciseHistory(
        widget.exercise.id,
        widget.userId,
        limit: 7, // Limit strictly to 7 points as requested
      );
      
      final processedHistory = history.map((session) {
        final sets = (session['sets'] as List?) ?? [];
        double maxWeight = 0;
        
        for (final set in sets) {
          final weights = (set['weights'] as List?) ?? [];
          for (final w in weights) {
            final weight = double.tryParse(w.toString()) ?? 0;
            if (weight > maxWeight) maxWeight = weight;
          }
        }
        
        return {
          'date': DateTime.parse(session['session']['performed_at']),
          'value': maxWeight,
        };
      }).toList();

      processedHistory.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

      if (mounted) {
        setState(() {
          _history = processedHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading history: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const int desiredGridLines = 5;
    const double gridLineSpacingPx = 38;
    const double chartOverheadHeight = 140;

    double minX = 0;
    double maxX = 6;

    double realMinY = 0;
    double realMaxY = 100;
    double interval = 25;
    double chartMaxY = 100;

    if (_history.isNotEmpty) {
      final values = _history.map((e) => e['value'] as double).toList();
      double minV = values.reduce((a, b) => a < b ? a : b);
      double maxV = values.reduce((a, b) => a > b ? a : b);
      
      // Initial range estimate
      double minFloor = minV.floorToDouble();
      double maxCeil = maxV.ceilToDouble();
      if (minFloor == maxCeil) maxCeil += 5;
      
      double range = maxCeil - minFloor;
      double rawInterval = range / (desiredGridLines - 1);
      if (rawInterval < 1) rawInterval = 1;
      interval = rawInterval.ceilToDouble();
      
      // Snap min to interval and ensure padding from bottom
      // We want the lowest point to be at least 20% of an interval above the bottom line
      double snappedMin = (minFloor / interval).floorToDouble() * interval;
      if (minV - snappedMin < interval * 0.2) {
        snappedMin -= interval;
      }
      realMinY = snappedMin;
      
      // Recalculate interval to ensure we cover the max value
      // We have fixed number of lines starting from realMinY
      double neededRange = maxV - realMinY;
      rawInterval = neededRange / (desiredGridLines - 1);
      if (rawInterval < 1) rawInterval = 1;
      interval = rawInterval.ceilToDouble();
      
      chartMaxY = interval * (desiredGridLines - 1);

      // Calculate centered viewport
      // We want the spacing to be the same as if there were 7 points (range 0..6)
      // So the view range must always be 6.
      // We center the available data points within this range.
      final double dataCount = _history.length.toDouble();
      final double centerData = (dataCount - 1) / 2;
      final double viewRange = 6;
      minX = centerData - viewRange / 2;
      maxX = centerData + viewRange / 2;
    }

    return Container(
      width: double.infinity,
      height: chartOverheadHeight + (desiredGridLines - 1) * gridLineSpacingPx,
      padding: const EdgeInsets.fromLTRB(20, 20, 25, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7D4DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.exercise.exercise,
            style: GoogleFonts.quicksand(
              color: const Color(0xFF3A416F),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                    ? Center(
                        child: Text(
                          'Aucune donnée disponible',
                          style: GoogleFonts.quicksand(color: const Color(0xFFC2BFC6)),
                        ),
                      )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            double? tooltipLeft;
                            double? tooltipTop;

                            if (_touchedSpot != null) {
                              final spot = _touchedSpot!;
                              final chartWidth = constraints.maxWidth - 40;
                              final chartHeight = constraints.maxHeight - 60;
                              
                              // Calculate xPercent based on the fixed view range (minX to maxX)
                              final xPercent = (spot.x - minX) / (maxX - minX);
                              
                              final yPercent = spot.y / chartMaxY;
                              
                              final spotPxX = 40 + xPercent * chartWidth;
                              final spotPxY = chartHeight * (1 - yPercent);
                              
                              tooltipLeft = spotPxX;
                              tooltipTop = spotPxY - 16; // 10px spacing + 6px dot radius
                            }

                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                SizedBox.expand(
                                  child: LineChart(
                                    LineChartData(
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        horizontalInterval: interval,
                                        getDrawingHorizontalLine: (value) {
                                          return const FlLine(
                                            color: Color(0xFFECE9F1),
                                            strokeWidth: 1,
                                          );
                                        },
                                        checkToShowHorizontalLine: (value) {
                                          return true;
                                        },
                                      ),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        rightTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false)),
                                        topTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false)),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 41, // Reduced to 41px as requested
                                            interval: 1,
                                            getTitlesWidget: (value, meta) {
                                              final index = value.toInt();
                                              if (index >= 0 && index < _history.length) {
                                                final date =
                                                    _history[index]['date'] as DateTime;
                                                return Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      DateFormat('dd').format(date),
                                                      style: GoogleFonts.quicksand(
                                                        color: const Color(0xFF3A416F),
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                    Text(
                                                      DateFormat('MMM', 'fr_FR').format(date),
                                                      style: GoogleFonts.quicksand(
                                                        color: const Color(0xFFC2BFC6),
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            interval: interval,
                                            getTitlesWidget: (value, meta) {
                                              final realValue = value + realMinY;
                                              final displayValue = realValue.round();
                                              return Text(
                                                '$displayValue kg',
                                                style: GoogleFonts.quicksand(
                                                  color: const Color(0xFF3A416F),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(
                                        show: true,
                                        border: const Border(
                                          top: BorderSide(color: Color(0xFFECE9F1), width: 1),
                                          bottom: BorderSide(color: Color(0xFFECE9F1), width: 1),
                                          left: BorderSide.none,
                                          right: BorderSide.none,
                                        ),
                                      ),
                                      minX: minX,
                                      maxX: maxX,
                                      minY: 0, // Chart starts at 0
                                      maxY: chartMaxY, // Chart ends at range
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: _history.asMap().entries.map((e) {
                                            return FlSpot(e.key.toDouble(),
                                                (e.value['value'] as double) - realMinY);
                                          }).toList(),
                                          isCurved: true,
                                          curveSmoothness: 0.35,
                                          preventCurveOverShooting: true, // Prevent curve from dipping below lines
                                          color: const Color(0xFFA1A5FD),
                                          barWidth: 2,
                                          isStrokeCapRound: true,
                                          dotData: FlDotData(
                                            show: true,
                                            getDotPainter: (spot, percent, barData, index) {
                                              return FlDotCirclePainter(
                                                radius: 4,
                                                color: const Color(0xFF7069FA),
                                                strokeWidth: 2,
                                                strokeColor: Colors.white,
                                              );
                                            },
                                          ),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                const Color(0xFF7069FA).withOpacity(0.2),
                                                const Color(0xFF7069FA).withOpacity(0.0),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                      lineTouchData: LineTouchData(
                                        getTouchedSpotIndicator: (barData, spotIndexes) {
                                          return spotIndexes.map((barSpot) {
                                            return TouchedSpotIndicatorData(
                                              const FlLine(
                                                  color: Colors.transparent, strokeWidth: 0),
                                              FlDotData(
                                                show: true,
                                                getDotPainter: (spot, percent, barData, index) {
                                                  return FlDotCirclePainter(
                                                    radius: 6,
                                                    color: const Color(0xFF7069FA),
                                                    strokeWidth: 2,
                                                    strokeColor: Colors.white,
                                                  );
                                                },
                                              ),
                                            );
                                          }).toList();
                                        },
                                        touchCallback: (event, response) {
                                          if (!event.isInterestedForInteractions ||
                                              response == null ||
                                              response.lineBarSpots == null ||
                                              response.lineBarSpots!.isEmpty) {
                                            setState(() {
                                              _touchedSpot = null;
                                              _touchPosition = null;
                                            });
                                            return;
                                          }

                                          final newSpot = response.lineBarSpots!.first;
                                          final hasNewSpot = _touchedSpot == null ||
                                              _touchedSpot!.x != newSpot.x ||
                                              _touchedSpot!.y != newSpot.y;

                                          setState(() {
                                            _touchedSpot = newSpot;
                                            _touchPosition = event.localPosition;
                                          });

                                          if (hasNewSpot) {
                                            HapticFeedback.lightImpact();
                                          }
                                        },
                                        touchTooltipData: LineTouchTooltipData(
                                          tooltipPadding: EdgeInsets.zero,
                                          tooltipMargin: 0,
                                          getTooltipItems: (touchedSpots) => touchedSpots
                                              .map(
                                                (_) => const LineTooltipItem(
                                                  '',
                                                  TextStyle(color: Colors.transparent),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_touchedSpot != null && tooltipLeft != null && tooltipTop != null)
                                  Positioned(
                                    left: tooltipLeft,
                                    top: tooltipTop,
                                    child: FractionalTranslation(
                                      translation: const Offset(-0.5, -1.0),
                                      child: _TooltipWithArrow(
                                        backgroundColor: const Color(0xFF2D2E32),
                                        label:
                                            '${(_touchedSpot!.y + realMinY).toInt()} kg',
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
          ),
        ],
      ),
    );
  }
}

class _TooltipWithArrow extends StatelessWidget {
  final Color backgroundColor;
  final String label;

  const _TooltipWithArrow({
    required this.backgroundColor,
    required this.label,
  });

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
