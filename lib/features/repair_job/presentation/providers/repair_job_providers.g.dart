// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repair_job_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$repairJobDaoHash() => r'a8ff36c6f7c5260fd501173c208900680ed5c83a';

/// See also [repairJobDao].
@ProviderFor(repairJobDao)
final repairJobDaoProvider = AutoDisposeProvider<RepairJobDao>.internal(
  repairJobDao,
  name: r'repairJobDaoProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$repairJobDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RepairJobDaoRef = AutoDisposeProviderRef<RepairJobDao>;
String _$activeRepairJobsHash() => r'bd5cc276830d219f2578ee67dae60028e76066cc';

/// See also [activeRepairJobs].
@ProviderFor(activeRepairJobs)
final activeRepairJobsProvider =
    AutoDisposeStreamProvider<List<RepairJobWithCustomer>>.internal(
      activeRepairJobs,
      name: r'activeRepairJobsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeRepairJobsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveRepairJobsRef =
    AutoDisposeStreamProviderRef<List<RepairJobWithCustomer>>;
String _$activeRepairJobCountHash() =>
    r'782fe8ea0c826515ec40dbe0ce1405f1c5c65514';

/// See also [activeRepairJobCount].
@ProviderFor(activeRepairJobCount)
final activeRepairJobCountProvider = AutoDisposeStreamProvider<int>.internal(
  activeRepairJobCount,
  name: r'activeRepairJobCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeRepairJobCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveRepairJobCountRef = AutoDisposeStreamProviderRef<int>;
String _$repairJobDetailsHash() => r'0000c3362ba592d4e5aa284b9fa2f11b6fb45d2b';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [repairJobDetails].
@ProviderFor(repairJobDetails)
const repairJobDetailsProvider = RepairJobDetailsFamily();

/// See also [repairJobDetails].
class RepairJobDetailsFamily extends Family<AsyncValue<RepairJobWithDetails>> {
  /// See also [repairJobDetails].
  const RepairJobDetailsFamily();

  /// See also [repairJobDetails].
  RepairJobDetailsProvider call(int jobId) {
    return RepairJobDetailsProvider(jobId);
  }

  @override
  RepairJobDetailsProvider getProviderOverride(
    covariant RepairJobDetailsProvider provider,
  ) {
    return call(provider.jobId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'repairJobDetailsProvider';
}

/// See also [repairJobDetails].
class RepairJobDetailsProvider
    extends AutoDisposeStreamProvider<RepairJobWithDetails> {
  /// See also [repairJobDetails].
  RepairJobDetailsProvider(int jobId)
    : this._internal(
        (ref) => repairJobDetails(ref as RepairJobDetailsRef, jobId),
        from: repairJobDetailsProvider,
        name: r'repairJobDetailsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$repairJobDetailsHash,
        dependencies: RepairJobDetailsFamily._dependencies,
        allTransitiveDependencies:
            RepairJobDetailsFamily._allTransitiveDependencies,
        jobId: jobId,
      );

  RepairJobDetailsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.jobId,
  }) : super.internal();

  final int jobId;

  @override
  Override overrideWith(
    Stream<RepairJobWithDetails> Function(RepairJobDetailsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RepairJobDetailsProvider._internal(
        (ref) => create(ref as RepairJobDetailsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        jobId: jobId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<RepairJobWithDetails> createElement() {
    return _RepairJobDetailsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RepairJobDetailsProvider && other.jobId == jobId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, jobId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RepairJobDetailsRef
    on AutoDisposeStreamProviderRef<RepairJobWithDetails> {
  /// The parameter `jobId` of this provider.
  int get jobId;
}

class _RepairJobDetailsProviderElement
    extends AutoDisposeStreamProviderElement<RepairJobWithDetails>
    with RepairJobDetailsRef {
  _RepairJobDetailsProviderElement(super.provider);

  @override
  int get jobId => (origin as RepairJobDetailsProvider).jobId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
