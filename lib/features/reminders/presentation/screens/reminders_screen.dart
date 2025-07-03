// lib/features/reminders/presentation/screens/reminders_screen.dart
import 'package:autoshop_manager/data/repositories/customer_repository.dart';
import 'package:autoshop_manager/features/settings/presentation/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/customer/presentation/customer_providers.dart';
import 'package:autoshop_manager/features/reminders/presentation/providers/reminder_providers.dart' hide shopSettingsProvider;
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  final int? customerId;
  final bool showCloseButton;

  const RemindersScreen({super.key, this.customerId, this.showCloseButton = false});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  CustomerWithVehicles? _selectedCustomer;
  Vehicle? _selectedVehicle;
  MessageTemplate? _selectedTemplate;
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    if (widget.customerId != null) {
      _prefillData();
    }
  }

  void _prefillData() async {
    await Future.delayed(const Duration(milliseconds: 100)); 
    final customers = ref.read(customerListProvider).valueOrNull ?? [];
    if (customers.isEmpty || !mounted) return;
    
    final customer = customers.firstWhereOrNull((c) => c.customer.id == widget.customerId);
    if(customer != null) {
      setState(() {
        _selectedCustomer = customer;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _populateMessage(ShopSetting shopSettings) {
    if (_selectedCustomer == null || _selectedVehicle == null || _selectedTemplate == null) {
      _messageController.clear();
      return;
    }
    
    final lastMileage = _selectedVehicle!.lastEngineOilChangeMileage ?? _selectedVehicle!.lastGeneralServiceMileage ?? 0;
    final nextMileage = lastMileage + 5000;

    String message = _selectedTemplate!.content;
    
    message = message.replaceAll('[CustomerName]', _selectedCustomer!.customer.name);
    message = message.replaceAll('[VehicleModel]', '${_selectedVehicle!.make ?? ''} ${_selectedVehicle!.model ?? ''}');
    message = message.replaceAll('[VehicleRegistration]', _selectedVehicle!.registrationNumber);
    message = message.replaceAll('[NextServiceMileage]', nextMileage.toString());
    message = message.replaceAll('[LastServiceMileage]', lastMileage.toString());
    
    final lastServiceDate = _selectedVehicle!.lastEngineOilChangeDate ?? _selectedVehicle!.lastGeneralServiceDate;
    message = message.replaceAll('[LastServiceDate]', lastServiceDate != null ? DateFormat.yMMMd().format(lastServiceDate) : 'N/A');

    message = message.replaceAll('[WorkshopName]', shopSettings.workshopName);
    message = message.replaceAll('[WorkshopAddress]', shopSettings.workshopAddress);
    message = message.replaceAll('[WorkshopPhoneNumber]', shopSettings.workshopPhoneNumber);
    message = message.replaceAll('[WorkshopManagerName]', shopSettings.workshopManagerName);
    
    _messageController.text = message;
  }
  
  void _sendMessage(String scheme, String phoneNumber) async {
    final encodedMessage = Uri.encodeComponent(_messageController.text);
    final isWhatsApp = scheme.contains('wa.me');
    final url = isWhatsApp ? Uri.parse('$scheme$phoneNumber?text=$encodedMessage') : Uri.parse('$scheme:$phoneNumber?body=$encodedMessage');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch app for $scheme.')));
      }
    }
  }
  
  void _prefillFromUpcoming(ShopSetting shopSettings, CustomerWithVehicles customer, Vehicle vehicle) {
    setState(() {
      _selectedCustomer = customer;
      _selectedVehicle = vehicle;
      _populateMessage(shopSettings);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool canSend = _selectedCustomer != null && _selectedVehicle != null && _selectedTemplate != null;

    return Scaffold(
      appBar: CommonAppBar(title: 'Reminders'),
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Send Reminder'),
                Tab(text: 'Upcoming'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSendReminderTab(canSend),
                _buildUpcomingRemindersTab(),
              ],
            ),
          )
        ],
      )
    );
  }

  Widget _buildSendReminderTab(bool canSend) {
    final customersAsync = ref.watch(customerListProvider);
    final templatesAsync = ref.watch(messageTemplatesProvider);
    final workshopSettingsAsync = ref.watch(shopSettingsProvider);

    return workshopSettingsAsync.when(
      data: (shopSettings) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              customersAsync.when(
                data: (customers) => DropdownButtonFormField<CustomerWithVehicles>(
                  value: _selectedCustomer,
                  decoration: const InputDecoration(labelText: 'Select Customer', border: OutlineInputBorder()),
                  items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.customer.name))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCustomer = val;
                      _selectedVehicle = null;
                      _populateMessage(shopSettings);
                    });
                  },
                ),
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (e,s) => const Center(child: Text("Error loading customers"))
              ),
              const SizedBox(height: 16),
              if (_selectedCustomer != null)
                DropdownButtonFormField<Vehicle>(
                  value: _selectedVehicle,
                  decoration: const InputDecoration(labelText: 'Select Vehicle', border: OutlineInputBorder()),
                  items: _selectedCustomer!.vehicles.map((v) => DropdownMenuItem(value: v, child: Text(v.registrationNumber))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedVehicle = val;
                      _populateMessage(shopSettings);
                    });
                  },
                ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: templatesAsync.when(
                      data: (templates) {
                        final MessageTemplate? currentSelection = _selectedTemplate == null
                            ? null
                            : templates.firstWhereOrNull((t) => t.templateType == _selectedTemplate!.templateType);

                        return DropdownButtonFormField<MessageTemplate>(
                          value: currentSelection,
                          decoration: const InputDecoration(labelText: 'Select Template', border: OutlineInputBorder()),
                          items: templates.map((t) => DropdownMenuItem(value: t, child: Text(t.title))).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedTemplate = val;
                              _populateMessage(shopSettings);
                            });
                          },
                        );
                      },
                      loading: () => const Center(child: LinearProgressIndicator()),
                      error: (e,s) => const Center(child: Text("Error loading templates"))
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/reminders/manage-templates'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Manage Templates'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message Preview',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.sms),
                    label: const Text('Send SMS'),
                    onPressed: canSend ? () => _sendMessage('sms', _selectedCustomer!.customer.phoneNumber) : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.chat),
                    label: const Text('Send WhatsApp'),
                    onPressed: canSend ? () => _sendMessage('https://wa.me/', _selectedCustomer!.customer.whatsappNumber ?? _selectedCustomer!.customer.phoneNumber) : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                  ),
                ],
              )
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading workshop settings: $err')),
    );
  }

  Widget _buildUpcomingRemindersTab() {
    final upcomingAsync = ref.watch(upcomingRemindersProvider);
    final workshopSettingsAsync = ref.watch(shopSettingsProvider);

    return upcomingAsync.when(
      data: (vehicles) {
        if (vehicles.isEmpty) {
          return const Center(child: Text('No upcoming reminders in the next 7 days.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: vehicles.length,
          itemBuilder: (context, index) {
            return _UpcomingReminderTile(
              vehicle: vehicles[index],
              onSend: (customer) {
                final shopSettings = workshopSettingsAsync.value;
                if (shopSettings != null) {
                  _prefillFromUpcoming(shopSettings, customer, vehicles[index]);
                }
                _tabController.animateTo(0);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _UpcomingReminderTile extends ConsumerWidget {
  final Vehicle vehicle;
  final Function(CustomerWithVehicles) onSend;

  const _UpcomingReminderTile({required this.vehicle, required this.onSend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerByIdProvider(vehicle.customerId));
    final reminderNotifier = ref.read(remindersNotifierProvider.notifier);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        title: Text('${vehicle.make ?? ''} ${vehicle.model ?? ''} - ${vehicle.registrationNumber}'),
        subtitle: Text(
          '${vehicle.nextReminderType ?? 'Service'} due on ${DateFormat.yMMMd().format(vehicle.nextReminderDate!)}',
          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0).copyWith(top: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customerAsync.when(
                  data: (customer) => Text('Customer: ${customer?.customer.name ?? 'N/A'}'),
                  loading: () => const Text('Customer: Loading...'),
                  error: (e, s) => const Text('Customer: Error'),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('Send'),
                      onPressed: () {
                        final customer = customerAsync.value;
                        if(customer != null) {
                           onSend(customer);
                        }
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.snooze),
                      label: const Text('Snooze'),
                      onPressed: () async {
                        final newDate = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                        if (newDate != null) {
                           reminderNotifier.snoozeReminder(vehicle.id, newDate);
                        }
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.do_not_disturb_on),
                      label: const Text('Stop'),
                      onPressed: () async {
                         final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                            title: const Text('Stop Reminders?'),
                            content: const Text('This will permanently stop all future reminders for this vehicle. Are you sure?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Stop')),
                            ],
                         ));
                         if(confirm ?? false) {
                            reminderNotifier.stopReminder(vehicle.id);
                         }
                      },
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

