import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Fixiva wordmark. Blue on light surfaces, white on dark.
class FxLogo extends StatelessWidget {
  const FxLogo({this.white = false, this.height = 28, super.key});

  final bool white;
  final double height;

  @override
  Widget build(BuildContext context) {
    final asset = white
        ? 'assets/branding/Fixiva_Logo_white.svg'
        : 'assets/branding/Fixiva_Logo_blue.svg';
    return SvgPicture.asset(asset, height: height, fit: BoxFit.contain);
  }
}

/// Fixiva icon mark for tight spots (nav rail). Blue on light, white on
/// dark — pass [onDark] on the navy rail.
class FxMark extends StatelessWidget {
  const FxMark({this.onDark = false, this.size = 24, super.key});

  final bool onDark;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = onDark
        ? 'assets/branding/Fixiva_icon_white.svg'
        : 'assets/branding/Fixiva_icon_blue.svg';
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
