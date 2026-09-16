import 'package:flutter/material.dart';
import 'package:mediqux_mobile/config/theme.dart';

/// Pill badge with a colored status dot + label, matching the web app's
/// semantic status colors (scheduled/completed/cancelled, active/critical,
/// male/female, etc.). Pass [color] explicitly, or use one of the
/// [StatusBadge.tone] presets for a common semantic meaning.
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.label, required this.color, super.key});

  factory StatusBadge.tone(
    BuildContext context, {
    required String label,
    required StatusTone tone,
  }) {
    final glass = Theme.of(context).extension<GlassColors>()!;
    final color = switch (tone) {
      StatusTone.positive => glass.success,
      StatusTone.warning => const Color(0xFFF59E0B),
      StatusTone.critical => const Color(0xFFEF4444),
      StatusTone.neutral => glass.muted,
    };
    return StatusBadge(label: label, color: color);
  }

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: glass.glass2,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        border: Border.all(color: glass.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

enum StatusTone { positive, warning, critical, neutral }
