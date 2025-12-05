import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NoteModal extends StatefulWidget {
  final String? initialNote;
  final Function(String) onSave;

  const NoteModal({
    super.key,
    required this.initialNote,
    required this.onSave,
  });

  @override
  State<NoteModal> createState() => _NoteModalState();
}

class _NoteModalState extends State<NoteModal> {
  late final TextEditingController _controller;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final currentText = _controller.text;
    final initialText = widget.initialNote ?? '';
    final hasChanged = currentText != initialText;
    
    if (hasChanged != _hasChanged) {
      setState(() {
        _hasChanged = hasChanged;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
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
          top: 20, // Trait à 20px du haut (padding top of container)
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
            Text(
              'Notes',
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3A416F),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD7D4DC)),
                ),
                child: TextField(
                  controller: _controller,
                  expands: true,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  style: GoogleFonts.quicksand(
                    fontSize: 16, // 16px
                    fontWeight: FontWeight.w600, // Semibold
                    color: const Color(0xFF3A416F),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Ajoutez votre note ici',
                    hintStyle: GoogleFonts.quicksand(
                      fontSize: 16, // 16px
                      fontWeight: FontWeight.w600, // Semibold
                      color: const Color(0xFFC2BFC6),
                    ),
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
                  widget.onSave(_controller.text);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasChanged ? const Color(0xFF7069FA) : const Color(0xFFF8F9FA),
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
                    color: _hasChanged ? Colors.white : const Color(0xFFC2BFC6),
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
