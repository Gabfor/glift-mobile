import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class GliftSortDropdown extends StatefulWidget {
  final List<Map<String, String>> options;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const GliftSortDropdown({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  State<GliftSortDropdown> createState() => _GliftSortDropdownState();
}

class _GliftSortDropdownState extends State<GliftSortDropdown> {
  final LayerLink _fieldLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  double? _fieldWidth;

  bool get _isMenuOpen => _overlayEntry != null;

  @override
  void dispose() {
    _removeOverlay(rebuild: false);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _fieldWidth = constraints.maxWidth;

        final selectedOption = widget.options.firstWhere(
          (option) => option['value'] == widget.selectedValue,
          orElse: () => widget.options.first,
        );

        return CompositedTransformTarget(
          link: _fieldLink,
          child: Focus(
            focusNode: _focusNode,
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                _removeOverlay();
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleOverlay,
              child: AnimatedContainer(
                height: 40,
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: _isMenuOpen
                        ? const Color(0xFFA1A5FD)
                        : const Color(0xFFD7D4DC),
                    width: 1.0,
                  ),
                  boxShadow: _isMenuOpen
                      ? [
                          BoxShadow(
                            color: const Color(0xFFA1A5FD).withValues(alpha: 0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : const [],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/tri.svg',
                            width: 16,
                            height: 14,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedOption['label'] ?? '',
                              style: GoogleFonts.quicksand(
                                color: const Color(0xFF3A416F),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: _isMenuOpen ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: SvgPicture.asset(
                        'assets/icons/chevron.svg',
                        width: 9,
                        height: 6,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF3A416F),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleOverlay() {
    if (_overlayEntry != null) {
      _removeOverlay();
    } else {
      _focusNode.requestFocus();
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _removeOverlay,
                onPanDown: (_) => _removeOverlay(),
              ),
            ),
            CompositedTransformFollower(
              link: _fieldLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 8),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: _fieldWidth ?? 0,
                  constraints: const BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        offset: Offset(0, 2),
                        blurRadius: 9,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    children: widget.options.map((option) {
                      final isSelected = widget.selectedValue == option['value'];

                      return InkWell(
                        onTap: () {
                          widget.onChanged(option['value']!);
                          _removeOverlay();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFAFAFF)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            option['label']!,
                            style: GoogleFonts.quicksand(
                              color: isSelected
                                  ? const Color(0xFF7069FA)
                                  : const Color(0xFF3A416F),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    setState(() {});

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay({bool rebuild = true}) {
    if (!mounted) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
    if (rebuild && mounted) {
      setState(() {});
    }
  }
}
