// lib/features/settings/presentation/screens/settings_screen.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/data/repositories/preference_repository.dart';
import 'package:autoshop_manager/features/auth/presentation/auth_providers.dart';
import 'package:autoshop_manager/features/settings/domain/models/country.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:autoshop_manager/features/settings/presentation/settings_providers.dart';

// --- FIX: Updated the bundle provider to include the new countries list ---
final settingsBundleProvider =
    Provider<AsyncValue<(UserPreferences, ShopSetting, List<Country>)>>((ref) {
  final userPrefsAsync = ref.watch(userPreferencesStreamProvider);
  final workshopSettingsAsync = ref.watch(shopSettingsProvider);
  final countriesAsync = ref.watch(countriesProvider);

  if (userPrefsAsync.hasValue &&
      workshopSettingsAsync.hasValue &&
      countriesAsync.hasValue) {
    return AsyncData((
      userPrefsAsync.value!,
      workshopSettingsAsync.value!,
      countriesAsync.value!
    ));
  }

  // Propagate the first error found
  if (userPrefsAsync.hasError) return AsyncError(userPrefsAsync.error!, userPrefsAsync.stackTrace!);
  if (workshopSettingsAsync.hasError) return AsyncError(workshopSettingsAsync.error!, workshopSettingsAsync.stackTrace!);
  if (countriesAsync.hasError) return AsyncError(countriesAsync.error!, countriesAsync.stackTrace!);
  
  return const AsyncLoading();
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _wsFormKey = GlobalKey<FormState>();
  final _adminFormKey = GlobalKey<FormState>();
  final _userFormKey = GlobalKey<FormState>();
  final _newUserFormKey = GlobalKey<FormState>();
  
  late TextEditingController _adminFullNameController;
  late TextEditingController _adminPasswordController;
  late TextEditingController _userFullNameController;
  late TextEditingController _userPasswordController;
  late TextEditingController _newUserNameController;
  late TextEditingController _newUserUsernameController;
  late TextEditingController _newUserPasswordController;
  late TextEditingController _newUserRoleController;

  String? _initialAdminName;
  String? _initialStandardUserName;
  bool _isAdminFormDirty = false;
  bool _isStandardUserFormDirty = false;

  // --- FIX: Removed the hardcoded country map ---

  late TextEditingController _retentionPeriodController;
  late TextEditingController _wsNameController;
  late TextEditingController _wsManagerController;
  late TextEditingController _wsPhoneController;
  late TextEditingController _wsAddressController;

  // --- FIX: The selected country is now a full Country object ---
  Country? _selectedCountry;
  String? _currentCurrencySymbol;
  bool? _currentAutoPrint;
  int? _historyRetentionPeriod;
  String? _historyRetentionUnit;

  bool _isGeneralSettingsExpanded = false;
  bool _isWorkshopSettingsExpanded = false;
  bool _isDataManagementExpanded = false;
  bool _isUserManagementExpanded = false; 
  bool _showCreateUserForm = false;

  @override
  void initState() {
    super.initState();
    _retentionPeriodController = TextEditingController();
    _wsNameController = TextEditingController();
    _wsManagerController = TextEditingController();
    _wsPhoneController = TextEditingController();
    _wsAddressController = TextEditingController();
    
    _adminFullNameController = TextEditingController();
    _adminPasswordController = TextEditingController();
    _userFullNameController = TextEditingController();
    _userPasswordController = TextEditingController();
    _newUserNameController = TextEditingController();
    _newUserUsernameController = TextEditingController();
    _newUserPasswordController = TextEditingController();
    _newUserRoleController = TextEditingController(text: 'Supervisor');

    _adminFullNameController.addListener(_checkAdminFormDirty);
    _adminPasswordController.addListener(_checkAdminFormDirty);
    _userFullNameController.addListener(_checkStandardUserFormDirty);
    _userPasswordController.addListener(_checkStandardUserFormDirty);
  }

  @override
  void dispose() {
    _retentionPeriodController.dispose();
    _wsNameController.dispose();
    _wsManagerController.dispose();
    _wsPhoneController.dispose();
    _wsAddressController.dispose();

    _adminFullNameController.removeListener(_checkAdminFormDirty);
    _adminPasswordController.removeListener(_checkAdminFormDirty);
    _userFullNameController.removeListener(_checkStandardUserFormDirty);
    _userPasswordController.removeListener(_checkStandardUserFormDirty);

    _adminFullNameController.dispose();
    _adminPasswordController.dispose();
    _userFullNameController.dispose();
    _userPasswordController.dispose();
    _newUserNameController.dispose();
    _newUserUsernameController.dispose();
    _newUserPasswordController.dispose();
    _newUserRoleController.dispose();

    super.dispose();
  }

  void _checkAdminFormDirty() {
    final isDirty = (_initialAdminName != _adminFullNameController.text) ||
                    (_adminPasswordController.text.isNotEmpty);
    if (isDirty != _isAdminFormDirty) {
      setState(() => _isAdminFormDirty = isDirty);
    }
  }

  void _checkStandardUserFormDirty() {
    final isDirty = (_initialStandardUserName != _userFullNameController.text) ||
                      (_userPasswordController.text.isNotEmpty);
    if (isDirty != _isStandardUserFormDirty) {
      setState(() => _isStandardUserFormDirty = isDirty);
    }
  }

  void _onAutoPrintChanged(bool newValue, UserPreferences currentPrefs) {
    setState(() => _currentAutoPrint = newValue);
    _savePreferences(currentPrefs.copyWith(autoPrintReceipt: newValue));
  }

  // --- FIX: Updated method to work with the Country model ---
  void _onCountryChanged(Country? newCountry, UserPreferences currentPrefs) {
    if (newCountry == null || newCountry == _selectedCountry) return;
    
    setState(() {
      _selectedCountry = newCountry;
      _currentCurrencySymbol = newCountry.currencySymbol;
    });
    
    _savePreferences(currentPrefs.copyWith(defaultCurrency: newCountry.currencyCode));
  }

  void _onRetentionChanged(UserPreferences currentPrefs) {
    final newPeriod = int.tryParse(_retentionPeriodController.text) ?? 1;
    final newUnit = _historyRetentionUnit ?? 'Years';
    setState(() => _historyRetentionPeriod = newPeriod);
    _savePreferences(currentPrefs.copyWith(
      historyRetentionPeriod: newPeriod,
      historyRetentionUnit: newUnit,
    ));
  }

  void _saveWorkshopSettings() async {
    if (_wsFormKey.currentState?.validate() ?? false) {
      final settings = ShopSettingsCompanion(
        workshopName: drift.Value(_wsNameController.text),
        workshopManagerName: drift.Value(_wsManagerController.text),
        workshopPhoneNumber: drift.Value(_wsPhoneController.text),
        workshopAddress: drift.Value(_wsAddressController.text),
      );
      final success = await ref
          .read(workshopSettingsNotifierProvider.notifier)
          .updateShopSettings(settings);
      if (mounted) {
        _showSnackbar(
            success,
            'Workshop settings saved!',
            'Failed to save workshop settings.');
      }
    }
  }

  void _updateUser(GlobalKey<FormState> formKey, int userId,
      TextEditingController nameController, TextEditingController passController, String initialName) async {
    
    final currentName = nameController.text;
    final newPassword = passController.text;

    if (initialName == currentName && newPassword.isEmpty) {
      return;
    }

    if (formKey.currentState?.validate() ?? false) {
      final success = await ref.read(authNotifierProvider.notifier).updateUser(
            userId: userId,
            fullName: currentName,
            newPassword: newPassword.isNotEmpty ? newPassword : null,
          );
      if (mounted) {
        if (success) {
          passController.clear(); 
          FocusScope.of(context).unfocus(); 
        }
        _showSnackbar(success, 'User updated successfully!', 'Failed to update user.');
      }
    }
  }
  
  void _createUser() async {
    if (_newUserFormKey.currentState?.validate() ?? false) {
      final newUser = await ref.read(authNotifierProvider.notifier).signup(
        _newUserUsernameController.text,
        _newUserPasswordController.text,
        _newUserRoleController.text,
        fullName: _newUserNameController.text,
      );

      if (mounted) {
        if (newUser != null) {
          _showSnackbar(true, 'User created successfully!', '');
          setState(() => _showCreateUserForm = false);
        } else {
          final error = ref.read(authNotifierProvider).error ?? 'Unknown error';
          _showSnackbar(false, '', 'Failed to create user: $error');
        }
      }
    }
  }
  
  void _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text('Are you sure you want to delete the user "${user.username}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ref.read(authNotifierProvider.notifier).deleteUser(user.id);
      if (mounted) {
        _showSnackbar(success, 'User deleted successfully!', 'Failed to delete user.');
      }
    }
  }

  void _showSnackbar(bool success, String successMessage, String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? successMessage : errorMessage),
        backgroundColor:
            success ? Colors.green : Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _savePreferences(UserPreferences newPrefs) async {
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final success = await notifier.savePreferences(newPrefs);

    if (!mounted) return;

    _showSnackbar(success, 'Settings saved successfully.', 'Failed to save settings.');

    if (success) {
      ref.invalidate(userPreferencesStreamProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<(UserPreferences, ShopSetting, List<Country>)>>(settingsBundleProvider, (previous, next) {
      if (next.hasValue && !next.isLoading && (previous == null || !previous.hasValue || previous.isLoading)) {
        final (prefs, ws, countries) = next.value!;
        
        if (mounted) {
          setState(() {
            // --- FIX: Find the full Country object based on the saved currency code ---
            _selectedCountry = countries.firstWhere(
                (c) => c.currencyCode == prefs.defaultCurrency,
                orElse: () => countries.first,
              );
            _currentCurrencySymbol = _selectedCountry?.currencySymbol;
            _currentAutoPrint = prefs.autoPrintReceipt;
            _historyRetentionPeriod = prefs.historyRetentionPeriod;
            _historyRetentionUnit = prefs.historyRetentionUnit;
          });

          _retentionPeriodController.text = prefs.historyRetentionPeriod.toString();
          _wsNameController.text = ws.workshopName;
          _wsManagerController.text = ws.workshopManagerName;
          _wsPhoneController.text = ws.workshopPhoneNumber;
          _wsAddressController.text = ws.workshopAddress;
        }
      }
    });

    ref.listen<AsyncValue<List<User>>>(allUsersProvider, (previous, next) {
      if (next.hasValue && !next.isLoading) {
        final users = next.value!;
        final adminUser = users.firstWhereOrNull((u) => u.role == 'Admin');
        final standardUser = users.firstWhereOrNull((u) => u.role != 'Admin');

        if (adminUser != null) {
          _initialAdminName = adminUser.fullName ?? '';
          _adminFullNameController.text = _initialAdminName!;
        }
        if (standardUser != null) {
          _initialStandardUserName = standardUser.fullName ?? '';
          _userFullNameController.text = _initialStandardUserName!;
        } else {
          _initialStandardUserName = null;
        }
        
        _checkAdminFormDirty();
        _checkStandardUserFormDirty();
      }
    });

    final settingsBundleAsync = ref.watch(settingsBundleProvider);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: const CommonAppBar(title: 'Settings'),
      body: settingsBundleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading settings: $err')),
        data: (data) {
          final (prefs, _, countries) = data;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildExpandableSettingsCard(
                  context,
                  title: 'General Settings',
                  isExpanded: _isGeneralSettingsExpanded,
                  onExpansionChanged: (expanded) =>
                      setState(() => _isGeneralSettingsExpanded = expanded),
                  children: [
                    // --- FIX: Updated Dropdown to use the new countries list ---
                    ListTile(
                      title: const Text('Country'),
                      subtitle: DropdownButtonFormField<Country>(
                        value: _selectedCountry,
                        isExpanded: true,
                        items: countries.map((Country country) {
                          return DropdownMenuItem<Country>(
                            value: country,
                            child: Text('${country.flag} ${country.name}'),
                          );
                        }).toList(),
                        onChanged: (val) => _onCountryChanged(val, prefs),
                      ),
                    ),
                    ListTile(
                      title: const Text('Default Currency'),
                      subtitle: Text(
                        '${_selectedCountry?.currencyName ?? ''} (${_currentCurrencySymbol ?? ''})',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Auto-Print Receipt'),
                      subtitle: const Text(
                          'Open print dialog after completing a job.'),
                      value: _currentAutoPrint ?? false,
                      onChanged: (val) => _onAutoPrintChanged(val, prefs),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Form(
                  key: _wsFormKey,
                  child: _buildExpandableSettingsCard(
                    context,
                    title: 'Workshop Settings',
                    isExpanded: _isWorkshopSettingsExpanded,
                    onExpansionChanged: (expanded) =>
                        setState(() => _isWorkshopSettingsExpanded = expanded),
                    children: [
                      TextFormField(controller: _wsNameController, decoration: const InputDecoration(labelText: 'Workshop Name*'), validator: (v) => v!.isEmpty ? 'Required' : null, onEditingComplete: _saveWorkshopSettings),
                      const SizedBox(height: 16),
                      TextFormField(controller: _wsManagerController, decoration: const InputDecoration(labelText: 'Owner/Manager Name*'), validator: (v) => v!.isEmpty ? 'Required' : null, onEditingComplete: _saveWorkshopSettings),
                      const SizedBox(height: 16),
                      TextFormField(controller: _wsPhoneController, decoration: const InputDecoration(labelText: 'Phone Number*'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Required' : null, onEditingComplete: _saveWorkshopSettings),
                      const SizedBox(height: 16),
                      TextFormField(controller: _wsAddressController, decoration: const InputDecoration(labelText: 'Address*'), validator: (v) => v!.isEmpty ? 'Required' : null, onEditingComplete: _saveWorkshopSettings),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildExpandableSettingsCard(
                  context,
                  title: 'Data Management',
                  isExpanded: _isDataManagementExpanded,
                  onExpansionChanged: (expanded) =>
                      setState(() => _isDataManagementExpanded = expanded),
                  children: [
                    ListTile(
                      title: const Text('Completed Job History'),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            const Text('Keep records for: '),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _retentionPeriodController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder()),
                                onEditingComplete: () =>
                                    _onRetentionChanged(prefs),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: _historyRetentionUnit,
                                items: ['Days', 'Months', 'Years']
                                    .map((unit) => DropdownMenuItem(
                                        value: unit, child: Text(unit)))
                                    .toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(
                                        () => _historyRetentionUnit = newValue);
                                    _onRetentionChanged(prefs);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildExpandableSettingsCard(
                  context,
                  title: 'User Management',
                  isExpanded: _isUserManagementExpanded,
                  onExpansionChanged: (expanded) =>
                      setState(() => _isUserManagementExpanded = expanded),
                  children: [
                    if (authState.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    _buildUserManagementSection(),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserManagementSection() {
    final allUsersAsync = ref.watch(allUsersProvider);

    return allUsersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (users) {
        final adminUser = users.firstWhereOrNull((u) => u.role == 'Admin');
        final standardUser = users.firstWhereOrNull((u) => u.role != 'Admin');
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (adminUser != null)
              _buildUserEditForm(
                formKey: _adminFormKey,
                user: adminUser,
                nameController: _adminFullNameController,
                passwordController: _adminPasswordController,
                isDeletable: false,
                isDirty: _isAdminFormDirty,
                onSave: () => _updateUser(_adminFormKey, adminUser.id, _adminFullNameController, _adminPasswordController, _initialAdminName!),
              ),
            const Divider(height: 32),
            if (standardUser != null)
              _buildUserEditForm(
                formKey: _userFormKey,
                user: standardUser,
                nameController: _userFullNameController,
                passwordController: _userPasswordController,
                isDeletable: true,
                isDirty: _isStandardUserFormDirty,
                onSave: () => _updateUser(_userFormKey, standardUser.id, _userFullNameController, _userPasswordController, _initialStandardUserName!),
                onDelete: () => _deleteUser(standardUser),
              ),
            if (standardUser == null)
              _buildCreateUserSection(),
          ],
        );
      },
    );
  }

  Widget _buildUserEditForm({
    required GlobalKey<FormState> formKey,
    required User user,
    required TextEditingController nameController,
    required TextEditingController passwordController,
    required bool isDeletable,
    required bool isDirty,
    required VoidCallback onSave,
    VoidCallback? onDelete,
  }) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.role, style: Theme.of(context).textTheme.titleLarge),
          Text(user.username, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Full Name*'),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: passwordController,
            decoration: const InputDecoration(
                labelText: 'New Password (optional)',
                helperText: 'Leave blank to keep current password'),
            obscureText: true,
            validator: (v) => v!.isNotEmpty && v.length < 6
                ? 'Min 6 characters'
                : null,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isDeletable)
                TextButton(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error),
                  child: const Text('Delete User'),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: isDirty ? onSave : null,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCreateUserSection() {
    if (!_showCreateUserForm) {
      return Center(
        child: ElevatedButton(
          onPressed: () => setState(() => _showCreateUserForm = true),
          child: const Text('Create Standard User'),
        ),
      );
    }
    return Form(
      key: _newUserFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create New User', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(
            controller: _newUserNameController,
            decoration: const InputDecoration(labelText: 'Full Name*'),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _newUserRoleController,
            decoration: const InputDecoration(labelText: 'Role Name*'),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _newUserUsernameController,
            decoration: const InputDecoration(labelText: 'Username*'),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _newUserPasswordController,
            decoration: const InputDecoration(labelText: 'Password*'),
            obscureText: true,
            validator: (v) =>
                v!.length < 6 ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _showCreateUserForm = false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _createUser,
                child: const Text('Create'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildExpandableSettingsCard(BuildContext context,
      {required String title,
      required bool isExpanded,
      required ValueChanged<bool> onExpansionChanged,
      required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: onExpansionChanged,
        title: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        childrenPadding: const EdgeInsets.all(16).copyWith(top: 0),
        children: children,
      ),
    );
  }
}

