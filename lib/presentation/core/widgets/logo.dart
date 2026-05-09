import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum LogoSize { sm, md, lg }

enum LogoLayout { horizontal, vertical }

class Logo extends StatelessWidget {
  final LogoSize? size;
  final LogoLayout? layout;

  const Logo({
    super.key,
    this.size = LogoSize.md,
    this.layout = LogoLayout.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? LogoSize.md;
    final effectiveLayout = layout ?? LogoLayout.horizontal;

    double iconHeight;
    double nameHeight;
    double spacing;

    switch (effectiveSize) {
      case LogoSize.lg:
        iconHeight = 80.0;
        nameHeight = 36.0;
        spacing = 16.0;
        break;
      case LogoSize.sm:
        iconHeight = 28.0;
        nameHeight = 16.0;
        spacing = 6.0;
        break;
      case LogoSize.md:
        iconHeight = 44.0;
        nameHeight = 22.0;
        spacing = 10.0;
        break;
    }

    final iconSvg = SvgPicture.asset(
      'assets/icons/icon_app.svg',
      height: iconHeight,
    );

    final nameSvg = SvgPicture.asset(
      'assets/icons/name_scanni.svg',
      height: nameHeight,
    );

    if (effectiveLayout == LogoLayout.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconSvg,
          SizedBox(height: spacing),
          nameSvg,
        ],
      );
    }

    // Horizontal layout (AppBar / Home header)
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconSvg,
        SizedBox(width: spacing),
        nameSvg,
      ],
    );
  }
}
