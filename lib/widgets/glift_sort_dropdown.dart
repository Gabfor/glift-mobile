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
  bool _isFocused = false;

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

        return CompositedTransformTarget(
          link: _fieldLink,
          child: AnimatedContainer(
            height: 42,
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFocused
                    ? const Color(0xFF7069FA)
                    : const Color(0xFFE4E2EA),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x33000000)
                      .withOpacity(_isFocused ? 0.18 : 0.12),
                  offset: const Offset(0, 10),
                  blurRadius: 28,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Focus(
                    focusNode: _focusNode,
                    onFocusChange: (hasFocus) {
                      setState(() {
                        _isFocused = hasFocus;
                      });

                      if (!hasFocus) {
                        _removeOverlay();
                      }
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (_overlayEntry != null) {
                          _removeOverlay();
                        } else {
                          _focusNode.requestFocus();
                          _showOverlay();
                        }
                      },
                      child: Row(
                        children: [
                          Container(
                            height: 30,
                            width: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F4FF),
                              borderRadius: BorderRadius.circular(9),
                            ),
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
                            widget.options
                                    .firstWhere(
                                      (option) =>
                                          option['value'] == widget.selectedValue,
                                      orElse: () => widget.options.first,
                                    )['label'] ??
                                '',
                            style: GoogleFonts.quicksand(
                              color: const Color(0xFF3A416F),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/chevron.svg',
                  width: 9,
                  height: 7,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF7069FA),
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
                behavior: HitTestBehavior.translucent,
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
                            vertical: 4,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFF5F4FF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                height: 22,
                                width: 22,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF7069FA)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF7069FA)
                                        : const Color(0xFFE6E4ED),
                                    width: 1.1,
                                  ),
                                  boxShadow: isSelected
                                      ? const [
                                          BoxShadow(
                                            color: Color(0x337069FA),
                                            offset: Offset(0, 6),
                                            blurRadius: 14,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                option['label']!,
                                style: GoogleFonts.quicksand(
                                  color: isSelected
                                      ? const Color(0xFF3A416F)
                                      : const Color(0xFF6F6B7A),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
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

    overlay.insert(_overlayEntry!);
    setState(() => _isFocused = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isFocused = false);
    }
  }
}
