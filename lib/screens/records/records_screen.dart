import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.medium(
            title: Text('Records'),
            automaticallyImplyLeading: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList.list(
              children: [
                _RecordTile(
                  icon: Icons.science_rounded,
                  label: 'Lab Reports',
                  description: 'Blood panels, urinalysis, pathology',
                  color: const Color(0xFF0B6E7C),
                  onTap: () => context.push('/lab-reports'),
                ),
                const SizedBox(height: 10),
                _RecordTile(
                  icon: Icons.image_search_rounded,
                  label: 'Diagnostic Studies',
                  description: 'X-rays, MRI, CT scans, ultrasound',
                  color: const Color(0xFF4B5ABF),
                  onTap: () => context.push('/diagnostic-studies'),
                ),
                const SizedBox(height: 10),
                _RecordTile(
                  icon: Icons.receipt_long_rounded,
                  label: 'Prescriptions',
                  description: 'Medication orders and renewals',
                  color: const Color(0xFF1E7E4A),
                  onTap: () => context.push('/prescriptions'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
