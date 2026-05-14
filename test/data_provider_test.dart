import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:aidtracker/providers/data_provider.dart';
import 'package:aidtracker/models/beneficiary.dart';
import 'package:aidtracker/models/inventory_item.dart';
import 'package:aidtracker/models/app_user.dart';

void main() {
  // Initialize the test binding
  TestWidgetsFlutterBinding.ensureInitialized();

  // Sets up the mock channels for Firebase core calls in the test environment
  setupFirebaseCoreMocks();

  late Directory tempDir;
  late DataProvider dataProvider;

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  setUp(() async {
    // 1. Create an isolated temporary directory for Hive storage
    tempDir = await Directory.systemTemp.createTemp('hive_test_dir');
    Hive.init(tempDir.path);

    // 2. Open all necessary Hive boxes in plain text for testing
    await Hive.openBox('beneficiaries');
    await Hive.openBox('inventory');
    await Hive.openBox('distributions');
    await Hive.openBox('users');
    await Hive.openBox('auditLogs');
    await Hive.openBox('campaigns');
    await Hive.openBox('editRequests');

    // 3. Initialize the state provider and load mock data
    dataProvider = DataProvider();
    await dataProvider.loadData();
  });

  tearDown(() async {
    // Clean up databases and delete the temporary folder after each test run
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Aid Tracker Logic Tests', () {
    test('Mock Data initialization verification', () {
      expect(dataProvider.team.length, equals(2));
      expect(dataProvider.beneficiaries.length, equals(2));
      expect(dataProvider.inventory.length, equals(3));
      expect(dataProvider.distributions.length, equals(1));
    });

    test('30-Day Ration Cooldown (Double Distribution Lock)', () async {
      // 1. Verify that mock_amina is NOT locked for mock_rice initially 
      // (last distribution was 31 days ago)
      bool isLockedInitially = dataProvider.hasReceivedItemInLast30Days('mock_amina', 'mock_rice');
      expect(isLockedInitially, isFalse);

      // 2. Fetch Amina and Rice instances
      final amina = dataProvider.beneficiaries.firstWhere((b) => b.id == 'mock_amina');
      final rice = dataProvider.inventory.firstWhere((i) => i.id == 'mock_rice');

      // 3. Record a distribution of Rice to Amina today
      await dataProvider.recordDistribution(
        amina, 
        {rice: 10}, 
        'regular distribution', 
        agentId: 'u2', 
        agentName: 'Amina Hassan',
      );

      // 4. Verify that the 30-day cooldown lock is now ACTIVE for Rice
      bool isLockedNow = dataProvider.hasReceivedItemInLast30Days('mock_amina', 'mock_rice');
      expect(isLockedNow, isTrue);

      // 5. Verify that another item (e.g. Cooking Oil) is NOT locked
      bool isOilLocked = dataProvider.hasReceivedItemInLast30Days('mock_amina', 'mock_oil');
      expect(isOilLocked, isFalse);
    });

    test('Inventory Stock Deduction on Distribution', () async {
      final amina = dataProvider.beneficiaries.firstWhere((b) => b.id == 'mock_amina');
      final rice = dataProvider.inventory.firstWhere((i) => i.id == 'mock_rice');
      
      // Initial stock of Rice is 150
      expect(rice.quantity, equals(150));

      // Distribute 25 units of rice
      await dataProvider.recordDistribution(
        amina, 
        {rice: 25}, 
        'distribution test', 
        agentId: 'u2', 
        agentName: 'Amina Hassan',
      );

      // Verify stock in memory is updated to 125
      final updatedRice = dataProvider.inventory.firstWhere((i) => i.id == 'mock_rice');
      expect(updatedRice.quantity, equals(125));

      // Verify stock inside the Hive database is written as 125
      final hiveRiceMap = Hive.box('inventory').get('mock_rice');
      expect(hiveRiceMap['quantity'], equals(125));
    });

    test('Admin Override: Edit Distribution (Inventory Recalculation & Audit Log)', () async {
      final amina = dataProvider.beneficiaries.firstWhere((b) => b.id == 'mock_amina');
      final rice = dataProvider.inventory.firstWhere((i) => i.id == 'mock_rice');
      final adminUser = AppUser(id: 'u1', name: 'Regional Manager', email: 'admin@ngo.org', password: '123456', role: 'admin', location: 'HQ');

      // 1. Record a distribution of 50 units of rice (Stock drops from 150 to 100)
      await dataProvider.recordDistribution(
        amina, 
        {rice: 50}, 
        'first distribution', 
        agentId: 'u2', 
        agentName: 'Amina Hassan',
      );
      
      final distRecord = dataProvider.distributions.first;
      expect(dataProvider.inventory.firstWhere((i) => i.id == 'mock_rice').quantity, equals(100));

      // 2. Admin edits the distribution quantity to be 20 units instead (30 units returned)
      await dataProvider.updateDistributionAndLog(
        distRecord.id, 
        {'mock_rice': 20}, 
        'incorrect input correction', 
        adminUser,
      );

      // 3. Verify inventory is adjusted back to 130
      expect(dataProvider.inventory.firstWhere((i) => i.id == 'mock_rice').quantity, equals(130));

      // 4. Verify that an audit log is written to track this edit action
      expect(dataProvider.auditLogs.length, equals(1));
      expect(dataProvider.auditLogs.first.action, equals('distribution_edited'));
      expect(dataProvider.auditLogs.first.details, contains('incorrect input correction'));
    });

    test('Admin Override: Delete Distribution (Inventory Restoration & Soft Delete)', () async {
      final amina = dataProvider.beneficiaries.firstWhere((b) => b.id == 'mock_amina');
      final rice = dataProvider.inventory.firstWhere((i) => i.id == 'mock_rice');
      final adminUser = AppUser(id: 'u1', name: 'Regional Manager', email: 'admin@ngo.org', password: '123456', role: 'admin', location: 'HQ');

      // 1. Record a distribution of 40 units of rice (Stock drops from 150 to 110)
      await dataProvider.recordDistribution(
        amina, 
        {rice: 40}, 
        'distribution to delete', 
        agentId: 'u2', 
        agentName: 'Amina Hassan',
      );
      
      final distRecord = dataProvider.distributions.first;
      expect(dataProvider.inventory.firstWhere((i) => i.id == 'mock_rice').quantity, equals(110));

      // 2. Admin deletes the distribution
      await dataProvider.deleteDistribution(distRecord.id, adminUser);

      // 3. Verify stock is completely restored back to 150
      expect(dataProvider.inventory.firstWhere((i) => i.id == 'mock_rice').quantity, equals(150));

      // 4. Verify that the distribution is soft-deleted (filtered out from active lists but kept in DB with status)
      expect(dataProvider.distributions.any((d) => d.id == distRecord.id), isFalse);
      
      final hiveDistMap = Hive.box('distributions').get(distRecord.id);
      expect(hiveDistMap['syncStatus'], equals('deleted'));

      // 5. Verify that a deletion audit log was generated
      expect(dataProvider.auditLogs.length, equals(1));
      expect(dataProvider.auditLogs.first.action, equals('distribution_deleted'));
    });
  });
}
