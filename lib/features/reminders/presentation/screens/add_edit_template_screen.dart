// lib/features/reminders/presentation/screens/add_edit_template_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/auth/presentation/auth_providers.dart';
import 'package:autoshop_manager/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:drift/drift.dart' as drift;

// --- FIX: Import for the repository provider ---
import 'package:autoshop_manager/features/reminders/data/reminder_repository.dart';

class AddEditTemplateScreen extends ConsumerStatefulWidget {
  final MessageTemplate? template;
  const AddEditTemplateScreen({super.key, this.template});

  bool get isEditing => template != null;

  @override
  ConsumerState<AddEditTemplateScreen> createState() =>
      _AddEditTemplateScreenState();
}

class _AddEditTemplateScreenState extends ConsumerState<AddEditTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.template?.title);
    _contentController = TextEditingController(text: widget.template?.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  String _generateSlug(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-') // Replace non-alphanumeric with hyphens
        .replaceAll(RegExp(r'^-|-$'), '');     // Remove leading/trailing hyphens
  }

  Future<void> _saveTemplate() async {
    if (_formKey.currentState!.validate()) {
      late final String templateType;

      if (!widget.isEditing) {
        templateType = _generateSlug(_titleController.text);
        
        final exists = await ref.read(reminderRepositoryProvider).templateExists(templateType);
        if (exists && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: A template with a similar title already exists. Please use a more unique title.')),
          );
          return;
        }
      } else {
        templateType = widget.template!.templateType;
      }

      final companion = MessageTemplatesCompanion(
        templateType: drift.Value(templateType),
        title: drift.Value(_titleController.text),
        content: drift.Value(_contentController.text),
      );
      await ref.read(remindersNotifierProvider.notifier).saveTemplate(companion);
      if(mounted) context.pop();
    }
  }
  
  Future<void> _deleteTemplate() async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete Template?'),
      content: const Text('This action cannot be undone. Are you sure you want to delete this template?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
      ],
    ));

    if (confirm ?? false) {
      await ref.read(remindersNotifierProvider.notifier).deleteTemplate(widget.template!.templateType);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(authNotifierProvider).isAdmin;
    return Scaffold(
      appBar: CommonAppBar(
        title: widget.isEditing ? 'Edit Template' : 'Add Template',
        showBackButton: true,
        customActions: [
          if(widget.isEditing && isAdmin) IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Template',
            onPressed: _deleteTemplate,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Template Title',
                  helperText: 'e.g., Engine Oil Change Reminder. A unique ID will be generated from this.',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              Card(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                elevation: 0,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Placeholders:\n[CustomerName], [VehicleModel], [VehicleRegistration], [NextServiceMileage], [LastServiceMileage], [LastServiceDate], [WorkshopName], [WorkshopAddress], [WorkshopPhoneNumber], [WorkshopManagerName]', style: TextStyle(color: Colors.grey)),
                )
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Template Content',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveTemplate,
                child: const Text('Save Template'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
