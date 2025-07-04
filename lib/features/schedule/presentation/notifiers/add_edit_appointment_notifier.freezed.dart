// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'add_edit_appointment_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AddEditAppointmentState {
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isSaving => throw _privateConstructorUsedError;
  List<CustomerWithVehicles> get customers =>
      throw _privateConstructorUsedError;
  List<Vehicle> get vehiclesForSelectedCustomer =>
      throw _privateConstructorUsedError; // --- ADDED: State for managing services ---
  List<Service> get allServices => throw _privateConstructorUsedError;
  List<Service> get selectedServices => throw _privateConstructorUsedError;
  Customer? get selectedCustomer => throw _privateConstructorUsedError;
  Vehicle? get selectedVehicle => throw _privateConstructorUsedError;
  DateTime? get appointmentDate => throw _privateConstructorUsedError;
  TimeOfDay? get appointmentTime => throw _privateConstructorUsedError;
  String? get technicianName => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  bool? get saveSuccess => throw _privateConstructorUsedError;

  /// Create a copy of AddEditAppointmentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AddEditAppointmentStateCopyWith<AddEditAppointmentState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AddEditAppointmentStateCopyWith<$Res> {
  factory $AddEditAppointmentStateCopyWith(
    AddEditAppointmentState value,
    $Res Function(AddEditAppointmentState) then,
  ) = _$AddEditAppointmentStateCopyWithImpl<$Res, AddEditAppointmentState>;
  @useResult
  $Res call({
    bool isLoading,
    bool isSaving,
    List<CustomerWithVehicles> customers,
    List<Vehicle> vehiclesForSelectedCustomer,
    List<Service> allServices,
    List<Service> selectedServices,
    Customer? selectedCustomer,
    Vehicle? selectedVehicle,
    DateTime? appointmentDate,
    TimeOfDay? appointmentTime,
    String? technicianName,
    String? notes,
    String? errorMessage,
    bool? saveSuccess,
  });
}

/// @nodoc
class _$AddEditAppointmentStateCopyWithImpl<
  $Res,
  $Val extends AddEditAppointmentState
>
    implements $AddEditAppointmentStateCopyWith<$Res> {
  _$AddEditAppointmentStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AddEditAppointmentState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isSaving = null,
    Object? customers = null,
    Object? vehiclesForSelectedCustomer = null,
    Object? allServices = null,
    Object? selectedServices = null,
    Object? selectedCustomer = freezed,
    Object? selectedVehicle = freezed,
    Object? appointmentDate = freezed,
    Object? appointmentTime = freezed,
    Object? technicianName = freezed,
    Object? notes = freezed,
    Object? errorMessage = freezed,
    Object? saveSuccess = freezed,
  }) {
    return _then(
      _value.copyWith(
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            isSaving: null == isSaving
                ? _value.isSaving
                : isSaving // ignore: cast_nullable_to_non_nullable
                      as bool,
            customers: null == customers
                ? _value.customers
                : customers // ignore: cast_nullable_to_non_nullable
                      as List<CustomerWithVehicles>,
            vehiclesForSelectedCustomer: null == vehiclesForSelectedCustomer
                ? _value.vehiclesForSelectedCustomer
                : vehiclesForSelectedCustomer // ignore: cast_nullable_to_non_nullable
                      as List<Vehicle>,
            allServices: null == allServices
                ? _value.allServices
                : allServices // ignore: cast_nullable_to_non_nullable
                      as List<Service>,
            selectedServices: null == selectedServices
                ? _value.selectedServices
                : selectedServices // ignore: cast_nullable_to_non_nullable
                      as List<Service>,
            selectedCustomer: freezed == selectedCustomer
                ? _value.selectedCustomer
                : selectedCustomer // ignore: cast_nullable_to_non_nullable
                      as Customer?,
            selectedVehicle: freezed == selectedVehicle
                ? _value.selectedVehicle
                : selectedVehicle // ignore: cast_nullable_to_non_nullable
                      as Vehicle?,
            appointmentDate: freezed == appointmentDate
                ? _value.appointmentDate
                : appointmentDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            appointmentTime: freezed == appointmentTime
                ? _value.appointmentTime
                : appointmentTime // ignore: cast_nullable_to_non_nullable
                      as TimeOfDay?,
            technicianName: freezed == technicianName
                ? _value.technicianName
                : technicianName // ignore: cast_nullable_to_non_nullable
                      as String?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
            saveSuccess: freezed == saveSuccess
                ? _value.saveSuccess
                : saveSuccess // ignore: cast_nullable_to_non_nullable
                      as bool?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AddEditAppointmentStateImplCopyWith<$Res>
    implements $AddEditAppointmentStateCopyWith<$Res> {
  factory _$$AddEditAppointmentStateImplCopyWith(
    _$AddEditAppointmentStateImpl value,
    $Res Function(_$AddEditAppointmentStateImpl) then,
  ) = __$$AddEditAppointmentStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isLoading,
    bool isSaving,
    List<CustomerWithVehicles> customers,
    List<Vehicle> vehiclesForSelectedCustomer,
    List<Service> allServices,
    List<Service> selectedServices,
    Customer? selectedCustomer,
    Vehicle? selectedVehicle,
    DateTime? appointmentDate,
    TimeOfDay? appointmentTime,
    String? technicianName,
    String? notes,
    String? errorMessage,
    bool? saveSuccess,
  });
}

/// @nodoc
class __$$AddEditAppointmentStateImplCopyWithImpl<$Res>
    extends
        _$AddEditAppointmentStateCopyWithImpl<
          $Res,
          _$AddEditAppointmentStateImpl
        >
    implements _$$AddEditAppointmentStateImplCopyWith<$Res> {
  __$$AddEditAppointmentStateImplCopyWithImpl(
    _$AddEditAppointmentStateImpl _value,
    $Res Function(_$AddEditAppointmentStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AddEditAppointmentState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isSaving = null,
    Object? customers = null,
    Object? vehiclesForSelectedCustomer = null,
    Object? allServices = null,
    Object? selectedServices = null,
    Object? selectedCustomer = freezed,
    Object? selectedVehicle = freezed,
    Object? appointmentDate = freezed,
    Object? appointmentTime = freezed,
    Object? technicianName = freezed,
    Object? notes = freezed,
    Object? errorMessage = freezed,
    Object? saveSuccess = freezed,
  }) {
    return _then(
      _$AddEditAppointmentStateImpl(
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        isSaving: null == isSaving
            ? _value.isSaving
            : isSaving // ignore: cast_nullable_to_non_nullable
                  as bool,
        customers: null == customers
            ? _value._customers
            : customers // ignore: cast_nullable_to_non_nullable
                  as List<CustomerWithVehicles>,
        vehiclesForSelectedCustomer: null == vehiclesForSelectedCustomer
            ? _value._vehiclesForSelectedCustomer
            : vehiclesForSelectedCustomer // ignore: cast_nullable_to_non_nullable
                  as List<Vehicle>,
        allServices: null == allServices
            ? _value._allServices
            : allServices // ignore: cast_nullable_to_non_nullable
                  as List<Service>,
        selectedServices: null == selectedServices
            ? _value._selectedServices
            : selectedServices // ignore: cast_nullable_to_non_nullable
                  as List<Service>,
        selectedCustomer: freezed == selectedCustomer
            ? _value.selectedCustomer
            : selectedCustomer // ignore: cast_nullable_to_non_nullable
                  as Customer?,
        selectedVehicle: freezed == selectedVehicle
            ? _value.selectedVehicle
            : selectedVehicle // ignore: cast_nullable_to_non_nullable
                  as Vehicle?,
        appointmentDate: freezed == appointmentDate
            ? _value.appointmentDate
            : appointmentDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        appointmentTime: freezed == appointmentTime
            ? _value.appointmentTime
            : appointmentTime // ignore: cast_nullable_to_non_nullable
                  as TimeOfDay?,
        technicianName: freezed == technicianName
            ? _value.technicianName
            : technicianName // ignore: cast_nullable_to_non_nullable
                  as String?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        saveSuccess: freezed == saveSuccess
            ? _value.saveSuccess
            : saveSuccess // ignore: cast_nullable_to_non_nullable
                  as bool?,
      ),
    );
  }
}

/// @nodoc

class _$AddEditAppointmentStateImpl implements _AddEditAppointmentState {
  const _$AddEditAppointmentStateImpl({
    required this.isLoading,
    required this.isSaving,
    required final List<CustomerWithVehicles> customers,
    required final List<Vehicle> vehiclesForSelectedCustomer,
    required final List<Service> allServices,
    required final List<Service> selectedServices,
    this.selectedCustomer,
    this.selectedVehicle,
    this.appointmentDate,
    this.appointmentTime,
    this.technicianName,
    this.notes,
    this.errorMessage,
    this.saveSuccess,
  }) : _customers = customers,
       _vehiclesForSelectedCustomer = vehiclesForSelectedCustomer,
       _allServices = allServices,
       _selectedServices = selectedServices;

  @override
  final bool isLoading;
  @override
  final bool isSaving;
  final List<CustomerWithVehicles> _customers;
  @override
  List<CustomerWithVehicles> get customers {
    if (_customers is EqualUnmodifiableListView) return _customers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_customers);
  }

  final List<Vehicle> _vehiclesForSelectedCustomer;
  @override
  List<Vehicle> get vehiclesForSelectedCustomer {
    if (_vehiclesForSelectedCustomer is EqualUnmodifiableListView)
      return _vehiclesForSelectedCustomer;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_vehiclesForSelectedCustomer);
  }

  // --- ADDED: State for managing services ---
  final List<Service> _allServices;
  // --- ADDED: State for managing services ---
  @override
  List<Service> get allServices {
    if (_allServices is EqualUnmodifiableListView) return _allServices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allServices);
  }

  final List<Service> _selectedServices;
  @override
  List<Service> get selectedServices {
    if (_selectedServices is EqualUnmodifiableListView)
      return _selectedServices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_selectedServices);
  }

  @override
  final Customer? selectedCustomer;
  @override
  final Vehicle? selectedVehicle;
  @override
  final DateTime? appointmentDate;
  @override
  final TimeOfDay? appointmentTime;
  @override
  final String? technicianName;
  @override
  final String? notes;
  @override
  final String? errorMessage;
  @override
  final bool? saveSuccess;

  @override
  String toString() {
    return 'AddEditAppointmentState(isLoading: $isLoading, isSaving: $isSaving, customers: $customers, vehiclesForSelectedCustomer: $vehiclesForSelectedCustomer, allServices: $allServices, selectedServices: $selectedServices, selectedCustomer: $selectedCustomer, selectedVehicle: $selectedVehicle, appointmentDate: $appointmentDate, appointmentTime: $appointmentTime, technicianName: $technicianName, notes: $notes, errorMessage: $errorMessage, saveSuccess: $saveSuccess)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddEditAppointmentStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isSaving, isSaving) ||
                other.isSaving == isSaving) &&
            const DeepCollectionEquality().equals(
              other._customers,
              _customers,
            ) &&
            const DeepCollectionEquality().equals(
              other._vehiclesForSelectedCustomer,
              _vehiclesForSelectedCustomer,
            ) &&
            const DeepCollectionEquality().equals(
              other._allServices,
              _allServices,
            ) &&
            const DeepCollectionEquality().equals(
              other._selectedServices,
              _selectedServices,
            ) &&
            (identical(other.selectedCustomer, selectedCustomer) ||
                other.selectedCustomer == selectedCustomer) &&
            (identical(other.selectedVehicle, selectedVehicle) ||
                other.selectedVehicle == selectedVehicle) &&
            (identical(other.appointmentDate, appointmentDate) ||
                other.appointmentDate == appointmentDate) &&
            (identical(other.appointmentTime, appointmentTime) ||
                other.appointmentTime == appointmentTime) &&
            (identical(other.technicianName, technicianName) ||
                other.technicianName == technicianName) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.saveSuccess, saveSuccess) ||
                other.saveSuccess == saveSuccess));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    isLoading,
    isSaving,
    const DeepCollectionEquality().hash(_customers),
    const DeepCollectionEquality().hash(_vehiclesForSelectedCustomer),
    const DeepCollectionEquality().hash(_allServices),
    const DeepCollectionEquality().hash(_selectedServices),
    selectedCustomer,
    selectedVehicle,
    appointmentDate,
    appointmentTime,
    technicianName,
    notes,
    errorMessage,
    saveSuccess,
  );

  /// Create a copy of AddEditAppointmentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AddEditAppointmentStateImplCopyWith<_$AddEditAppointmentStateImpl>
  get copyWith =>
      __$$AddEditAppointmentStateImplCopyWithImpl<
        _$AddEditAppointmentStateImpl
      >(this, _$identity);
}

abstract class _AddEditAppointmentState implements AddEditAppointmentState {
  const factory _AddEditAppointmentState({
    required final bool isLoading,
    required final bool isSaving,
    required final List<CustomerWithVehicles> customers,
    required final List<Vehicle> vehiclesForSelectedCustomer,
    required final List<Service> allServices,
    required final List<Service> selectedServices,
    final Customer? selectedCustomer,
    final Vehicle? selectedVehicle,
    final DateTime? appointmentDate,
    final TimeOfDay? appointmentTime,
    final String? technicianName,
    final String? notes,
    final String? errorMessage,
    final bool? saveSuccess,
  }) = _$AddEditAppointmentStateImpl;

  @override
  bool get isLoading;
  @override
  bool get isSaving;
  @override
  List<CustomerWithVehicles> get customers;
  @override
  List<Vehicle> get vehiclesForSelectedCustomer; // --- ADDED: State for managing services ---
  @override
  List<Service> get allServices;
  @override
  List<Service> get selectedServices;
  @override
  Customer? get selectedCustomer;
  @override
  Vehicle? get selectedVehicle;
  @override
  DateTime? get appointmentDate;
  @override
  TimeOfDay? get appointmentTime;
  @override
  String? get technicianName;
  @override
  String? get notes;
  @override
  String? get errorMessage;
  @override
  bool? get saveSuccess;

  /// Create a copy of AddEditAppointmentState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AddEditAppointmentStateImplCopyWith<_$AddEditAppointmentStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}
