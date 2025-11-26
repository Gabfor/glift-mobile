import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GliftPageLayout extends StatelessWidget {
  const GliftPageLayout({
    super.key,
    this.title,
    this.subtitle,
    this.header,
    this.headerBottom,
    required this.child,
    this.footer,
    this.padding,
    this.scrollable = true,
    this.footerPadding,
    this.footerIgnoresViewInsets = false,
    this.resizeToAvoidBottomInset = true,
  });

  final String? title;
  final String? subtitle;
  final Widget? header;
  final Widget? headerBottom;
  final Widget child;
  final Widget? footer;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;
  final EdgeInsetsGeometry? footerPadding;
  final bool footerIgnoresViewInsets;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final headerContent = header ?? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Text(
            title!,
            style: GoogleFonts.quicksand(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: GoogleFonts.quicksand(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (headerBottom != null) ...[
          const SizedBox(height: 12),
          headerBottom!,
        ],
      ],
    );

    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF7069FA),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: headerContent,
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: scrollable
                          ? SingleChildScrollView(
                              padding: padding ?? const EdgeInsets.fromLTRB(20, 20, 20, 30),
                              child: child,
                            )
                          : Padding(
                              padding: padding ?? const EdgeInsets.fromLTRB(20, 20, 20, 30),
                              child: child,
                            ),
                    ),
                    if (footer != null)
                      MediaQuery.removeViewInsets(
                        context: context,
                        removeBottom: footerIgnoresViewInsets,
                        child: Padding(
                          padding:
                              footerPadding ?? const EdgeInsets.only(bottom: 20),
                          child: footer!,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
