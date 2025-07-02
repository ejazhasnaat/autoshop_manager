// lib/data/database/app_database.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:collection/collection.dart';
import 'package:stream_transform/stream_transform.dart';

part 'app_database.g.dart';

@DataClassName('ShopSetting')
class ShopSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get workshopName => text().withDefault(const Constant('Your Workshop'))();
  TextColumn get workshopAddress => text().withDefault(const Constant('123 Auto Lane'))();
  TextColumn get workshopPhoneNumber => text().withDefault(const Constant('555-123-4567'))();
  TextColumn get workshopManagerName => text().withDefault(const Constant('The Manager'))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('User')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().unique()();
  TextColumn get fullName => text().nullable()();
  TextColumn get passwordHash => text()();
  TextColumn get role => text().withDefault(const Constant('User'))();
  BoolColumn get forcePasswordReset => boolean().withDefault(const Constant(false))();
}

@DataClassName('MessageTemplate')
class MessageTemplates extends Table {
  TextColumn get templateType => text()();
  TextColumn get title => text().withLength(min: 2, max: 100)();
  TextColumn get content => text()();
  @override
  Set<Column> get primaryKey => {templateType};
}

@DataClassName('ServiceHistory')
class ServiceHistories extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vehicleId => integer().references(Vehicles, #id, onDelete: KeyAction.cascade)();
  TextColumn get serviceType => text()();
  DateTimeColumn get serviceDate => dateTime()();
  IntColumn get mileage => integer()();
  IntColumn get repairJobId => integer().nullable().references(RepairJobs, #id, onDelete: KeyAction.setNull)();
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
  BoolColumn get isReminderActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get reminderSnoozedUntil => dateTime().nullable()();
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
  TextColumn get name => text().withLength(min: 2, max: 100)();
  TextColumn get description => text().nullable().withLength(max: 500)();
  RealColumn get price => real()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get category => text().withDefault(const Constant('Uncategorized'))();
  TextColumn get serviceCode => text().unique()();
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

@DataClassName('RepairJob')
class RepairJobs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vehicleId => integer().references(Vehicles, #id, onDelete: KeyAction.restrict)();
  DateTimeColumn get creationDate => dateTime()();
  DateTimeColumn get completionDate => dateTime().nullable()();
  TextColumn get status => text()();
  // --- ADDED: New column for job priority ---
  TextColumn get priority => text().withDefault(const Constant('Normal'))();
  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
}

@DataClassName('RepairJobItem')
class RepairJobItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get repairJobId => integer().references(RepairJobs, #id, onDelete: KeyAction.cascade)();
  TextColumn get itemType => text()();
  IntColumn get linkedItemId => integer()();
  TextColumn get description => text()();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
}

@DriftAccessor(tables: [ServiceHistories])
class ServiceHistoryDao extends DatabaseAccessor<AppDatabase> with _$ServiceHistoryDaoMixin {
  ServiceHistoryDao(AppDatabase db) : super(db);
  Future<void> addServiceHistory(ServiceHistoriesCompanion entry) => into(serviceHistories).insert(entry);
  Future<List<ServiceHistory>> getHistoryForVehicle(int vehicleId) => (select(serviceHistories)..where((tbl) => tbl.vehicleId.equals(vehicleId))..orderBy([(t) => OrderingTerm(expression: t.serviceDate)])).get();
}

@DriftAccessor(tables: [Vehicles])
class VehicleDao extends DatabaseAccessor<AppDatabase> with _$VehicleDaoMixin {
  VehicleDao(AppDatabase db) : super(db);
  Future<List<Vehicle>> getAllVehicles() => select(vehicles).get();
  Future<Vehicle?> getVehicleById(int id) => (select(vehicles)..where((v) => v.id.equals(id))).getSingleOrNull();
  Future<void> insertVehicle(VehiclesCompanion vehicle) => into(vehicles).insert(vehicle);
  Future<bool> updateVehicle(Vehicle vehicle) => update(vehicles).replace(vehicle);
  Future<List<Vehicle>> getVehiclesForCustomer(int customerId) => (select(vehicles)..where((v) => v.customerId.equals(customerId))).get();
  Future<int> deleteVehicle(Vehicle vehicle) => delete(vehicles).delete(vehicle);
  Future<Vehicle?> getVehicleByRegNo(String regNo) => (select(vehicles)..where((v) => v.registrationNumber.equals(regNo))).getSingleOrNull();
}

@DriftAccessor(tables: [RepairJobs, RepairJobItems, Vehicles, Customers, InventoryItems, Services])
class RepairJobDao extends DatabaseAccessor<AppDatabase> with _$RepairJobDaoMixin {
  RepairJobDao(AppDatabase db) : super(db);

  Stream<List<RepairJobWithCustomer>> watchActiveJobs() {
    final query = select(repairJobs)
      ..where((r) => r.status.equals('Completed').not())
      ..orderBy([(r) => OrderingTerm(expression: r.creationDate, mode: OrderingMode.desc)]);

    return query.join([
      innerJoin(vehicles, vehicles.id.equalsExp(repairJobs.vehicleId)),
      innerJoin(customers, customers.id.equalsExp(vehicles.customerId)),
    ]).watch().map((rows) {
      return rows.map((row) {
        return RepairJobWithCustomer(
          repairJob: row.readTable(repairJobs),
          vehicle: row.readTable(vehicles),
          customer: row.readTable(customers),
        );
      }).toList();
    });
  }
  
  Stream<RepairJobWithDetails> watchJobDetails(int jobId) {
    final jobStream = (select(repairJobs)..where((r) => r.id.equals(jobId))).watchSingle();
  
    return jobStream.switchMap((job) {
      if (job == null) {
        return Stream.value(RepairJobWithDetails.empty());
      }

      final vehicleFuture = (select(vehicles)..where((v) => v.id.equals(job.vehicleId))).getSingle();
      final customerFuture = vehicleFuture.then((v) => (select(customers)..where((c) => c.id.equals(v.customerId))).getSingle());
      final itemsStream = (select(repairJobItems)..where((i) => i.repairJobId.equals(jobId))).watch();

      return itemsStream.asyncMap((items) async {
        final vehicle = await vehicleFuture;
        final customer = await customerFuture;
        final grouped = groupBy(items, (RepairJobItem item) => item.itemType);
        
        return RepairJobWithDetails(
          job: job,
          vehicle: vehicle,
          customer: customer,
          inventoryItems: grouped['InventoryItem'] ?? [],
          serviceItems: grouped['Service'] ?? [],
          otherItems: grouped['Other'] ?? [],
        );
      });
    });
  }

  Stream<List<RepairJobWithDetails>> watchAllJobsForVehicle(int vehicleId) {
    final jobsQuery = select(repairJobs)
      ..where((job) => job.vehicleId.equals(vehicleId))
      ..orderBy([(r) => OrderingTerm(expression: r.completionDate, mode: OrderingMode.desc)]);

    return jobsQuery.watch().switchMap((jobs) {
      final futures = jobs.map((job) async {
        final items = await (select(repairJobItems)..where((i) => i.repairJobId.equals(job.id))).get();
        final grouped = groupBy(items, (RepairJobItem item) => item.itemType);

        return RepairJobWithDetails(
          job: job,
          vehicle: null,
          customer: null,
          inventoryItems: grouped['InventoryItem'] ?? [],
          serviceItems: grouped['Service'] ?? [],
          otherItems: grouped['Other'] ?? [],
        );
      }).toList();

      return Stream.fromFuture(Future.wait(futures));
    });
  }
}

class RepairJobWithCustomer {
  final RepairJob repairJob;
  final Vehicle vehicle;
  final Customer customer;
  RepairJobWithCustomer({required this.repairJob, required this.vehicle, required this.customer});
}

class RepairJobWithDetails {
  final RepairJob job;
  final Vehicle? vehicle;
  final Customer? customer;
  final List<RepairJobItem> inventoryItems;
  final List<RepairJobItem> serviceItems;
  final List<RepairJobItem> otherItems;

  RepairJobWithDetails({
    required this.job,
    this.vehicle,
    this.customer,
    required this.inventoryItems,
    required this.serviceItems,
    required this.otherItems,
  });

  factory RepairJobWithDetails.empty() {
    return RepairJobWithDetails(
      job: RepairJob(id: -1, vehicleId: -1, creationDate: DateTime.now(), status: '', priority: 'Normal', totalAmount: 0.0),
      vehicle: null,
      customer: null,
      inventoryItems: [],
      serviceItems: [],
      otherItems: [],
    );
  }

  double get total => 
      inventoryItems.fold<double>(0, (sum, item) => sum + (item.unitPrice * item.quantity)) + 
      serviceItems.fold<double>(0, (sum, item) => sum + (item.unitPrice * item.quantity)) +
      otherItems.fold<double>(0, (sum, item) => sum + (item.unitPrice * item.quantity));
}


class RepairJobItemWithDetails {
  final RepairJobItem repairJobItem;
  final dynamic item;
  RepairJobItemWithDetails({required this.repairJobItem, required this.item});
}

@DriftDatabase(
  tables: [
    Users, InventoryItems, Customers, Vehicles, Orders, OrderItems,
    Services, VehicleModels, ServiceHistories, MessageTemplates, ShopSettings,
    RepairJobs, RepairJobItems
  ], 
  daos: [
    VehicleDao, ServiceHistoryDao, RepairJobDao
  ]
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static final AppDatabase _instance = AppDatabase._();

  factory AppDatabase() {
    return _instance;
  }
  
  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await into(shopSettings).insert(const ShopSettingsCompanion());
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 9) {
        await m.createTable(messageTemplates);
        await m.addColumn(vehicles, vehicles.isReminderActive);
        await m.addColumn(vehicles, vehicles.reminderSnoozedUntil);
      }
      if (from < 10) {
        await m.createTable(shopSettings);
      }
      if (from < 11) {
        await m.addColumn(users, users.forcePasswordReset);
      }
      if (from < 12) {
        await m.addColumn(users, users.fullName);
      }
      if (from < 13) {
        await m.addColumn(services, services.category);
        await m.addColumn(services, services.serviceCode);
      }
      if (from < 14) {
        await m.createTable(repairJobs);
        await m.createTable(repairJobItems);
        await m.addColumn(serviceHistories, serviceHistories.repairJobId);
      }
      // --- ADDED: Migration step to add the new 'priority' column ---
      if (from < 15) {
        await m.addColumn(repairJobs, repairJobs.priority);
      }
    },
    beforeOpen: (details) async {
      if (details.wasCreated) {
        await into(shopSettings).insert(const ShopSettingsCompanion());
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

