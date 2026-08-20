import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/glift_theme.dart';

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
    this.fullPageScroll = true,
    this.headerPadding,
    this.overlay,
    this.controller,
    this.backgroundColor,
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

  final bool fullPageScroll;
  final EdgeInsetsGeometry? headerPadding;
  final Widget? overlay;
  final ScrollController? controller;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final effectiveFooterBottom = footerIgnoresViewInsets && resizeToAvoidBottomInset
        ? -mediaQuery.viewInsets.bottom
        : (footerIgnoresViewInsets ? 0.0 : mediaQuery.viewInsets.bottom);
    final additionalBottomSpacing = footer != null
        ? (footerIgnoresViewInsets ? 0.0 : mediaQuery.viewInsets.bottom) + (footerPadding?.vertical ?? 0.0) + 40.0
        : 0.0;
    final headerContent = header ??
        Column(
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

    Widget buildBody({required Widget child}) {
      final contentPadding = (padding ?? const EdgeInsets.fromLTRB(20, 20, 20, 30))
          .add(EdgeInsets.only(bottom: additionalBottomSpacing));

      return Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: GliftTheme.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final paddedChild = Padding(
                padding: contentPadding,
                child: ConstrainedBox(
                  constraints: constraints.hasBoundedHeight
                      ? BoxConstraints(minHeight: constraints.maxHeight)
                      : const BoxConstraints(),
                  child: child,
                ),
              );

              if (fullPageScroll || !scrollable) return paddedChild;

              return SingleChildScrollView(
                controller: controller,
                padding: EdgeInsets.zero,
                child: paddedChild,
              );
            },
          ),
        ),
      );
    }

    Widget withOverlay(Widget body) {
      if (overlay == null) return body;

      return Stack(
        children: [
          body,
          overlay!,
        ],
      );
    }

    if (fullPageScroll) {
      return Scaffold(
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        backgroundColor: backgroundColor ?? GliftTheme.background,
        body: withOverlay(
          Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 300,
                child: Container(color: GliftTheme.accent),
              ),
              SingleChildScrollView(
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      color: GliftTheme.accent,
                      padding: EdgeInsets.only(top: mediaQuery.padding.top),
                      child: Padding(
                        padding: headerPadding ?? const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        child: headerContent,
                      ),
                    ),
                    buildBody(child: child),
                  ],
                ),
              ),
              if (footer != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: effectiveFooterBottom,
                  child: Padding(
                    padding: footerPadding ?? const EdgeInsets.only(bottom: 20),
                    child: footer!,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: backgroundColor ?? GliftTheme.background,
      body: SafeArea(
        bottom: false,
        child: withOverlay(
          Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 200,
                child: Container(color: GliftTheme.accent),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    color: GliftTheme.accent,
                    child: Padding(
                      padding: headerPadding ?? const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      child: headerContent,
                    ),
                  ),
                  Expanded(
                    child: buildBody(child: child),
                  ),
                ],
              ),
              if (footer != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: effectiveFooterBottom,
                  child: Padding(
                    padding: footerPadding ?? const EdgeInsets.only(bottom: 20),
                    child: footer!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
