import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/auth/presentation/auth_providers.dart';
import 'package:autoshop_manager/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ManageTemplatesScreen extends ConsumerStatefulWidget {
  const ManageTemplatesScreen({super.key});

  @override
  ConsumerState<ManageTemplatesScreen> createState() => _ManageTemplatesScreenState();
}

class _ManageTemplatesScreenState extends ConsumerState<ManageTemplatesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(messageTemplatesProvider);
    final isAdmin = ref.watch(authNotifierProvider).isAdmin;

    ref.listen<AsyncValue>(remindersNotifierProvider, (_, state) {
      if (state is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
      }
    });

    return Scaffold(
      appBar: const CommonAppBar(title: 'Manage Templates', showBackButton: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search templates...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    ),
                    onChanged: (value) {
                      ref.read(templateSearchQueryProvider.notifier).state = value;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                
                ElevatedButton.icon(
                  onPressed: () => context.go('/reminders/manage-templates/add'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  // --- FIX: Wrapped the ElevatedButton.icon with a Tooltip widget ---
                  Tooltip(
                    message: 'Reset to Defaults',
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.sync),
                      label: const Text('Reset'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Reset Default Templates?'),
                            content: const Text('This will restore the default templates to their original content. Your own custom-added templates will not be affected. Continue?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Reset')),
                            ],
                          ),
                        );
                        if (confirm ?? false) {
                          final success = await ref.read(remindersNotifierProvider.notifier).resetDefaultTemplates();
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Default templates have been reset.')));
                          }
                        }
                      },
                    ),
                  )
                ]
              ],
            ),
          ),
          Expanded(
            child: templatesAsync.when(
              data: (templates) {
                if (templates.isEmpty) {
                  return const Center(
                      child: Text('No templates found.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    return Card(
                      child: ListTile(
                        title: Text(template.title),
                        subtitle: Text(template.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () => context.go('/reminders/manage-templates/edit', extra: template),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Edit Template',
                              onPressed: () => context.go('/reminders/manage-templates/edit', extra: template),
                            ),
                            if (isAdmin)
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                                tooltip: 'Delete Template',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Template?'),
                                      content: Text('Are you sure you want to delete the "${template.title}" template? This action cannot be undone.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(true),
                                          child: const Text('Delete'),
                                          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm ?? false) {
                                    await ref.read(remindersNotifierProvider.notifier).deleteTemplate(template.templateType);
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
