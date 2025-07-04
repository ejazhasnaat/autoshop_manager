// lib/features/schedule/presentation/screens/schedule_screen.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/schedule/presentation/schedule_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsForDateProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final stats = ref.watch(appointmentStatsProvider);
    final eventDates = ref.watch(appointmentDatesProvider).value ?? [];

    return Scaffold(
      appBar: const CommonAppBar(title: 'Appointment Schedule'),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLeftPanel(context, ref, stats, eventDates),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Appointments for ${DateFormat.yMMMMd().format(selectedDate)}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: appointmentsAsync.when(
                    data: (appointments) {
                      if (appointments.isEmpty) {
                        return const Center(child: Text('No appointments for this date.'));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: appointments.length,
                        itemBuilder: (context, index) {
                          return _AppointmentCard(appointmentDetails: appointments[index]);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel(BuildContext context, WidgetRef ref,
      AppointmentStats stats, List<DateTime> eventDates) {
    final selectedDate = ref.watch(selectedDateProvider);
    final focusedDate = ref.watch(focusedDateProvider);

    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Date', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Card(
              clipBehavior: Clip.antiAlias,
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: focusedDate,
                calendarFormat: CalendarFormat.month,
                selectedDayPredicate: (day) => isSameDay(selectedDate, day),
                onDaySelected: (newSelectedDay, newFocusedDay) {
                  ref.read(selectedDateProvider.notifier).state = newSelectedDay;
                  ref.read(focusedDateProvider.notifier).state = newFocusedDay;
                },
                eventLoader: (day) {
                  return eventDates.where((eventDate) {
                    return isSameDay(eventDate, day);
                  }).toList();
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _StatRow(label: 'Total Appointments:', value: stats.total.toString()),
            const SizedBox(height: 8),
            _StatRow(label: 'Confirmed:', value: stats.confirmed.toString()),
            const SizedBox(height: 8),
            _StatRow(label: 'Pending:', value: stats.pending.toString()),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentWithDetails appointmentDetails;

  const _AppointmentCard({required this.appointmentDetails});

  Color _getStatusColor(String status, BuildContext context) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.amber.shade700;
      case 'rescheduled':
        return Colors.blue;
      case 'cancelled':
        return Theme.of(context).colorScheme.error;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appointment = appointmentDetails.appointment;
    final customer = appointmentDetails.customer;
    final vehicle = appointmentDetails.vehicle;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat.jm().format(appointment.appointmentDate)} (${appointment.durationInMinutes} min)',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(appointment.status, context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        appointment.status.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Text('ID: APT-${appointment.id.toString().padLeft(3, '0')}', style: theme.textTheme.bodySmall),
              ],
            ),
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(Icons.person_outline, customer.name),
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.phone_outlined, customer.phoneNumber),
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.email_outlined, customer.email ?? 'N/A'),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(Icons.directions_car_outlined, '${vehicle.year} ${vehicle.make} ${vehicle.model}'),
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.build_outlined, appointment.servicesDescription),
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.engineering_outlined, appointment.technicianName ?? 'Unassigned'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (appointment.status == 'pending')
                  ElevatedButton(onPressed: () {}, child: const Text('Confirm')),
                const SizedBox(width: 8),
                TextButton(onPressed: () {}, child: const Text('Reschedule')),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
