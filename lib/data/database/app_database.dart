// lib/data/database/app_database.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'app_database.g.dart';

@DataClassName('ServiceHistory')
class ServiceHistories extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vehicleId => integer().references(Vehicles, #id, onDelete: KeyAction.cascade)();
  TextColumn get serviceType => text()();
  DateTimeColumn get serviceDate => dateTime()();
  IntColumn get mileage => integer()();
}

@DriftAccessor(tables: [ServiceHistories])
class ServiceHistoryDao extends DatabaseAccessor<AppDatabase> with _$ServiceHistoryDaoMixin {
  ServiceHistoryDao(AppDatabase db) : super(db);
  Future<void> addServiceHistory(ServiceHistoriesCompanion entry) => into(serviceHistories).insert(entry);
  Future<List<ServiceHistory>> getHistoryForVehicle(int vehicleId) =>
      (select(serviceHistories)..where((tbl) => tbl.vehicleId.equals(vehicleId))..orderBy([(t) => OrderingTerm(expression: t.serviceDate)])).get();
}

@DriftAccessor(tables: [Vehicles])
class VehicleDao extends DatabaseAccessor<AppDatabase> with _$VehicleDaoMixin {
  VehicleDao(AppDatabase db) : super(db);
  Future<List<Vehicle>> getAllVehicles() => select(vehicles).get();
  Future<Vehicle?> getVehicleById(int id) => (select(vehicles)..where((v) => v.id.equals(id))).getSingleOrNull();
  Future<void> insertVehicle(VehiclesCompanion vehicle) => into(vehicles).insert(vehicle);
  Future<bool> updateVehicle(Vehicle vehicle) => update(vehicles).replace(vehicle);
  Future<List<Vehicle>> getVehiclesForCustomer(int customerId) =>
      (select(vehicles)..where((v) => v.customerId.equals(customerId))).get();
  Future<int> deleteVehicle(Vehicle vehicle) => delete(vehicles).delete(vehicle);

  // --- ADDED: Method to check for existing registration number ---
  Future<Vehicle?> getVehicleByRegNo(String regNo) => 
      (select(vehicles)..where((v) => v.registrationNumber.equals(regNo))).getSingleOrNull();
}

@DataClassName('User')
class Users extends Table {
  IntColumn get id => integer().autoIncrement().nullable()();
  TextColumn get username => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get role => text().withDefault(const Constant('User'))();
}

@DataClassName('InventoryItem')
class InventoryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 2, max: 100)();
  TextColumn get partNumber => text().nullable().unique().withLength(min: 1, max: 50)();
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
  IntColumn get currentMileage => integer().nullable()();
  DateTimeColumn get lastGeneralServiceDate => dateTime().nullable()();
  DateTimeColumn get lastEngineOilChangeDate => dateTime().nullable()();
  DateTimeColumn get lastGearOilChangeDate => dateTime().nullable()();
  IntColumn get lastGeneralServiceMileage => integer().nullable()();
  IntColumn get lastEngineOilChangeMileage => integer().nullable()();
  IntColumn get lastGearOilChangeMileage => integer().nullable()();
  DateTimeColumn get nextReminderDate => dateTime().nullable()();
  TextColumn get nextReminderType => text().nullable()();
}

@DataClassName('Order')
class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer().references(Customers, #id, onDelete: KeyAction.restrict)();
  DateTimeColumn get orderDate => dateTime()();
  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();
  TextColumn get status => text().withDefault(const Constant('Pending'))();
}

@DataClassName('OrderItem')
class OrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId => integer().references(Orders, #id, onDelete: KeyAction.cascade)();
  IntColumn get itemId => integer().references(InventoryItems, #id, onDelete: KeyAction.restrict)();
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

@DriftDatabase(tables: [Users, InventoryItems, Customers, Vehicles, Orders, OrderItems, Services, VehicleModels, ServiceHistories], daos: [VehicleDao, ServiceHistoryDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) {
      return m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 8) {
        await m.createTable(serviceHistories);
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
