import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EditNameModal extends StatefulWidget {
  final String title;
  final String description;
  final String initialName;
  final String? fieldLabel;
  final bool showLinkField;
  final String? initialLink;
  final VoidCallback? onDelete;

  const EditNameModal({
    super.key,
    required this.title,
    required this.description,
    required this.initialName,
    this.fieldLabel,
    this.showLinkField = false,
    this.initialLink,
    this.onDelete,
    this.isDeleteEnabled = true,
  });

  final bool isDeleteEnabled;

  @override
  State<EditNameModal> createState() => _EditNameModalState();
}

class _EditNameModalState extends State<EditNameModal> {
  late TextEditingController _controller;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();
  
  late TextEditingController _linkController;
  bool _isLinkFocused = false;
  final FocusNode _linkFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
    
    if (widget.showLinkField) {
      _linkController = TextEditingController(text: widget.initialLink);
      _linkFocusNode.addListener(() {
        setState(() {
          _isLinkFocused = _linkFocusNode.hasFocus;
        });
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    if (widget.showLinkField) {
      _linkController.dispose();
      _linkFocusNode.dispose();
    }
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    widget.title,
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3A416F),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                
                // Description Text
                Center(
                  child: Text(
                    widget.description,
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3A416F),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),

                // Field Label
                if (widget.fieldLabel != null) ...[
                  Text(
                    widget.fieldLabel!,
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3A416F),
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                
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
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (widget.showLinkField) {
                              _linkFocusNode.requestFocus();
                            } else {
                              final newName = _controller.text.trim();
                              if (newName.isNotEmpty) {
                                Navigator.of(context).pop(newName);
                              }
                            }
                          },
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF5D6494),
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(
                              left: 14.5,
                              right: 44.5, // 30 + 14.5 for icon
                            ),
                            hintText: widget.fieldLabel,
                            hintStyle: GoogleFonts.quicksand(
                              color: const Color(0xFFD7D4DC),
                              fontWeight: FontWeight.w700,
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

                if (widget.showLinkField) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Lien',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3A416F),
                    ),
                  ),
                  const SizedBox(height: 5),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: _isLinkFocused ? const Color(0xFFA1A5FD) : const Color(0xFFD7D4DC),
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: _isLinkFocused
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
                            controller: _linkController,
                            focusNode: _linkFocusNode,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              final newName = _controller.text.trim();
                              if (newName.isNotEmpty) {
                                final newLink = _linkController.text.trim();
                                Navigator.of(context).pop({
                                  'name': newName,
                                  'link': newLink.isEmpty ? null : newLink,
                                });
                              }
                            },
                            style: GoogleFonts.quicksand(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF5D6494),
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.only(
                                left: 14.5,
                                right: 44.5,
                              ),
                              hintText: 'Insérez votre lien ici',
                              hintStyle: GoogleFonts.quicksand(
                                color: const Color(0xFFD7D4DC),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        if (_linkController.text.isNotEmpty)
                          Positioned(
                            right: 10,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: () {
                                  _linkController.clear();
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
                ],

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
                          onPressed: _controller.text.trim().isEmpty 
                            ? null 
                            : () {
                                final newName = _controller.text.trim();
                                if (widget.showLinkField) {
                                  final newLink = _linkController.text.trim();
                                  Navigator.of(context).pop({
                                    'name': newName,
                                    'link': newLink.isEmpty ? null : newLink,
                                  });
                                } else {
                                  Navigator.of(context).pop(newName);
                                }
                              },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7069FA),
                            disabledBackgroundColor: const Color(0xFFF2F1F6),
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
                              color: _controller.text.trim().isEmpty 
                                ? const Color(0xFFD7D4DC) 
                                : Colors.white,
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
          
          if (widget.onDelete != null)
            Positioned(
              left: 8,
              top: 8,
              child: IconButton(
                icon: SvgPicture.asset(
                  widget.isDeleteEnabled ? 'assets/icons/delete_red.svg' : 'assets/icons/delete_grey.svg',
                  width: 25,
                  height: 25,
                ),
                onPressed: widget.isDeleteEnabled ? widget.onDelete : null,
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
