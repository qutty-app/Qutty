import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum LogoVariant {
  standard, // logo.svg / logo_dark.svg
  withBg, // logo_bg.svg / logo_bg_dark.svg
  textWithBg, // logo_text_d_bg.svg / logo_text_d_bg_dark.svg
  textWithBgAlt, // logo_text_r_bg.svg / logo_text_r_bg_dark.svg
}

class Logo extends StatelessWidget {
  /// Controls which style of the logo to display.
  final LogoVariant variant;

  /// Optional width for the SVG asset.
  final double? width;

  /// Optional height for the SVG asset.
  final double? height;

  /// How to inscribe the logo into the space allocated during layout.
  final BoxFit fit;

  /// Explicitly force dark mode regardless of theme if true.
  /// Force light mode if false.
  /// If null, follows [Theme.of(context).brightness].
  final bool? isDarkMode;

  const Logo({
    super.key,
    this.variant = LogoVariant.standard,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.isDarkMode,
  });

  String _getAssetPath(bool isDark) {
    switch (variant) {
      case LogoVariant.standard:
        return isDark ? 'assets/logo_dark.svg' : 'assets/logo.svg';
      case LogoVariant.withBg:
        return isDark ? 'assets/logo_bg_dark.svg' : 'assets/logo_bg.svg';
      case LogoVariant.textWithBg:
        return isDark
            ? 'assets/logo_text_d_bg_dark.svg'
            : 'assets/logo_text_d_bg.svg';
      case LogoVariant.textWithBgAlt:
        return isDark
            ? 'assets/logo_text_r_bg_dark.svg'
            : 'assets/logo_text_r_bg.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Falls back to system/app theme if isDarkMode is not explicitly passed
    final effectiveIsDark =
        isDarkMode ?? (Theme.of(context).brightness == Brightness.dark);

    final assetPath = _getAssetPath(effectiveIsDark);

    return SvgPicture.asset(assetPath, width: width, height: height, fit: fit);
  }
}
