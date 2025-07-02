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
        // Using a LayoutBuilder to create a responsive layout for larger screens
        child: LayoutBuilder(
          builder: (context, constraints) {
            // On smaller screens, stack the panels vertically. On larger screens, show them side-by-side.
            bool isWide = constraints.maxWidth > 1200;
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
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
                  const SizedBox(height: 24), // Added spacing
                  const ManagementCardsRow(), // Added the new widget
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

