import 'package:flutter/material.dart';
import 'package:mediqux_mobile/config/theme.dart';

/// A row with a gradient icon chip, title, optional subtitle, and a
/// trailing chevron — the shared list-item style used by both the Records
/// and More hub screens (and anywhere else a simple "go to X" row is
/// needed), so grouped nav lists look consistent across the app.
class NavListTile extends StatelessWidget {
  const NavListTile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
    this.subtitle,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final String? subtitle;

  /// Set for a destructive/warning action (e.g. "Sign Out") — swaps the
  /// chip from the brand gradient to a flat tint of this color, and colors
  /// the label to match.
  final Color? labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    final danger = labelColor != null;

    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: danger ? null : glass.accentGradient,
                color: danger ? labelColor!.withValues(alpha: 0.12) : null,
                borderRadius: const BorderRadius.all(Radius.circular(13)),
                boxShadow: danger
                    ? null
                    : [
                        BoxShadow(
                          color: glass.gradientStart.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Icon(
                icon,
                color: danger ? labelColor : Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: glass.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: glass.muted2, size: 20),
          ],
        ),
      ),
    );
  }
}
