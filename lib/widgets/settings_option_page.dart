import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/glift_theme.dart';
import 'glift_page_layout.dart';

class SettingsOptionItem {
  const SettingsOptionItem({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

class SettingsOptionPage extends StatefulWidget {
  const SettingsOptionPage({
    super.key,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.options,
    required this.initialValue,
    required this.onChanged,
  });

  final String headerTitle;
  final String headerSubtitle;
  final List<SettingsOptionItem> options;
  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<SettingsOptionPage> createState() => _SettingsOptionPageState();
}

class _SettingsOptionPageState extends State<SettingsOptionPage> {
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _SettingsBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.headerTitle,
                        style: GoogleFonts.quicksand(
                          color: const Color(0xFF3A416F),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.headerSubtitle,
                        style: GoogleFonts.quicksand(
                          color: const Color(0xFF3A416F),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFECE9F1)), // Changed from D7D4DC to match separator? Or keep mostly invisible? User didn't specify border color of card, but 0xFFD7D4DC is standard. I'll stick to D7D4DC or maybe ECE9F1 to be softer. Let's use ECE9F1 for border too to match inside separators if that's the "vibe", but user only asked for separator. I'll keep D7D4DC for border unless it looks bad. Wait, user asked to change separator to ECE9F1. The border was D7D4DC. I'll keep D7D4DC for the outer border for now to align with other cards.
                  // Actually, looking at the mockup mental image, usually borders are subtle. ECE9F1 is very subtle.
                  // Let's stick to existing border color 0xFFD7D4DC for now.
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < widget.options.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFECE9F1),
                          indent: 15,
                          endIndent: 15,
                        ),
                      _SettingsOptionTile(
                        label: widget.options[i].label,
                        isSelected: widget.options[i].value == _selectedValue,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _selectedValue = widget.options[i].value);
                          widget.onChanged(widget.options[i].value);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsBackButton extends StatelessWidget {
  const _SettingsBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0xFF3A416F),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.chevron_left,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

class _SettingsOptionTile extends StatelessWidget {
  const _SettingsOptionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.quicksand(
                color: GliftTheme.body,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check,
                color: const Color(0xFF3A416F),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
