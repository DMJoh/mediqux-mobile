import 'package:flutter/material.dart';
import 'package:mediqux_mobile/config/theme.dart';

/// Primary CTA styled with the brand gradient fill + a soft matching glow —
/// the mobile equivalent of the web app's `Button variant="primary"`.
/// For secondary/destructive actions, use [OutlinedButton]/[TextButton]
/// (themed as the "ghost"/"danger" variants in [AppTheme]) instead.
class GradientButton extends StatelessWidget {
  const GradientButton({
    required this.onPressed,
    required this.child,
    super.key,
    this.icon,
    this.compact = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;

  /// Smaller padding/font/radius for inline use (e.g. a header "Save"
  /// action) instead of a full-width primary CTA.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassColors>()!;
    final disabled = onPressed == null;
    final radius = compact ? 10.0 : 12.0;

    return Container(
      decoration: BoxDecoration(
        gradient: disabled ? null : glass.accentGradient,
        color: disabled ? glass.glass2 : null,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: glass.gradientStart.withValues(alpha: 0.35),
                  blurRadius: compact ? 10 : 16,
                  offset: Offset(0, compact ? 3 : 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.all(Radius.circular(radius)),
          onTap: onPressed,
          child: Padding(
            padding: compact
                ? const EdgeInsets.symmetric(vertical: 8, horizontal: 14)
                : const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  IconTheme(
                    data: IconThemeData(
                      color: Colors.white,
                      size: compact ? 16 : 20,
                    ),
                    child: icon!,
                  ),
                  const SizedBox(width: 8),
                ],
                DefaultTextStyle(
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 14 : 16,
                  ),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
