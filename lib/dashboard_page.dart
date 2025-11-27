import 'package:flutter/material.dart';
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

  const DashboardPage({super.key, required this.supabase});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardRepository _repository;
  
  List<Program> _programs = [];
  String? _selectedProgramId;
  
  List<Map<String, dynamic>> _trainings = [];
  int _selectedTrainingIndex = 0;
  
  List<TrainingRow> _exercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = DashboardRepository(widget.supabase);
    _loadData();
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
    _loadTrainings(programId);
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

  @override
  Widget build(BuildContext context) {
    return GliftPageLayout(
      header: _buildHeader(),
      scrollable: false,
      padding: EdgeInsets.zero,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              children: [
                if (_trainings.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildArrowButton(
                        icon: Icons.chevron_left,
                        onTap: _selectedTrainingIndex > 0
                            ? () => _onTrainingChanged(-1)
                            : null,
                      ),
                      Text(
                        _trainings[_selectedTrainingIndex]['name'],
                        style: GoogleFonts.quicksand(
                          color: const Color(0xFF3A416F),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                    final index = entry.key;
                    final exercise = entry.value;
                    final isLast = index == _exercises.length - 1;

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
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Tableau de bord',
          style: GoogleFonts.quicksand(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (_programs.isNotEmpty) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _programs.map((program) {
                final isSelected = program.id == _selectedProgramId;
                return GestureDetector(
                  onTap: () => _onProgramSelected(program.id),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Text(
                      program.name,
                      style: GoogleFonts.quicksand(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
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
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

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
    double realMinY = 0;
    double realMaxY = 100;
    double interval = 20;
    double chartMaxY = 100;

    if (_history.isNotEmpty) {
      final values = _history.map((e) => e['value'] as double).toList();
      final minVal = values.reduce((a, b) => a < b ? a : b);
      final maxVal = values.reduce((a, b) => a > b ? a : b);
      
      realMinY = minVal.floorToDouble();
      realMaxY = maxVal.ceilToDouble();
      
      if (realMinY == realMaxY) {
        realMaxY += 5;
        realMinY = (realMinY - 5).clamp(0, double.infinity);
      }
      
      // Calculate interval to have exactly 5 horizontal lines (38px spacing)
      // Plot area is ~190px (330 - 140 overhead). 190 / 38 = 5.
      double range = realMaxY - realMinY;
      interval = range / 5;
      
      if (interval == 0) interval = 1;
      chartMaxY = range;
    }

    return Container(
      width: double.infinity,
      height: 330, // Adjusted height for 38px spacing (190px plot area)
      padding: const EdgeInsets.all(20),
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
                    : LineChart(
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
                          extraLinesData: ExtraLinesData(
                            horizontalLines: [
                              HorizontalLine(y: 0, color: const Color(0xFFECE9F1), strokeWidth: 1),
                              HorizontalLine(y: chartMaxY, color: const Color(0xFFECE9F1), strokeWidth: 1),
                            ],
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 60,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 && index < _history.length) {
                                    final date = _history[index]['date'] as DateTime;
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
                                  // Round to 1 decimal place if needed, or int if whole number
                                  if (realValue % 1 == 0) {
                                    return Text(
                                      '${realValue.toInt()} kg',
                                      style: GoogleFonts.quicksand(
                                        color: const Color(0xFF3A416F),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    );
                                  }
                                  return Text(
                                    '${realValue.toStringAsFixed(1)} kg',
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
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: (_history.length - 1).toDouble(),
                          minY: 0, // Chart starts at 0
                          maxY: chartMaxY, // Chart ends at range
                          lineBarsData: [
                            LineChartBarData(
                              spots: _history.asMap().entries.map((e) {
                                return FlSpot(e.key.toDouble(), (e.value['value'] as double) - realMinY);
                              }).toList(),
                              isCurved: true,
                              curveSmoothness: 0.35,
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
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (LineBarSpot touchedSpot) => const Color(0xFF2D2E32),
                              tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((LineBarSpot touchedSpot) {
                                  final realValue = touchedSpot.y + realMinY;
                                  return LineTooltipItem(
                                    '${realValue.toInt()} kg',
                                    GoogleFonts.quicksand(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
