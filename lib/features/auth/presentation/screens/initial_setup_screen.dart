// lib/features/auth/presentation/screens/initial_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/features/auth/presentation/auth_providers.dart';
import 'package:go_router/go_router.dart';

class InitialSetupScreen extends ConsumerStatefulWidget {
  const InitialSetupScreen({super.key});
  @override
  ConsumerState<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends ConsumerState<InitialSetupScreen> {
  int _currentStep = 0;
  final _workshopFormKey = GlobalKey<FormState>();
  final _adminFormKey = GlobalKey<FormState>();
  final _userFormKey = GlobalKey<FormState>();

  bool _isProcessing = false;

  final _workshopName = TextEditingController();
  final _managerName = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  final _adminUsername = TextEditingController(text: 'admin');
  final _adminFullName = TextEditingController();
  final _adminPassword = TextEditingController();

  bool _createStandardUser = true;
  final _userUsername = TextEditingController(text: 'user');
  final _userFullName = TextEditingController();
  final _userPassword = TextEditingController();

  final _userRoleName = TextEditingController(text: 'Supervisor');

  @override
  void dispose() {
    _workshopName.dispose();
    _managerName.dispose();
    _phone.dispose();
    _address.dispose();
    _adminUsername.dispose();
    _adminFullName.dispose();
    _adminPassword.dispose();
    _userUsername.dispose();
    _userFullName.dispose();
    _userPassword.dispose();
    _userRoleName.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final workshopValid = _workshopFormKey.currentState!.validate();
      final adminValid = _adminFormKey.currentState!.validate();
      final userValid =
          !_createStandardUser ||
          (_userFormKey.currentState?.validate() ?? false);

      if (workshopValid && adminValid && userValid) {
        final success = await ref
            .read(authNotifierProvider.notifier)
            .performInitialSetup(
              workshopName: _workshopName.text,
              managerName: _managerName.text,
              phone: _phone.text,
              address: _address.text,
              adminUsername: _adminUsername.text,
              adminPassword: _adminPassword.text,
              adminFullName: _adminFullName.text,
              userUsername: _createStandardUser ? _userUsername.text : null,
              userPassword: _createStandardUser ? _userPassword.text : null,
              userFullName: _createStandardUser ? _userFullName.text : null,
              userRole: _createStandardUser ? _userRoleName.text : null,
            );

        if (mounted && !success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Setup failed: ${ref.read(authNotifierProvider).error ?? 'Unknown error'}',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } else {
        if (!workshopValid)
          setState(() => _currentStep = 0);
        else if (!adminValid)
          setState(() => _currentStep = 1);
        else if (!userValid)
          setState(() => _currentStep = 2);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        _isProcessing || ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AutoShop Manager Setup'),
        centerTitle: true,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepTapped: isLoading
            ? null
            : (step) => setState(() => _currentStep = step),
        onStepContinue: isLoading
            ? null
            : () {
                if (_currentStep < 3) {
                  setState(() => _currentStep += 1);
                } else {
                  _completeSetup();
                }
              },
        onStepCancel: isLoading
            ? null
            : (_currentStep == 0
                  ? null
                  : () => setState(() => _currentStep -= 1)),
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        child: Text(
                          _currentStep == 3 ? 'COMPLETE SETUP' : 'NEXT',
                        ),
                      ),
                      if (_currentStep != 0)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('BACK'),
                        ),
                    ],
                  ),
          );
        },
        steps: [
          _buildWorkshopStep(),
          _buildAdminStep(),
          _buildUserStep(),
          _buildConfirmStep(),
        ],
      ),
    );
  }

  Step _buildWorkshopStep() {
    return Step(
      title: const Text('Workshop Details'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Form(
        key: _workshopFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _workshopName,
              decoration: const InputDecoration(labelText: 'Workshop Name*'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _managerName,
              decoration: const InputDecoration(
                labelText: 'Owner/Manager Name*',
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone Number*'),
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Address*'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Step _buildAdminStep() {
    return Step(
      title: const Text('Admin Account'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Form(
        key: _adminFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The admin account has full access to all features, including managing users and settings.',
            ),
            const SizedBox(height: 16),
            // --- FIX 1: Reordered fields and updated labels ---
            TextFormField(
              controller: _adminFullName,
              decoration: const InputDecoration(labelText: 'Full Name*'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _adminUsername,
              decoration: const InputDecoration(labelText: 'Username*'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _adminPassword,
              decoration: const InputDecoration(labelText: 'Password*'),
              obscureText: true,
              validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
            ),
          ],
        ),
      ),
    );
  }

  Step _buildUserStep() {
    return Step(
      title: const Text('Standard User Account'),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This is a standard account for daily operations with limited access. You can skip this and add it later.',
          ),
          CheckboxListTile(
            title: const Text('Create a standard user account now'),
            value: _createStandardUser,
            onChanged: (val) =>
                setState(() => _createStandardUser = val ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          if (_createStandardUser)
            Form(
              key: _userFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _userFullName,
                    decoration: const InputDecoration(labelText: 'Full Name*'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _userRoleName,
                    decoration: const InputDecoration(
                      labelText: 'Role Name*',
                      helperText: 'e.g., Operator, Supervisor',
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _userUsername,
                    decoration: const InputDecoration(labelText: 'Username*'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _userPassword,
                    decoration: const InputDecoration(labelText: 'Password*'),
                    obscureText: true,
                    validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Step _buildConfirmStep() {
    return Step(
      title: const Text('Finish'),
      isActive: _currentStep >= 3,
      // --- FIX 5: Updated text and alignment ---
      content: const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Click "Complete Setup" to save all settings and create the user accounts.',
        ),
      ),
    );
  }
}
