import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:glift_mobile/theme/glift_colors.dart';

/// Custom toggle switch matching Glift Web's `ToggleSwitch` component.
class GliftSwitch extends StatelessWidget {
  const GliftSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = enabled ? value : false;

    return Semantics(
      toggled: effectiveValue,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                onChanged(!value);
              }
            : null,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: 44,
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              color: effectiveValue
                  ? GliftColors.focusRing
                  : GliftColors.surfaceSubtle,
              border: Border.all(
                color: effectiveValue
                    ? GliftColors.brandPrimary
                    : GliftColors.borderSoft,
                width: 1,
              ),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: effectiveValue
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: GliftColors.surfaceSubtle,
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.2),
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
