import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/glift_theme.dart';

class SettingsOptionItem {
  const SettingsOptionItem({
    required this.value,
    required this.label,
    this.iconPath,
  });

  final String value;
  final String label;
  final String? iconPath;
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
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFECE9F1)),
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
                            iconPath: widget.options[i].iconPath,
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
    this.iconPath,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String? iconPath;
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
            if (iconPath != null) ...[
              SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SvgPicture.asset(
                      iconPath!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
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
                color: Color(0xFF3A416F),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
