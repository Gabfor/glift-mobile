import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';

import 'repositories/store_repository.dart';
import 'models/store_program.dart';
import 'widgets/glift_page_layout.dart';

class StorePage extends StatefulWidget {
  final SupabaseClient supabase;

  const StorePage({super.key, required this.supabase});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  late final StoreRepository _repository;
  List<StoreProgram> _programs = [];
  bool _isLoading = true;
  String _selectedGoal = 'Tous';

  @override
  void initState() {
    super.initState();
    _repository = StoreRepository(widget.supabase);
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
      print('Error loading store programs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
    if (_selectedGoal == 'Tous') return _programs;
    return _programs.where((program) => program.goal == _selectedGoal).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GliftPageLayout(
      title: 'Glift Store',
      subtitle: 'Trouver votre prochain programme',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _programs.isEmpty
              ? Center(
                  child: Text(
                    'Aucun programme trouvé',
                    style: GoogleFonts.quicksand(
                      color: const Color(0xFF3A416F),
                      fontSize: 16,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_availableGoals.length > 1) ...[
                      _FiltersRow(
                        options: _availableGoals,
                        selected: _selectedGoal,
                        onSelected: (value) {
                          setState(() => _selectedGoal = value);
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 50),
                      itemCount: _filteredPrograms.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        return _StoreProgramCard(program: _filteredPrograms[index]);
                      },
                    ),
                  ],
                ),
    );
  }
}

class _FiltersRow extends StatelessWidget {
  const _FiltersRow({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options
            .map(
              (option) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(
                    option,
                    style: GoogleFonts.quicksand(
                      color: selected == option ? Colors.white : const Color(0xFF3A416F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  selected: selected == option,
                  selectedColor: const Color(0xFF7069FA),
                  backgroundColor: const Color(0xFFF2F1F6),
                  showCheckmark: false,
                  onSelected: (_) => onSelected(option),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StoreProgramCard extends StatelessWidget {
  final StoreProgram program;

  const _StoreProgramCard({required this.program});

  @override
  Widget build(BuildContext context) {
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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

          SizedBox(height: program.partnerImage != null ? 45 : 15),

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
                      _buildIconTag('assets/icons/homme.svg'), // You might need to check if asset exists or use Icon
                    if (program.gender == 'Femme' || program.gender == 'Tous')
                      _buildIconTag('assets/icons/femme.svg'),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  program.description,
                  style: GoogleFonts.quicksand(
                    color: const Color(0xFF5D6494),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.57,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F1F6),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock, size: 16, color: Color(0xFFD7D4DC)),
                            const SizedBox(width: 8),
                            Text(
                              'Télécharger',
                              style: GoogleFonts.quicksand(
                                color: const Color(0xFFD7D4DC),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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
    // Placeholder for gender icon since we might not have the assets yet
    // Or we can try to load them if they exist.
    // For now using a simple container with icon
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5FE),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Icon(Icons.person, size: 14, color: Color(0xFFA1A5FD)),
    );
  }
}
