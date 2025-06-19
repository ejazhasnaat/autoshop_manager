// lib/data/database/app_database.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'app_database.g.dart';

@DataClassName('User')
class Users extends Table {
  IntColumn get id => integer().autoIncrement().nullable()();
  TextColumn get username => text().unique()();
  TextColumn get passwordHash => text()(); // Store hashed passwords
  TextColumn get role => text().withDefault(const Constant('User'))();
}

@DataClassName('InventoryItem')
class InventoryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 2, max: 100)();
  TextColumn get partNumber => text().nullable().unique().withLength(min: 1, max: 50)(); // <--- UPDATED: Made nullable
  TextColumn get supplier => text().nullable().withLength(max: 100)();
  RealColumn get costPrice => real()();
  RealColumn get salePrice => real()();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  TextColumn get stockLocation => text().nullable().withLength(max: 50)();
  TextColumn get vehicleMake => text().nullable().withLength(max: 50)();
  TextColumn get vehicleModel => text().nullable().withLength(max: 50)();
  IntColumn get vehicleYearFrom => integer().nullable()();
  IntColumn get vehicleYearTo => integer().nullable()();
}

@DataClassName('Customer')
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 2, max: 100)();
  TextColumn get phoneNumber => text().unique().withLength(min: 11, max: 14)();
  TextColumn get whatsappNumber => text().nullable().withLength(min: 11, max: 14)();
  TextColumn get email => text().nullable().withLength(max: 100)();
  TextColumn get address => text().nullable().withLength(max: 200)();
}

@DataClassName('Vehicle')
class Vehicles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer().references(Customers, #id, onDelete: KeyAction.cascade)();
  TextColumn get registrationNumber => text().withLength(min: 1, max: 20).unique()();
  TextColumn get make => text().nullable().withLength(max: 50)();
  TextColumn get model => text().nullable().withLength(max: 50)();
  IntColumn get year => integer().nullable()();
}

@DataClassName('Order')
class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId =>
      integer().references(Customers, #id, onDelete: KeyAction.restrict)();
  DateTimeColumn get orderDate => dateTime()();
  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();
  TextColumn get status => text().withDefault(const Constant('Pending'))();
}

@DataClassName('OrderItem')
class OrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId =>
      integer().references(Orders, #id, onDelete: KeyAction.cascade)();
  IntColumn get itemId =>
      integer().references(InventoryItems, #id, onDelete: KeyAction.restrict)();
  IntColumn get quantity => integer()();
  RealColumn get priceAtSale => real()();
}

@DataClassName('Service')
class Services extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 2, max: 100).unique()();
  TextColumn get description => text().nullable().withLength(max: 500)();
  RealColumn get price => real()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

@DataClassName('VehicleModel')
class VehicleModels extends Table {
  TextColumn get make => text().withLength(min: 1, max: 50)();
  TextColumn get model => text().withLength(min: 1, max: 50)();
  IntColumn get yearFrom => integer().nullable()();
  IntColumn get yearTo => integer().nullable()();

  @override
  Set<Column> get primaryKey => {make, model};
}


@DriftDatabase(tables: [Users, InventoryItems, Customers, Vehicles, Orders, OrderItems, Services, VehicleModels])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6; // Keeping schema version at 6 for simplicity with regular db wipes

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) {
      return m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(users, users.role,);
      }
      if (from < 3) {
        await m.createTable(services);
      }
      if (from < 4) {
        await m.addColumn(customers, customers.whatsappNumber);
        await m.createTable(vehicles);
      }
      if (from < 5) {
        await m.createTable(vehicleModels);
      }
      if (from < 6) {
        await m.addColumn(inventoryItems, inventoryItems.vehicleMake);
        await m.addColumn(inventoryItems, inventoryItems.vehicleModel);
        await m.addColumn(inventoryItems, inventoryItems.vehicleYearFrom);
        await m.addColumn(inventoryItems, inventoryItems.vehicleYearTo);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}

