import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/glift_theme.dart';

class NoTopOverscrollPhysics extends ClampingScrollPhysics {
  const NoTopOverscrollPhysics({super.parent});

  @override
  NoTopOverscrollPhysics applyTo(ScrollPhysics? ancestor) {
    return NoTopOverscrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (value < position.minScrollExtent) {
      return value - position.minScrollExtent;
    }
    return super.applyBoundaryConditions(position, value);
  }
}

class GliftPageLayout extends StatefulWidget {
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
    this.physics,
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
  final ScrollPhysics? physics;

  @override
  State<GliftPageLayout> createState() => _GliftPageLayoutState();
}

class _GliftPageLayoutState extends State<GliftPageLayout> {
  final ValueNotifier<double> _shadowOpacity = ValueNotifier<double>(0.0);

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
    final mediaQuery = MediaQuery.of(context);
    final effectiveFooterBottom = widget.footerIgnoresViewInsets && widget.resizeToAvoidBottomInset
        ? -mediaQuery.viewInsets.bottom
        : (widget.footerIgnoresViewInsets ? 0.0 : mediaQuery.viewInsets.bottom);
    final additionalBottomSpacing = widget.footer != null
        ? (widget.footerIgnoresViewInsets ? 0.0 : mediaQuery.viewInsets.bottom) + (widget.footerPadding?.vertical ?? 0.0) + 40.0
        : 0.0;
    final headerContent = widget.header ??
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.title != null)
              Text(
                widget.title!,
                style: GoogleFonts.quicksand(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.subtitle!,
                style: GoogleFonts.quicksand(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (widget.headerBottom != null) ...[
              const SizedBox(height: 12),
              widget.headerBottom!,
            ],
          ],
        );

    Widget buildBody({required Widget child}) {
      final contentPadding = (widget.padding ?? const EdgeInsets.fromLTRB(20, 20, 20, 30))
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
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Stack(
            children: [
              SafeArea(
                top: false,
                bottom: false,
                child: widget.fullPageScroll
                    ? Padding(
                        padding: contentPadding,
                        child: child,
                      )
                    : (widget.scrollable
                        ? SingleChildScrollView(
                            controller: widget.controller,
                            physics: widget.physics ?? const NoTopOverscrollPhysics(),
                            padding: EdgeInsets.zero,
                            child: Padding(
                              padding: contentPadding,
                              child: child,
                            ),
                          )
                        : Padding(
                            padding: contentPadding,
                            child: child,
                          )),
              ),
              ValueListenableBuilder<double>(
                valueListenable: _shadowOpacity,
                builder: (context, opacity, _) {
                  if (opacity <= 0.0) return const SizedBox.shrink();
                  return Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 16,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
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
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    Widget withOverlay(Widget body) {
      if (widget.overlay == null) return body;

      return Stack(
        children: [
          body,
          widget.overlay!,
        ],
      );
    }

    Widget scaffold;

    // Si la page active le scroll pleine page (ex: Inscription)
    if (widget.fullPageScroll && widget.scrollable) {
      scaffold = Scaffold(
        resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
        backgroundColor: widget.backgroundColor ?? GliftTheme.background,
        body: withOverlay(
          Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 400,
                child: Container(color: GliftTheme.accent),
              ),
              SingleChildScrollView(
                controller: widget.controller,
                physics: widget.physics ?? const NoTopOverscrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      color: GliftTheme.accent,
                      padding: EdgeInsets.only(top: mediaQuery.padding.top),
                      child: Padding(
                        padding: widget.headerPadding ?? const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        child: headerContent,
                      ),
                    ),
                    buildBody(child: widget.child),
                  ],
                ),
              ),
              if (widget.footer != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: effectiveFooterBottom,
                  child: Padding(
                    padding: widget.footerPadding ?? const EdgeInsets.only(bottom: 20),
                    child: widget.footer!,
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      // Pages avec header fixe et body contrôlé (Connexion, Dashboard, Réglages, Store...)
      scaffold = Scaffold(
        resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
        backgroundColor: widget.backgroundColor ?? GliftTheme.background,
        body: withOverlay(
          Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 400,
                child: Container(color: GliftTheme.accent),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    color: GliftTheme.accent,
                    padding: EdgeInsets.only(top: mediaQuery.padding.top),
                    child: Padding(
                      padding: widget.headerPadding ?? const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      child: headerContent,
                    ),
                  ),
                  Expanded(
                    child: buildBody(child: widget.child),
                  ),
                ],
              ),
              if (widget.footer != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: effectiveFooterBottom,
                  child: Padding(
                    padding: widget.footerPadding ?? const EdgeInsets.only(bottom: 20),
                    child: widget.footer!,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: scaffold,
    );
  }
}
