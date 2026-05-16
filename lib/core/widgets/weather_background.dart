import 'package:flutter/material.dart';
import '../theme/colors.dart';

class WeatherBackground extends StatelessWidget {
  const WeatherBackground({super.key, required this.child, this.accentColor});

  final Widget child;
  final Color? accentColor;

  static const _defaultAccent = Color(0xFF213560);

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? _defaultAccent;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withAlpha(40),
            TemporaColors.background,
          ],
          stops: const [0.0, 0.28],
        ),
      ),
      child: child,
    );
  }
}
