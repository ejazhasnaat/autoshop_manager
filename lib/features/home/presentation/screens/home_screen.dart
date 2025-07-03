// lib/features/home/presentation/screens/home_screen.dart
import 'package:autoshop_manager/features/home/presentation/widgets/active_jobs_section.dart';
import 'package:autoshop_manager/features/home/presentation/widgets/dashboard_stats_row.dart';
import 'package:autoshop_manager/features/home/presentation/widgets/management_cards_row.dart';
import 'package:autoshop_manager/features/home/presentation/widgets/quick_actions_panel.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Dashboard'),
      body: SingleChildScrollView(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWide = constraints.maxWidth > 1200;
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DashboardStatsRow(),
                  const SizedBox(height: 24),
                  isWide
                      ? const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: ActiveJobsSection()),
                            SizedBox(width: 24),
                            Expanded(flex: 3, child: QuickActionsPanel()),
                          ],
                        )
                      : const Column(
                          children: [
                            ActiveJobsSection(),
                            SizedBox(height: 24),
                            QuickActionsPanel(),
                          ],
                        ),
                  const SizedBox(height: 24),
                  // ADDED: Title for the management cards section.
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Manage Data',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const ManagementCardsRow(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

