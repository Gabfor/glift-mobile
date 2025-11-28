import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterSection {
  final String title;
  final List<String> options;

  FilterSection({required this.title, required this.options});
}

class FilterModal extends StatefulWidget {
  final List<FilterSection> sections;
  final Map<String, Set<String>> selectedFilters;
  final Function(Map<String, Set<String>>) onApply;
  final int Function(Map<String, Set<String>> filters) computeResults;

  const FilterModal({
    super.key,
    required this.sections,
    required this.selectedFilters,
    required this.onApply,
    required this.computeResults,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late Map<String, Set<String>> _tempSelectedFilters;
  late int _currentResults;

  bool get _hasActiveFilters {
    for (final section in widget.sections) {
      final options = section.options.toSet();
      final selected = _tempSelectedFilters[section.title] ?? {};
      final isFiltering = selected.isNotEmpty && selected.length != options.length;
      if (isFiltering) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    // Deep copy of selected filters
    _tempSelectedFilters = {};
    widget.selectedFilters.forEach((key, value) {
      _tempSelectedFilters[key] = Set.from(value);
    });

    // Ensure all checkboxes are selected by default
    for (final section in widget.sections) {
      _tempSelectedFilters[section.title] ??= section.options.toSet();
      if (_tempSelectedFilters[section.title]!.isEmpty) {
        _tempSelectedFilters[section.title]!.addAll(section.options);
      }
    }

    _currentResults = widget.computeResults(_tempSelectedFilters);
  }

  void _toggleFilter(String section, String option) {
    setState(() {
      if (!_tempSelectedFilters.containsKey(section)) {
        _tempSelectedFilters[section] = {};
      }

      final sectionFilters = _tempSelectedFilters[section]!;
      if (sectionFilters.contains(option)) {
        sectionFilters.remove(option);
      } else {
        sectionFilters.add(option);
      }

      _currentResults = widget.computeResults(_tempSelectedFilters);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Color(0xFF3A416F)),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      _hasActiveFilters
                          ? 'assets/icons/filtre_green.svg'
                          : 'assets/icons/filtre_red.svg',
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Filtres',
                      style: GoogleFonts.quicksand(
                        color: const Color(0xFF3A416F),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          
          // Content
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: widget.sections.length,
              itemBuilder: (context, index) {
                final section = widget.sections[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: GoogleFonts.quicksand(
                        color: const Color(0xFF3A416F),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...section.options.map((option) {
                      final isSelected = _tempSelectedFilters[section.title]?.contains(option) ?? false;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: () => _toggleFilter(section.title, option),
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                isSelected 
                                    ? 'assets/icons/checkbox_checked.svg' 
                                    : 'assets/icons/checkbox.svg',
                                width: 18,
                                height: 18,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                option,
                                style: GoogleFonts.quicksand(
                                  color: const Color(0xFF3A416F),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
          
          // Footer Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_tempSelectedFilters);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7069FA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Voir $_currentResults résultats',
                  style: GoogleFonts.quicksand(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
