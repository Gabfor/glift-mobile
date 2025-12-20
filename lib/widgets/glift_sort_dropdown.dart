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
    _removeOverlay();
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
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: _isMenuOpen
                        ? const Color(0xFFA1A5FD)
                        : const Color(0xFFD7D4DC),
                    width: 1.1,
                  ),
                  boxShadow: const [],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(
                            height: 30,
                            width: 30,
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/icons/tri.svg',
                                width: 15,
                                height: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            selectedOption['label'] ?? '',
                            style: GoogleFonts.quicksand(
                              color: const Color(0xFF3A416F),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SvgPicture.asset(
                      'assets/icons/chevron.svg',
                      width: 9,
                      height: 7,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF3A416F),
                        BlendMode.srcIn,
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
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        offset: Offset(0, 12),
                        blurRadius: 32,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
                            horizontal: 10,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 4),
                              Text(
                                option['label']!,
                                style: GoogleFonts.quicksand(
                                  color: isSelected
                                      ? const Color(0xFF7069FA)
                                      : const Color(0xFF3A416F),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
    if (mounted) {
      setState(() {});
    }
  }
}
