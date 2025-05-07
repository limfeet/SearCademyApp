import 'package:flutter/material.dart';

class CustomLogo extends StatelessWidget {
  const CustomLogo({
    super.key,
    this.size,
    this.textColor = const Color(0xFF757575),
    this.style = FlutterLogoStyle.markOnly,
    this.duration = const Duration(milliseconds: 750),
    this.curve = Curves.fastOutSlowIn,
    this.imageAsset = 'assets/images/searcademy_icon.png', // 기본 경로
  });

  final double? size;
  final Color textColor;
  final FlutterLogoStyle style;
  final Duration duration;
  final Curve curve;
  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    final IconThemeData iconTheme = IconTheme.of(context);
    final double? iconSize = size ?? iconTheme.size;
    return AnimatedContainer(
      width: iconSize,
      height: iconSize,
      duration: duration,
      curve: curve,
      child: Image.asset(
        imageAsset,
        fit: BoxFit.contain,
      ),
    );
  }
}
