// lib/features/service/presentation/service_providers.dart
import 'package:autoshop_manager/data/repositories/service_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/data/database/app_database.dart';

final serviceSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final serviceListProvider = FutureProvider.autoDispose<List<Service>>((ref) {
  final repository = ref.watch(serviceRepositoryProvider);
  final query = ref.watch(serviceSearchQueryProvider);
  return repository.getAllServices(query: query);
});

final serviceNotifierProvider =
    StateNotifierProvider.autoDispose<ServiceNotifier, AsyncValue<void>>((ref) {
  return ServiceNotifier(ref);
});

class ServiceNotifier extends StateNotifier<AsyncValue<void>> {
  ServiceNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<bool> addService(ServicesCompanion entry) async {
    state = const AsyncLoading();
    try {
      await _ref.read(serviceRepositoryProvider).addService(entry);
      _ref.invalidate(serviceListProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> updateService(Service service) async {
    state = const AsyncLoading();
    try {
      final success = await _ref.read(serviceRepositoryProvider).updateService(service);
      if (success) {
        _ref.invalidate(serviceListProvider);
      }
      state = const AsyncData(null);
      return success;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> deleteService(int id) async {
    state = const AsyncLoading();
    try {
      final success = await _ref.read(serviceRepositoryProvider).deleteService(id);
      if (success) {
        _ref.invalidate(serviceListProvider);
      }
      state = const AsyncData(null);
      return success;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> resetDefaultServices() async {
    state = const AsyncLoading();
    try {
      await _ref.read(serviceRepositoryProvider).seedServicesFromJson(forceReset: true);
      _ref.invalidate(serviceListProvider);

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
