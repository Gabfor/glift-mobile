import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import '../services/settings_service.dart';

class NoteModal extends StatefulWidget {
  final String? initialNote;
  final String? initialMaterial;
  final Function(String) onSave;
  final Function(String) onSaveMaterial;

  const NoteModal({
    super.key,
    required this.initialNote,
    this.initialMaterial,
    required this.onSave,
    required this.onSaveMaterial,
  });

  @override
  State<NoteModal> createState() => _NoteModalState();
}

class _NoteModalState extends State<NoteModal> {
  late final quill.QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _hasChanged = false;
  bool _isFocused = false;
  bool _showTopGradient = false;
  bool _showBottomGradient = false;
  
  // Material editing state
  bool _isEditingMaterial = false;
  late final TextEditingController _materialController;
  final FocusNode _materialFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
    // Initialize Quill Controller with HTML content
    try {
      final delta = HtmlToDelta().convert(widget.initialNote ?? '');
      _controller = quill.QuillController(
        document: quill.Document.fromDelta(delta),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (e) {
      // Fallback for empty or invalid HTML
      _controller = quill.QuillController.basic();
    }

    _materialController = TextEditingController(text: widget.initialMaterial);
    
    // Listen for changes
    _controller.document.changes.listen((_) {
      _onTextChanged();
    });

    _focusNode.addListener(_onFocusChange);
    _materialFocusNode.addListener(_onMaterialFocusChange);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateGradients());
  }

  void _onTextChanged() {
    // Simple check: if document length > 1 (newline is always present) and diff from init
    // For now, always mark as changed if edited, or we can improve this logic later.
    if (!_hasChanged) {
      setState(() {
        _hasChanged = true;
      });
    }
    
    // Schedule gradient update after layout
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateGradients());
  }

  void _onFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  void _onMaterialFocusChange() {
    if (!_materialFocusNode.hasFocus && _isEditingMaterial) {
      widget.onSaveMaterial(_materialController.text);
      setState(() {
        _isEditingMaterial = false;
      });
    }
  }

  void _onScroll() {
    _updateGradients();
  }

  void _updateGradients() {
    if (!_scrollController.hasClients) return;

    final offset = _scrollController.offset;
    final maxScroll = _scrollController.position.maxScrollExtent;

    // Show top gradient if we've scrolled down at all
    final showTop = offset > 0;
    // Show bottom gradient if we can still scroll down
    final showBottom = offset < maxScroll;

    if (showTop != _showTopGradient || showBottom != _showBottomGradient) {
      setState(() {
        _showTopGradient = showTop;
        _showBottomGradient = showBottom;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _scrollController.dispose();
    _materialController.dispose();
    _materialFocusNode.removeListener(_onMaterialFocusChange);
    _materialFocusNode.dispose();
    super.dispose();
  }

  String _getHtmlFromController() {
    final delta = _controller.document.toDelta();
    // Convert Delta to HTML
    final converter = QuillDeltaToHtmlConverter(
      delta.toJson(),
      ConverterOptions(
        converterOptions: OpConverterOptions(
          inlineStylesFlag: true,
        ),
      ),
    );
    return converter.convert();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: (MediaQuery.of(context).viewInsets.bottom > 0
                  ? MediaQuery.of(context).viewInsets.bottom
                  : MediaQuery.of(context).padding.bottom) +
              20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A416F),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Material Section
            if (SettingsService.instance.getMaterialEnabled())
              GestureDetector(
                onTap: () {
                  if (!_isEditingMaterial) {
                    setState(() {
                      _isEditingMaterial = true;
                      if (_materialController.text.isEmpty && widget.initialMaterial != null) {
                        _materialController.text = widget.initialMaterial!;
                      }
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _materialFocusNode.requestFocus();
                    });
                  }
                },
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD7D4DC)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'Matériel : ',
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF3A416F),
                                height: 1.3,
                              ),
                            ),
                            Expanded(
                            child: _isEditingMaterial
                                ? TextField(
                                    controller: _materialController,
                                    focusNode: _materialFocusNode,
                                    style: GoogleFonts.quicksand(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF5D6494),
                                      height: 1.3,
                                      letterSpacing: 0.0,
                                    ),
                                    strutStyle: const StrutStyle(
                                      fontSize: 16,
                                      height: 1.3,
                                      forceStrutHeight: true,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      isCollapsed: true,
                                      contentPadding: EdgeInsets.zero,
                                      hintText: 'Ex: Haltères, Barre...',
                                      hintStyle: GoogleFonts.quicksand(
                                        color: const Color(0xFFD7D4DC),
                                        fontWeight: FontWeight.w600,
                                        height: 1.3,
                                        letterSpacing: 0.0,
                                      ),
                                    ),
                                    onSubmitted: (value) {
                                      widget.onSaveMaterial(value);
                                      setState(() {
                                        _isEditingMaterial = false;
                                      });
                                    },
                                    onEditingComplete: () {
                                      widget.onSaveMaterial(_materialController.text);
                                      setState(() {
                                        _isEditingMaterial = false;
                                      });
                                      FocusScope.of(context).unfocus();
                                    },
                                  )
                                : Text(
                                    _materialController.text.isNotEmpty
                                        ? _materialController.text
                                        : 'Ex: Haltères, Barre...',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _materialController.text.isNotEmpty
                                          ? const Color(0xFF5D6494)
                                          : const Color(0xFFD7D4DC),
                                      height: 1.3,
                                      letterSpacing: 0.0,
                                    ),
                                    strutStyle: const StrutStyle(
                                      fontSize: 16,
                                      height: 1.3,
                                      forceStrutHeight: true,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                          ),
                        ],
                      ),
                    ),
                      if (!_isEditingMaterial) ...[
                        const SizedBox(width: 20),
                        SvgPicture.asset(
                          'assets/icons/edit.svg',
                          width: 15,
                          height: 15,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF5D6494),
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
            Text(
              'Notes',
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3A416F),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _isFocused ? const Color(0xFFA1A5FD) : const Color(0xFFD7D4DC),
                    width: _isFocused ? 2 : 1, 
                  ),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Column(
                    children: [
                       quill.QuillSimpleToolbar(
                        controller: _controller,
                        config: quill.QuillSimpleToolbarConfig(
                          multiRowsDisplay: false, // Force single row like web
                          // flutter_quill multiplies this by 1.4 for total height
                          // 35.7 * 1.4 ≈ 50px (Matches Material block height)
                          toolbarSize: 35.7, 
                          
                          // Enabled options (Web match)
                          showBoldButton: true,
                          showItalicButton: true,
                          showUnderLineButton: true,
                          showStrikeThrough: true,
                          showListBullets: true,
                          showListNumbers: true,
                          
                          // Disabled options (Default is true for many of these)
                          showFontFamily: false,
                          showFontSize: false,
                          showListCheck: false,
                          showQuote: false,
                          showLink: false,
                          showCodeBlock: false,
                          showInlineCode: false,
                          showIndent: false,
                          showHeaderStyle: false,
                          showColorButton: false,
                          showBackgroundColorButton: false,
                          showClearFormat: false,
                          showAlignmentButtons: false,
                          showSearchButton: false,
                          showSubscript: false,
                          showSuperscript: false,
                          showUndo: false,
                          showRedo: false,
                          showDirection: false,
                          showSmallButton: false,

                          color: Colors.white,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFD7D4DC), width: 1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(93, 100, 148, 0.05),
                                offset: Offset(0, 4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          buttonOptions: quill.QuillSimpleToolbarButtonOptions(
                            base: quill.QuillToolbarBaseButtonOptions(
                              iconTheme: quill.QuillIconTheme(
                                iconButtonSelectedData: const quill.IconButtonData(
                                  style: ButtonStyle(
                                   backgroundColor: WidgetStatePropertyAll(Color(0xFFFAFAFF)),
                                   iconColor: WidgetStatePropertyAll(Color(0xFF3A416F)),
                                  ),
                                ),
                                iconButtonUnselectedData: const quill.IconButtonData(
                                  style: ButtonStyle(
                                   iconColor: WidgetStatePropertyAll(Color(0xFF5D6494)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: quill.QuillEditor.basic(
                                controller: _controller,
                                focusNode: _focusNode,
                                scrollController: _scrollController,
                                config: quill.QuillEditorConfig(
                                  placeholder: 'Ajoutez vos notes ici',
                                  // Custom style builder to enforce specific font weights
                                  customStyleBuilder: (attribute) {
                                    if (attribute.key == 'bold') {
                                      return GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w700,
                                      );
                                    }
                                    return GoogleFonts.quicksand();
                                  },
                                  customStyles: quill.DefaultStyles(
                                    paragraph: quill.DefaultTextBlockStyle(
                                      GoogleFonts.quicksand(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF5D6494),
                                      ),
                                      const quill.HorizontalSpacing(0, 0),
                                      const quill.VerticalSpacing(0, 0),
                                      const quill.VerticalSpacing(0, 0),
                                      null,
                                    ),
                                    placeHolder: quill.DefaultTextBlockStyle(
                                       GoogleFonts.quicksand(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFD7D4DC),
                                      ),
                                      const quill.HorizontalSpacing(0, 0),
                                      const quill.VerticalSpacing(0, 0),
                                      const quill.VerticalSpacing(0, 0),
                                      null,
                                    ),
                                    lists: quill.DefaultListBlockStyle(
                                      GoogleFonts.quicksand(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF5D6494),
                                      ),
                                      const quill.HorizontalSpacing(0, 0),
                                      const quill.VerticalSpacing(0, 0),
                                      const quill.VerticalSpacing(0, 0),
                                      null,
                                      null,
                                      indentWidthBuilder: (block, context, indent, width) => const quill.HorizontalSpacing(15.0, 0.0), 
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 20,
                              child: IgnorePointer(
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 150),
                                  opacity: _showTopGradient ? 1.0 : 0.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.white,
                                          Colors.white.withValues(alpha: 0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 20,
                              child: IgnorePointer(
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 150),
                                  opacity: _showBottomGradient ? 1.0 : 0.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.white,
                                          Colors.white.withValues(alpha: 0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_hasChanged) {
                    widget.onSave(_getHtmlFromController());
                    Navigator.of(context).pop();
                  } else {
                    FocusScope.of(context).unfocus();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasChanged ? const Color(0xFF7069FA) : const Color(0xFFF2F1F6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Sauvegarder les notes',
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _hasChanged ? Colors.white : const Color(0xFFD7D4DC),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
