import 'package:flutter/material.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/widgets/glass_card.dart';

/// A titled glass card grouping related form fields — the form-screen
/// counterpart of the `InfoSection` widget used on detail screens, so
/// "Add/Edit X" screens share the same grouped-card visual language as the
/// rest of the app instead of a flat list of fields on the bare background.
class FormSection extends StatelessWidget {
  const FormSection({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: glass.gradientStart,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
