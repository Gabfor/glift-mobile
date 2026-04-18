import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/glift_theme.dart';

class EditTrainingNameModal extends StatefulWidget {
  final String initialName;

  const EditTrainingNameModal({
    super.key,
    required this.initialName,
  });

  @override
  State<EditTrainingNameModal> createState() => _EditTrainingNameModalState();
}

class _EditTrainingNameModalState extends State<EditTrainingNameModal> {
  late TextEditingController _controller;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image
                Center(
                  child: SvgPicture.asset(
                    'assets/icons/edit_big.svg',
                    height: 35,
                    width: 35,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                Center(
                  child: Text(
                    'Nom de l’entraînement',
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3A416F),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description Text
                Text(
                  'Vous pouvez modifier le nom de cet entraînement ci-dessous.',
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3A416F),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // TextField (Login style)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: _isFocused ? const Color(0xFFA1A5FD) : const Color(0xFFD7D4DC),
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: _isFocused
                        ? [
                            BoxShadow(
                              color: const Color(0xFFA1A5FD).withOpacity(0.5),
                              offset: Offset.zero,
                              blurRadius: 0,
                              spreadRadius: 0.5,
                            ),
                          ]
                        : [],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: true,
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF5D6494),
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(
                              left: 14.5,
                              right: 44.5, // 30 + 14.5 for icon
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (_controller.text.isNotEmpty)
                        Positioned(
                          right: 10,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                _controller.clear();
                                setState(() {});
                              },
                              child: SvgPicture.asset(
                                'assets/icons/cross_reset.svg',
                                width: 23,
                                height: 23,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFFD7D4DC),
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF3A416F)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            'Annuler',
                            style: GoogleFonts.quicksand(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3A416F),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Valider Button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            final newName = _controller.text.trim();
                            if (newName.isNotEmpty) {
                              Navigator.of(context).pop(newName);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7069FA),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            'Valider',
                            style: GoogleFonts.quicksand(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Close Button (Top Right)
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              icon: const Icon(Icons.close),
              color: const Color(0xFF3A416F),
              iconSize: 24,
              onPressed: () => Navigator.of(context).pop(),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
          ),
        ],
      ),
    );
  }
}
