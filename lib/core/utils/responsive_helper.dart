import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.height < 600;
  }

  static bool isMediumScreen(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return height >= 600 && height < 900;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.height >= 900;
  }

  static double getAdaptivePadding(BuildContext context) {
    if (isSmallScreen(context)) return 16.0;
    if (isMediumScreen(context)) return 24.0;
    return 32.0;
  }

  static double getAdaptiveIconSize(BuildContext context) {
    if (isSmallScreen(context)) return 80.0;
    if (isMediumScreen(context)) return 100.0;
    return 120.0;
  }

  static double getAdaptiveTitleSize(BuildContext context) {
    if (isSmallScreen(context)) return 24.0;
    if (isMediumScreen(context)) return 26.0;
    return 28.0;
  }

  static double getAdaptiveSubtitleSize(BuildContext context) {
    if (isSmallScreen(context)) return 18.0;
    if (isMediumScreen(context)) return 20.0;
    return 22.0;
  }

  static double getAdaptiveDescriptionSize(BuildContext context) {
    if (isSmallScreen(context)) return 14.0;
    if (isMediumScreen(context)) return 15.0;
    return 16.0;
  }

  static double getAdaptiveSpacing(BuildContext context) {
    if (isSmallScreen(context)) return 12.0;
    if (isMediumScreen(context)) return 16.0;
    return 24.0;
  }

  static EdgeInsets getAdaptivePaddingAll(BuildContext context) {
    final padding = getAdaptivePadding(context);
    return EdgeInsets.all(padding);
  }

  static EdgeInsets getAdaptivePaddingSymmetric(BuildContext context, {double? horizontal, double? vertical}) {
    final padding = getAdaptivePadding(context);
    return EdgeInsets.symmetric(horizontal: horizontal ?? padding, vertical: vertical ?? padding);
  }
}
