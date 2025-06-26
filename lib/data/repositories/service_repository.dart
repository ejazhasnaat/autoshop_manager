// lib/data/repositories/service_repository.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:autoshop_manager/core/providers.dart';
import 'package:autoshop_manager/data/database/app_database.dart';

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepository(ref.read(appDatabaseProvider));
});

class ServiceRepository {
  final AppDatabase _db;
  ServiceRepository(this._db);

  String _generateSlug(String title) {
    return title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
  }

  Future<void> seedServicesFromJson({bool forceReset = false}) async {
    try {
      if (!forceReset) {
        final countResult = await (_db.selectOnly(_db.services)..addColumns([_db.services.id.count()])).getSingleOrNull();
        final count = countResult?.read(_db.services.id.count()) ?? 0;
        if (count > 0) return;
      }

      final String jsonString = await rootBundle.loadString('assets/repair_services.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final List<dynamic> serviceCategories = jsonMap['services'];
      final List<String> defaultServiceCodes = [];
      final List<ServicesCompanion> servicesToInsert = [];

      for (var categoryData in serviceCategories) {
        final String categoryName = categoryData['category'];
        final List<dynamic> items = categoryData['items'];
        for (var itemData in items) {
          final String serviceName = itemData['name'];
          final String serviceCode = _generateSlug(serviceName);
          defaultServiceCodes.add(serviceCode);
          servicesToInsert.add(ServicesCompanion(
            name: Value(serviceName),
            description: Value(itemData['description']),
            price: Value((itemData['price'] as num).toDouble()),
            category: Value(categoryName),
            serviceCode: Value(serviceCode),
            isActive: const Value(true),
          ));
        }
      }

      await _db.batch((batch) {
        if (forceReset) {
          batch.deleteWhere(_db.services, (row) => row.serviceCode.isIn(defaultServiceCodes));
        }
        batch.insertAll(_db.services, servicesToInsert, mode: InsertMode.insertOrReplace);
      });
    } catch (e) {
      print('Error seeding services from JSON: $e');
      rethrow;
    }
  }

  /// Retrieves all services, with optional filtering by query
  Future<List<Service>> getAllServices({String? query}) async {
    final select = _db.select(_db.services);

    if (query != null && query.isNotEmpty) {
      final lowerQuery = '%${query.toLowerCase()}%';
      select.where((s) => s.name.lower().like(lowerQuery) | s.category.lower().like(lowerQuery));
    }

    select.orderBy([
      (s) => OrderingTerm(expression: s.category, mode: OrderingMode.asc),
      (s) => OrderingTerm(expression: s.name, mode: OrderingMode.asc),
    ]);
    
    return select.get();
  }

  Future<Service?> getServiceById(int id) async {
    return (_db.select(_db.services)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  Future<bool> serviceExists(String serviceCode) async {
    final existing = await (_db.select(_db.services)..where((s) => s.serviceCode.equals(serviceCode))).getSingleOrNull();
    return existing != null;
  }

  Future<int> addService(ServicesCompanion entry) async {
    return _db.into(_db.services).insert(entry);
  }

  Future<bool> updateService(Service service) async {
    return _db.update(_db.services).replace(service);
  }

  Future<bool> deleteService(int id) async {
    final count = await (_db.delete(_db.services)..where((s) => s.id.equals(id))).go();
    return count > 0;
  }
}
