import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/widgets/glass_card.dart';
import 'package:mediqux_mobile/widgets/nav_list_tile.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              'Records',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  NavListTile(
                    icon: Icons.science_outlined,
                    label: 'Lab Reports',
                    subtitle: 'Blood panels, urinalysis, pathology',
                    onTap: () => context.push('/lab-reports'),
                  ),
                  const Divider(height: 1),
                  NavListTile(
                    icon: Icons.image_search_outlined,
                    label: 'Diagnostic Studies',
                    subtitle: 'X-rays, MRI, CT scans, ultrasound',
                    onTap: () => context.push('/diagnostic-studies'),
                  ),
                  const Divider(height: 1),
                  NavListTile(
                    icon: Icons.receipt_long_outlined,
                    label: 'Prescriptions',
                    subtitle: 'Medication orders and renewals',
                    onTap: () => context.push('/prescriptions'),
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
