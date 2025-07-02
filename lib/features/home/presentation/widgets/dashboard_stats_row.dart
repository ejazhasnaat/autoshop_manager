// lib/features/home/presentation/widgets/dashboard_stats_row.dart
import 'package:autoshop_manager/features/home/presentation/home_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DashboardStatsRow extends ConsumerWidget {
  const DashboardStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeJobsCount = ref.watch(activeJobsCountProvider);
    final vehiclesInQueue = ref.watch(vehiclesInQueueProvider);
    final todaysRevenue = ref.watch(todaysRevenueProvider);
    final avgServiceTime = ref.watch(avgServiceTimeProvider);
    final activeTechnicians = ref.watch(activeTechniciansProvider);
    final inventoryAlerts = ref.watch(inventoryAlertsProvider);

    final activeJobsYesterday = ref.watch(activeJobsYesterdayProvider);
    final revenueYesterday = ref.watch(revenueYesterdayProvider);
    final avgServiceTimeYesterday = ref.watch(avgServiceTimeYesterdayProvider);
    
    return Row(
      children: [
        Expanded(
          child: _DashboardStatCard(
            title: 'Active Jobs',
            value: activeJobsCount.when(data: (d) => d.toString(), error: (e,s) => '!', loading: () => '...'),
            icon: Icons.directions_car_outlined,
            iconColor: Colors.blue.shade600,
            change: activeJobsCount.value != null ? (activeJobsCount.value! - activeJobsYesterday).toDouble() : null,
            changeText: 'from yesterday',
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _DashboardStatCard(
            title: 'Vehicles in Queue',
            value: vehiclesInQueue.toString(),
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange.shade700,
            sublabel: '2 urgent repairs',
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _DashboardStatCard(
            title: "Today's Revenue",
            value: todaysRevenue.when(data: (d) => NumberFormat.currency(symbol: '\$').format(d), error: (e,s) => '!', loading: () => '...'),
            icon: Icons.attach_money,
            iconColor: Colors.green.shade600,
            change: revenueYesterday > 0 && todaysRevenue.value != null ? ((todaysRevenue.value! - revenueYesterday) / revenueYesterday * 100) : null,
            changeText: 'vs yesterday',
            isPercentage: true,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _DashboardStatCard(
            title: 'Avg. Service Time',
            value: avgServiceTime.when(data: (d) => '${d.inHours}h ${d.inMinutes.remainder(60)}m', error: (e,s) => '!', loading: () => '...'),
            icon: Icons.timer_outlined,
            iconColor: Colors.purple.shade600,
            change: avgServiceTime.value != null ? (avgServiceTime.value!.inMinutes - avgServiceTimeYesterday.inMinutes).toDouble() : null,
            changeText: 'min improved',
            isInverted: true,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _DashboardStatCard(
            title: 'Active Technicians',
            value: '${activeTechnicians.active}/${activeTechnicians.total}',
            icon: Icons.people_alt_outlined,
            iconColor: Colors.cyan.shade600,
            sublabel: '2 on break',
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _DashboardStatCard(
            title: 'Inventory Alerts',
            value: inventoryAlerts.when(data: (d) => d.toString(), error: (e,s) => '!', loading: () => '...'),
            icon: Icons.error_outline,
            iconColor: Colors.red.shade700,
            sublabel: 'Low stock items',
          ),
        ),
      ],
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? sublabel;
  final double? change;
  final String? changeText;
  final bool isPercentage;
  final bool isInverted;

  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.sublabel,
    this.change,
    this.changeText,
    this.isPercentage = false,
    this.isInverted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    bool isPositive = (change ?? 0) >= 0;
    if (isInverted) isPositive = !isPositive;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: textTheme.titleSmall),
                Icon(icon, color: iconColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (sublabel != null)
              Text(sublabel!, style: textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
            if (change != null && changeText != null)
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isPositive ? Colors.green : Colors.red,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isPercentage ? change!.toStringAsFixed(1) : change!.abs().toInt()}${isPercentage ? '%' : ''}',
                    style: textTheme.bodySmall?.copyWith(
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(changeText!, style: textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

