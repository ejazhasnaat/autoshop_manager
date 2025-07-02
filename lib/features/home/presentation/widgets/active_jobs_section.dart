// lib/features/home/presentation/widgets/active_jobs_section.dart
import 'dart:async';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/repair_job/presentation/notifiers/add_edit_repair_job_notifier.dart';
import 'package:autoshop_manager/features/repair_job/presentation/providers/repair_job_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ActiveJobsSection extends ConsumerStatefulWidget {
  const ActiveJobsSection({super.key});

  @override
  ConsumerState<ActiveJobsSection> createState() => _ActiveJobsSectionState();
}

class _ActiveJobsSectionState extends ConsumerState<ActiveJobsSection> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeJobsAsync = ref.watch(activeRepairJobsProvider);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Icon(Icons.build_circle_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Active Jobs', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 8),
                activeJobsAsync.when(
                  data: (jobs) => Text(
                    '${jobs.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
                  ),
                  loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (e,s) => const Icon(Icons.error, color: Colors.red, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 550, 
              ),
              child: activeJobsAsync.when(
                data: (jobs) {
                  if (jobs.isEmpty) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48.0),
                      child: Text('No active jobs.'),
                    ));
                  }
                  return Scrollbar(
                    controller: _scrollController,
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: jobs.length,
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) => _ActiveJobCard(jobWithCustomer: jobs[index]),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => const Center(child: Text('Could not load active jobs.')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveJobCard extends ConsumerStatefulWidget {
  final RepairJobWithCustomer jobWithCustomer;
  const _ActiveJobCard({required this.jobWithCustomer});

  @override
  ConsumerState<_ActiveJobCard> createState() => _ActiveJobCardState();
}

class _ActiveJobCardState extends ConsumerState<_ActiveJobCard> {
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  bool _isCompleting = false;
  String _jobTimerState = 'not_started';

  @override
  void initState() {
    super.initState();
    final status = widget.jobWithCustomer.repairJob.status;
    if (status == 'In Progress') {
      _jobTimerState = 'running';
      _startTimer();
    } else if (status == 'Paused') {
      _jobTimerState = 'paused';
    } else {
      _jobTimerState = 'not_started';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _jobTimerState == 'running') {
        setState(() {
          _elapsedTime += const Duration(seconds: 1);
        });
      }
    });
  }

  // --- FIX ---
  // The method is now async and includes a try/catch block for robust error handling.
  Future<void> _handleTimerButtonPress() async {
    final notifier = ref.read(addEditRepairJobNotifierProvider(widget.jobWithCustomer.repairJob.id).notifier);
    
    final String targetStatus;
    if (_jobTimerState == 'running') {
      targetStatus = 'Paused';
    } else {
      targetStatus = 'In Progress';
    }

    try {
      notifier.setStatus(targetStatus);
      await notifier.saveJob(); // Await the save operation
      
      // Only update the local UI state if the save was successful
      if (mounted) {
        setState(() {
          if (targetStatus == 'Paused') {
            _timer?.cancel();
            _jobTimerState = 'paused';
          } else {
            _startTimer();
            _jobTimerState = 'running';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating job status: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.jobWithCustomer.repairJob;
    final customer = widget.jobWithCustomer.customer;
    final vehicle = widget.jobWithCustomer.vehicle;
    final theme = Theme.of(context);

    final (priorityLabel, priorityColor) = switch(job.priority) {
      'Normal' => ('Normal', Colors.blue),
      'High' => ('High', Colors.orange),
      'Urgent' => ('Urgent', Colors.red),
      _ => ('Normal', Colors.grey),
    };

    final (timerButtonIcon, timerButtonLabel) = switch (_jobTimerState) {
      'running' => (Icons.pause, 'Pause'),
      'paused' => (Icons.play_arrow, 'Resume'),
      _ => (Icons.play_arrow, 'Start'),
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.dividerColor, width: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.go('/repairs/edit/${job.id}'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('JOB-${job.id.toString().padLeft(3, '0')}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Chip(
                        label: Text(priorityLabel, style: theme.textTheme.labelSmall?.copyWith(color: priorityColor)),
                        backgroundColor: priorityColor.withOpacity(0.1),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        side: BorderSide(color: priorityColor.withOpacity(0.3)),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(job.status, style: theme.textTheme.labelSmall),
                        backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(customer.name, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('|', style: TextStyle(color: theme.colorScheme.outline)),
                  ),
                  Icon(Icons.directions_car, size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${vehicle.make} ${vehicle.model} ${vehicle.year} (${vehicle.registrationNumber})',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              
              ref.watch(repairJobDetailsProvider(job.id)).when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                ),
                error: (err, stack) => Text('Could not load services.', style: TextStyle(color: theme.colorScheme.error)),
                data: (details) {
                  final services = details.serviceItems;
                  if (services.isEmpty) {
                    return Text(job.notes ?? 'No services listed.', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600));
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Services:', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      ...services.map((item) => Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
                        child: Text('• ${item.description}', style: theme.textTheme.bodyMedium),
                      )),
                    ],
                  );
                },
              ),

              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Icon(Icons.handyman_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text('Mike Rodriguez', style: theme.textTheme.bodySmall)
                  ]),
                  Row(children: [
                    const Icon(Icons.timer_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text('Elapsed: ${_formatDuration(_elapsedTime)}', style: theme.textTheme.bodySmall)
                  ]),
                  Text('ETA: 30m', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: OutlinedButton.icon(
                      onPressed: _handleTimerButtonPress,
                      icon: Icon(timerButtonIcon, size: 18),
                      label: Text(timerButtonLabel),
                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isCompleting ? null : () async {
                      setState(() { _isCompleting = true; });
                      final BuildContext currentContext = context;
                      try {
                        final notifier = ref.read(addEditRepairJobNotifierProvider(job.id).notifier);
                        final completedId = await notifier.completeAndBillJob();
                        
                        if (currentContext.mounted) {
                          currentContext.go('/repairs/edit/$completedId/receipt');
                          ScaffoldMessenger.of(currentContext).showSnackBar(
                            const SnackBar(
                              content: Text('Job Completed!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error completing job: $e'),
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                           setState(() { _isCompleting = false; });
                        }
                      }
                    },
                    icon: _isCompleting 
                      ? Container(
                          width: 18,
                          height: 18,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, size: 18),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

