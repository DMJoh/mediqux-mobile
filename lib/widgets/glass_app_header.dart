import 'package:flutter/material.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/widgets/gradient_avatar.dart';

/// Flat "Back + title" header for detail/form screens, replacing the old
/// full-bleed gradient hero banner — mirrors the web app's plainer "Back
/// link above a glass card" detail layout.
class GlassAppHeader extends StatelessWidget {
  const GlassAppHeader({
    required this.title,
    required this.onBack,
    this.subtitle,
    this.avatarText,
    this.chips = const [],
    this.actions = const [],
    super.key,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final String? avatarText;
  final List<String> chips;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: onBack,
                ),
                const Spacer(),
                if (actions.isNotEmpty)
                  Row(mainAxisSize: MainAxisSize.min, children: actions),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (avatarText != null) ...[
                    GradientAvatar(initials: avatarText!, size: 52),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: glass.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (chips.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: chips
                                .map(
                                  (label) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: glass.glass2,
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(999),
                                      ),
                                      border: Border.all(
                                        color: glass.glassBorder,
                                      ),
                                    ),
                                    child: Text(
                                      label,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
