import 'package:flutter/material.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/widgets/glass_card.dart';

/// A single linked item shown inside a [RelatedRecordsSection].
class RelatedRecordItem {
  const RelatedRecordItem({
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onTap;
}

/// Glass panel listing up to a handful of related records (e.g. a patient's
/// recent appointments/prescriptions/conditions), with a "View all" link —
/// mirrors the web app's `RelatedSection` used throughout detail pages.
/// Renders nothing when [items] is empty and [isLoading] is false, so
/// callers can place it unconditionally.
class RelatedRecordsSection extends StatelessWidget {
  const RelatedRecordsSection({
    required this.icon,
    required this.title,
    required this.items,
    super.key,
    this.count,
    this.onViewAll,
    this.isLoading = false,
    this.emptyLabel,
  });

  final IconData icon;
  final String title;
  final int? count;
  final List<RelatedRecordItem> items;
  final VoidCallback? onViewAll;
  final bool isLoading;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;

    if (!isLoading && items.isEmpty && emptyLabel == null) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: glass.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (count != null) ...[
                Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: glass.muted,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (onViewAll != null)
                GestureDetector(
                  onTap: onViewAll,
                  child: Text(
                    'View all',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: glass.gradientEnd,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
            )
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                emptyLabel!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: glass.muted,
                ),
              ),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: InkWell(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  onTap: item.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (item.subtitle != null)
                                Text(
                                  item.subtitle!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: glass.muted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: glass.muted2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
