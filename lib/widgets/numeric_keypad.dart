import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.onNumber,
    required this.onBackspace,
    required this.onDecimal,
    required this.onClose,
  });

  final ValueChanged<String> onNumber;
  final VoidCallback onBackspace;
  final VoidCallback onDecimal;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: const Color(0xFF7069FA).withOpacity(0.1), // Light violet tint
          padding: const EdgeInsets.only(bottom: 20, top: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button bar
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: onClose,
                  child: const Icon(Icons.keyboard_hide, color: Color(0xFF3A416F)),
                ),
              ),
              _buildRow(['1', '2', '3']),
              _buildRow(['4', '5', '6']),
              _buildRow(['7', '8', '9']),
              _buildRow([',', '0', '⌫']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        return Expanded(
          child: _KeypadButton(
            text: key,
            onTap: () {
              if (key == '⌫') {
                onBackspace();
              } else if (key == ',') {
                onDecimal();
              } else {
                onNumber(key);
              }
            },
          ),
        );
      }).toList(),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 60,
        margin: const EdgeInsets.all(4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: GoogleFonts.quicksand(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3A416F),
          ),
        ),
      ),
    );
  }
}
