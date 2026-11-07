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
  final ValueNotifier<double> _shadowOpacity = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  void dispose() {
    _shadowOpacity.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical) {
      final double offset = notification.metrics.pixels;
      final double target = (offset / 15.0).clamp(0.0, 1.0);
      if (_shadowOpacity.value != target) {
        _shadowOpacity.value = target;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    const double headerHeight = 84.0;
    const double gapBelowHeader = 10.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Scrollable options list
            NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  headerHeight + gapBelowHeader,
                  20,
                  MediaQuery.of(context).padding.bottom + 40,
                ),
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

            // Header (fixed on top with scroll shadow)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    color: const Color(0xFFF9FAFB),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Row(
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
                  ),
                  ValueListenableBuilder<double>(
                    valueListenable: _shadowOpacity,
                    builder: (context, opacity, _) {
                      return IgnorePointer(
                        child: Opacity(
                          opacity: opacity,
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF1E1742).withValues(alpha: 0.12),
                                  const Color(0xFF1E1742).withValues(alpha: 0.04),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.45, 1.0],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
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
                    child: iconPath!.startsWith('http')
                        ? SvgPicture.network(
                            iconPath!,
                            fit: BoxFit.contain,
                          )
                        : SvgPicture.asset(
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
