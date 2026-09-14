import 'package:flutter/material.dart';
import 'package:mediqux_mobile/config/theme.dart';

/// Circular initials avatar filled with the brand gradient and a soft glow —
/// used for patient rosters, detail headers, and the account menu trigger.
class GradientAvatar extends StatelessWidget {
  const GradientAvatar({
    required this.initials,
    super.key,
    this.size = 48,
    this.glow = true,
  });

  final String initials;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassColors>()!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: glass.accentGradient,
        shape: BoxShape.circle,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: glass.gradientStart.withValues(alpha: 0.4),
                  blurRadius: size * 0.35,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}
