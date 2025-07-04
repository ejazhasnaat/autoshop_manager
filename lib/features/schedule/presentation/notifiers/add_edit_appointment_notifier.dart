// lib/features/schedule/presentation/notifiers/add_edit_appointment_notifier.dart
import 'dart:async';

import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/data/repositories/appointment_repository.dart';
import 'package:autoshop_manager/data/repositories/customer_repository.dart';
import 'package:autoshop_manager/data/repositories/service_repository.dart';
import 'package:autoshop_manager/data/repositories/vehicle_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_edit_appointment_notifier.freezed.dart';

@freezed
class AddEditAppointmentState with _$AddEditAppointmentState {
  const factory AddEditAppointmentState({
    required bool isLoading,
    required bool isSaving,
    required List<CustomerWithVehicles> customers,
    required List<Vehicle> vehiclesForSelectedCustomer,
    // --- ADDED: State for managing services ---
    required List<Service> allServices,
    required List<Service> selectedServices,
    Customer? selectedCustomer,
    Vehicle? selectedVehicle,
    DateTime? appointmentDate,
    TimeOfDay? appointmentTime,
    String? technicianName,
    String? notes,
    String? errorMessage,
    bool? saveSuccess,
  }) = _AddEditAppointmentState;

  factory AddEditAppointmentState.initial() => const AddEditAppointmentState(
        isLoading: true,
        isSaving: false,
        customers: [],
        vehiclesForSelectedCustomer: [],
        allServices: [],
        selectedServices: [],
      );
}

class AddEditAppointmentNotifier extends StateNotifier<AddEditAppointmentState> {
  final CustomerRepository _customerRepo;
  final VehicleRepository _vehicleRepo;
  final AppointmentRepository _appointmentRepo;
  // --- ADDED: ServiceRepository dependency ---
  final ServiceRepository _serviceRepo;

  AddEditAppointmentNotifier(
    this._customerRepo,
    this._vehicleRepo,
    this._appointmentRepo,
    this._serviceRepo, // --- ADDED
  ) : super(AddEditAppointmentState.initial()) {
    _init();
  }

  Future<void> _init() async {
    // Fetch customers and services concurrently
    final results = await Future.wait([
      _customerRepo.getAllCustomersWithVehicles(),
      _serviceRepo.getAllServices(),
    ]);

    state = state.copyWith(
      customers: results[0] as List<CustomerWithVehicles>,
      allServices: results[1] as List<Service>,
      isLoading: false,
    );
  }

  // --- ADDED: Method to update selected services ---
  void onServicesSelected(List<Service> services) {
    state = state.copyWith(selectedServices: services);
  }

  void customerSelected(Customer? customer) {
    if (customer == null) {
      state = state.copyWith(
          selectedCustomer: null,
          selectedVehicle: null,
          vehiclesForSelectedCustomer: []);
      return;
    }

    final customerWithVehicles =
        state.customers.firstWhere((cwv) => cwv.customer.id == customer.id);

    state = state.copyWith(
      selectedCustomer: customer,
      vehiclesForSelectedCustomer: customerWithVehicles.vehicles,
      selectedVehicle: null,
    );
  }

  void vehicleSelected(Vehicle? vehicle) {
    state = state.copyWith(selectedVehicle: vehicle);
  }

  void onDateSelected(DateTime date) {
    state = state.copyWith(appointmentDate: date);
  }

  void onTimeSelected(TimeOfDay time) {
    state = state.copyWith(appointmentTime: time);
  }

  Future<void> createAppointment({
    String? technician,
    String? notes,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null, saveSuccess: null);

    // --- UPDATED: Validation logic ---
    if (state.selectedCustomer == null ||
        state.selectedVehicle == null ||
        state.appointmentDate == null ||
        state.appointmentTime == null ||
        state.selectedServices.isEmpty) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Please fill all required fields: Customer, Vehicle, Services, Date, and Time.',
      );
      return;
    }

    final combinedDateTime = DateTime(
      state.appointmentDate!.year,
      state.appointmentDate!.month,
      state.appointmentDate!.day,
      state.appointmentTime!.hour,
      state.appointmentTime!.minute,
    );

    // --- UPDATED: Format selected services into a string ---
    final servicesDescription = state.selectedServices.map((s) => s.name).join(', ');

    final newAppointment = AppointmentsCompanion(
      customerId: Value(state.selectedCustomer!.id),
      vehicleId: Value(state.selectedVehicle!.id),
      appointmentDate: Value(combinedDateTime),
      servicesDescription: Value(servicesDescription),
      technicianName: Value(technician),
      notes: Value(notes),
      status: const Value('pending'),
    );

    try {
      await _appointmentRepo.addAppointment(newAppointment);
      state = state.copyWith(isSaving: false, saveSuccess: true);
    } catch (e) {
      state = state.copyWith(
          isSaving: false,
          saveSuccess: false,
          errorMessage: 'Failed to save appointment: $e');
    }
  }
}
