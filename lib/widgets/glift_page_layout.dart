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

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final footerInset = footerIgnoresViewInsets ? 0.0 : mediaQuery.viewInsets.bottom;
    final additionalBottomSpacing = footer != null
        ? footerInset + (footerPadding?.vertical ?? 0.0) + 40.0
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
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: child,
                ),
              );

              if (!scrollable) return paddedChild;

              return SingleChildScrollView(
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
        backgroundColor: GliftTheme.accent,
        body: withOverlay(
          NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    color: GliftTheme.accent,
                    padding: EdgeInsets.only(top: mediaQuery.padding.top),
                    child: Padding(
                      padding: headerPadding ?? const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      child: headerContent,
                    ),
                  ),
                ),
              ];
            },
            body: buildBody(child: child),
          ),
        ),
        bottomSheet: footer != null
            ? Padding(
                padding: EdgeInsets.only(bottom: footerInset),
                child: Padding(
                  padding: footerPadding ?? const EdgeInsets.only(bottom: 20),
                  child: footer!,
                ),
              )
            : null,
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: GliftTheme.accent,
      body: SafeArea(
        bottom: false,
        child: withOverlay(
          Stack(
            children: [
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
                  bottom: footerInset,
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
