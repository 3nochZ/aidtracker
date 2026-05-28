import 'dart:async';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../models/beneficiary.dart';
import '../models/inventory_item.dart';
import '../models/distribution.dart';
import '../models/app_user.dart';
import '../models/audit_log.dart';
import '../services/local_db_service.dart';
import '../core/hash_utils.dart';

class DataProvider extends ChangeNotifier {
  final LocalDbService _dbService = LocalDbService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  List<Beneficiary> _beneficiaries = [];
  List<InventoryItem> _inventory = [];
  List<Distribution> _distributions = [];
  List<AppUser> _team = [];
  List<AuditLog> _auditLogs = [];
  DateTime? _lastSyncTime;
  StreamSubscription<QuerySnapshot>? _inventorySubscription;
  StreamSubscription<QuerySnapshot>? _beneficiariesSubscription;
  
  List<Beneficiary> get beneficiaries => _beneficiaries.where((b) => b.syncStatus != 'deleted' && b.status == 'approved').toList();
  List<Beneficiary> get pendingApprovalBeneficiaries => _beneficiaries.where((b) => b.syncStatus != 'deleted' && b.status == 'pending').toList();
  DateTime? get lastSyncTime => _lastSyncTime;
  List<InventoryItem> get inventory => _inventory.where((i) => i.syncStatus != 'deleted').toList();
  List<Distribution> get distributions => _distributions.where((d) => d.syncStatus != 'deleted').toList();
  List<AppUser> get team => _team;
  List<AuditLog> get auditLogs => _auditLogs;

  int get totalDistributions => distributions.length; 
  
  int get pendingBeneficiariesCount => _beneficiaries.where((b) => b.syncStatus == 'pending' || b.syncStatus == 'deleted').length;
  int get pendingInventoryCount => _inventory.where((i) => i.syncStatus == 'pending' || i.syncStatus == 'deleted').length;
  int get pendingDistributionsCount => _distributions.where((d) => d.syncStatus == 'pending' || d.syncStatus == 'deleted').length;
  int get pendingTeamCount => _team.where((t) => t.syncStatus == 'pending').length;
  int get pendingAuditLogsCount => _auditLogs.where((l) => l.syncStatus == 'pending').length;

  int get pendingSyncCount => pendingBeneficiariesCount + pendingInventoryCount + pendingDistributionsCount + pendingTeamCount + pendingAuditLogsCount;

  List<InventoryItem> get lowStockItems => inventory.where((item) => item.quantity <= item.minStockLevel).toList();

  Map<dynamic, dynamic> _deepCastMap(dynamic value) {
    if (value is Map) {
      return Map<dynamic, dynamic>.fromEntries(
        value.entries.map((e) => MapEntry(e.key, e.value is Map ? _deepCastMap(e.value) : e.value)),
      );
    }
    return {};
  }

  List<T> _safeLoadBox<T>(Box box, T Function(Map<dynamic, dynamic>) fromMap) {
    final results = <T>[];
    for (final entry in box.toMap().entries) {
      if (entry.key == 'current_session' || entry.key == 'last_sync_time') {
        continue; 
      }
      try {
        final map = _deepCastMap(entry.value);
        results.add(fromMap(map));
      } catch (e) {
        debugPrint("[skipping corrupted entry] key=${entry.key}: $e");
      }
    }
    return results;
  }

  Future<void> loadData() async {
    try {
      final benBox = _dbService.getBeneficiariesBox();
      final invBox = _dbService.getInventoryBox();
      final distBox = _dbService.getDistributionsBox();
      final usersBox = _dbService.getUsersBox();
      final logBox = _dbService.getAuditLogsBox();
      final campaignsBox = _dbService.getCampaignsBox();

      final lastSyncStr = campaignsBox.get('last_sync_time') as String?;
      if (lastSyncStr != null) {
        _lastSyncTime = DateTime.tryParse(lastSyncStr);
      }

      _beneficiaries = _safeLoadBox(benBox, Beneficiary.fromMap);
      _inventory = _safeLoadBox(invBox, InventoryItem.fromMap);
      _distributions = _safeLoadBox(distBox, Distribution.fromMap);
      _team = _safeLoadBox(usersBox, AppUser.fromMap);
      _auditLogs = _safeLoadBox(logBox, AuditLog.fromMap);

      _distributions.sort((a, b) => b.date.compareTo(a.date));
      _auditLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (_team.isEmpty && _beneficiaries.isEmpty && _inventory.isEmpty) {
        _insertMockData();
      }
      
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        startRealtimeSync();
      }
    } catch (e) {
      debugPrint("(loaddata failed): $e - starting with empty state");
    }

    notifyListeners();
  }

  void _insertMockData() {
    final admin = AppUser(id: 'u1', name: 'Regional Manager', email: 'admin@ngo.org', password: HashUtils.hashPassword('123456'), role: 'admin', location: 'HQ', syncStatus: 'pending');
    final agent = AppUser(id: 'u2', name: 'Amina Hassan', email: 'agent@ngo.org', password: HashUtils.hashPassword('123456'), role: 'agent', location: 'Kismayu Camp', syncStatus: 'pending');
    
    _dbService.getUsersBox().put(admin.id, admin.toMap());
    _dbService.getUsersBox().put(agent.id, agent.toMap());
    _team.addAll([admin, agent]);

    final amina = Beneficiary(id: 'mock_amina', name: 'Amina Hassan', location: 'Addis Ababa, Bole, Kebele 03, House No. 402', householdSize: 5, group: 'General', syncStatus: 'pending', assignedAgentId: null, registeredByAgentId: 'u2', registeredByAgentName: 'Amina Hassan');
    final mohamed = Beneficiary(id: 'mock_mohamed', name: 'Mohamed Ali', location: 'Addis Ababa, Yeka, Kebele 12, House No. 809', householdSize: 4, group: 'Elderly', syncStatus: 'pending', assignedAgentId: null, registeredByAgentId: 'u2', registeredByAgentName: 'Amina Hassan');
    
    _dbService.getBeneficiariesBox().put(amina.id, amina.toMap());
    _dbService.getBeneficiariesBox().put(mohamed.id, mohamed.toMap());
    _beneficiaries.addAll([amina, mohamed]);
    
    final rice = InventoryItem(id: 'mock_rice', name: 'Rice', unit: 'kg', quantity: 150, minStockLevel: 20, syncStatus: 'pending', assignedAgentId: 'u2', allocatedTo: null);
    final oil = InventoryItem(id: 'mock_oil', name: 'Cooking Oil', unit: 'L', quantity: 45, minStockLevel: 10, syncStatus: 'pending', assignedAgentId: 'u2', allocatedTo: null);
    final sugar = InventoryItem(id: 'mock_sugar', name: 'Sugar', unit: 'kg', quantity: 8, minStockLevel: 15, syncStatus: 'pending', assignedAgentId: 'u2', allocatedTo: null);

    _dbService.getInventoryBox().put(rice.id, rice.toMap());
    _dbService.getInventoryBox().put(oil.id, oil.toMap());
    _dbService.getInventoryBox().put(sugar.id, sugar.toMap());
    _inventory.addAll([rice, oil, sugar]);

    final aminaPastDist = Distribution(
      id: 'mock_dist_amina', beneficiaryId: 'mock_amina', beneficiaryName: 'Amina Hassan', items: {'mock_rice': 5}, notes: 'regular campaign distribution', date: DateTime.now().subtract(const Duration(days: 31)), agentId: 'u2', agentName: 'Amina Hassan', syncStatus: 'pending',
    );
    _dbService.getDistributionsBox().put(aminaPastDist.id, aminaPastDist.toMap());
    _distributions.add(aminaPastDist);
  }

  bool hasReceivedItemInLast30Days(String beneficiaryId, String itemId) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _distributions.any((dist) {
      if (dist.syncStatus == 'deleted') return false;
      return dist.beneficiaryId == beneficiaryId &&
          dist.date.isAfter(thirtyDaysAgo) &&
          dist.items.containsKey(itemId);
    });
  }

  Future<void> updateDistributionAndLog(String distId, Map<String, int> newItems, String editReason, AppUser agent) async {
    final distIdx = _distributions.indexWhere((d) => d.id == distId);
    if (distIdx == -1) return;

    final oldDist = _distributions[distIdx];
    
    oldDist.items.forEach((itemId, oldQty) async {
      final newQty = newItems[itemId] ?? 0;
      final diff = newQty - oldQty; 
      
      final invIdx = _inventory.indexWhere((i) => i.id == itemId);
      if (invIdx != -1) {
        final item = _inventory[invIdx];
        final updatedItem = InventoryItem(id: item.id, name: item.name, unit: item.unit, quantity: item.quantity - diff, minStockLevel: item.minStockLevel, syncStatus: 'pending', assignedAgentId: item.assignedAgentId, allocatedTo: item.allocatedTo);
        await _dbService.getInventoryBox().put(item.id, updatedItem.toMap());
        _inventory[invIdx] = updatedItem;
      }
    });

    _distributions[distIdx] = Distribution(id: oldDist.id, beneficiaryId: oldDist.beneficiaryId, beneficiaryName: oldDist.beneficiaryName, items: newItems, notes: 'EDITED: $editReason', date: DateTime.now(), agentId: oldDist.agentId, agentName: oldDist.agentName, syncStatus: 'pending');
    await _dbService.getDistributionsBox().put(oldDist.id, _distributions[distIdx].toMap());

    final String logDetails = "edited distribution for ${oldDist.beneficiaryName}. changes: old: ${oldDist.items} -> new: $newItems. reason: $editReason";
    final auditLog = AuditLog(id: _uuid.v4(), action: 'distribution_edited', details: logDetails, userId: agent.id, userName: agent.name, timestamp: DateTime.now(), syncStatus: 'pending');
    await _dbService.getAuditLogsBox().put(auditLog.id, auditLog.toMap());
    _auditLogs.insert(0, auditLog);

    notifyListeners();
  }

  Future<void> deleteDistribution(String distId, AppUser admin) async {
    final distIdx = _distributions.indexWhere((d) => d.id == distId);
    if (distIdx == -1) return;

    final oldDist = _distributions[distIdx];

    oldDist.items.forEach((itemId, qty) async {
      final invIdx = _inventory.indexWhere((i) => i.id == itemId);
      if (invIdx != -1) {
        final item = _inventory[invIdx];
        final updatedItem = InventoryItem(
          id: item.id,
          name: item.name,
          unit: item.unit,
          quantity: item.quantity + qty,
          minStockLevel: item.minStockLevel,
          syncStatus: 'pending',
          assignedAgentId: item.assignedAgentId,
          allocatedTo: item.allocatedTo,
        );
        await _dbService.getInventoryBox().put(item.id, updatedItem.toMap());
        _inventory[invIdx] = updatedItem;
      }
    });

    _distributions[distIdx] = Distribution(
      id: oldDist.id,
      beneficiaryId: oldDist.beneficiaryId,
      beneficiaryName: oldDist.beneficiaryName,
      items: oldDist.items,
      notes: oldDist.notes,
      date: oldDist.date,
      agentId: oldDist.agentId,
      agentName: oldDist.agentName,
      syncStatus: 'deleted',
    );
    await _dbService.getDistributionsBox().put(oldDist.id, _distributions[distIdx].toMap());

    final String logDetails = "deleted distribution for ${oldDist.beneficiaryName}. returned items to inventory: ${oldDist.items}";
    final auditLog = AuditLog(
      id: _uuid.v4(),
      action: 'distribution_deleted',
      details: logDetails,
      userId: admin.id,
      userName: admin.name,
      timestamp: DateTime.now(),
      syncStatus: 'pending',
    );
    await _dbService.getAuditLogsBox().put(auditLog.id, auditLog.toMap());
    _auditLogs.insert(0, auditLog);

    notifyListeners();
  }

  Future<void> addAgent(String name, String email, String password, String role, String location) async {
    final newAgent = AppUser(id: _uuid.v4(), name: name, email: email, password: HashUtils.hashPassword(password), role: role, location: location, syncStatus: 'pending');
    await _dbService.getUsersBox().put(newAgent.id, newAgent.toMap());
    _team.add(newAgent);
    notifyListeners();
  }

  Future<AppUser> changeUserPassword(String userId, String currentPasswordHash, String newPasswordHash) async {
    final index = _team.indexWhere((u) => u.id == userId);
    if (index == -1) throw Exception("User not found.");
    final u = _team[index];
    if (u.password != currentPasswordHash) throw Exception("Incorrect current password.");
    
    _team[index] = AppUser(id: u.id, name: u.name, email: u.email, password: newPasswordHash, role: u.role, location: u.location, isActive: u.isActive, syncStatus: 'pending');
    await _dbService.getUsersBox().put(u.id, _team[index].toMap());
    notifyListeners();
    return _team[index];
  }

  Future<AppUser> adminResetUserPassword(String userId, String newPasswordHash) async {
    final index = _team.indexWhere((u) => u.id == userId);
    if (index == -1) throw Exception("User not found.");
    final u = _team[index];
    
    _team[index] = AppUser(id: u.id, name: u.name, email: u.email, password: newPasswordHash, role: u.role, location: u.location, isActive: u.isActive, syncStatus: 'pending');
    await _dbService.getUsersBox().put(u.id, _team[index].toMap());
    notifyListeners();
    return _team[index];
  }

  Future<void> toggleUserRole(String userId) async {
    final index = _team.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final u = _team[index];
      final newRole = u.role == 'admin' ? 'agent' : 'admin';
      _team[index] = AppUser(id: u.id, name: u.name, email: u.email, password: u.password, role: newRole, location: u.location, isActive: u.isActive, syncStatus: 'pending');
      await _dbService.getUsersBox().put(u.id, _team[index].toMap());
      notifyListeners();
    }
  }

  Future<void> toggleUserStatus(String userId) async {
    final index = _team.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final u = _team[index];
      _team[index] = AppUser(id: u.id, name: u.name, email: u.email, password: u.password, role: u.role, location: u.location, isActive: !u.isActive, syncStatus: 'pending');
      await _dbService.getUsersBox().put(u.id, _team[index].toMap());
      notifyListeners();
    }
  }

  Future<void> addBeneficiary(String name, String location, int householdSize, {String group = 'General', String? assignedAgentId, bool isAdmin = false, String? registeredByAgentId, String? registeredByAgentName}) async {
    final beneficiary = Beneficiary(
      id: _uuid.v4(), 
      name: name, 
      location: location, 
      householdSize: householdSize, 
      group: group, 
      status: isAdmin ? 'approved' : 'pending',
      syncStatus: 'pending', 
      assignedAgentId: assignedAgentId,
      registeredByAgentId: registeredByAgentId,
      registeredByAgentName: registeredByAgentName,
    );
    await _dbService.getBeneficiariesBox().put(beneficiary.id, beneficiary.toMap());
    _beneficiaries.add(beneficiary);
    notifyListeners();
  }

  Future<void> approveBeneficiary(String id, {AppUser? approvedBy}) async {
    final index = _beneficiaries.indexWhere((b) => b.id == id);
    if (index != -1) {
      final b = _beneficiaries[index];
      _beneficiaries[index] = Beneficiary(
        id: b.id, name: b.name, location: b.location, householdSize: b.householdSize, 
        group: b.group, status: 'approved', syncStatus: 'pending', assignedAgentId: b.assignedAgentId,
        registeredByAgentId: b.registeredByAgentId, registeredByAgentName: b.registeredByAgentName,
      );
      await _dbService.getBeneficiariesBox().put(id, _beneficiaries[index].toMap());

      if (approvedBy != null) {
        final auditLog = AuditLog(
          id: _uuid.v4(),
          action: 'beneficiary_approved',
          details: 'approved beneficiary: ${b.name} (registered by: ${b.registeredByAgentName ?? 'Admin/System'})',
          userId: approvedBy.id,
          userName: approvedBy.name,
          timestamp: DateTime.now(),
          syncStatus: 'pending',
        );
        await _dbService.getAuditLogsBox().put(auditLog.id, auditLog.toMap());
        _auditLogs.insert(0, auditLog);
      }

      notifyListeners();
    }
  }

  Future<void> rejectBeneficiary(String id, {required AppUser rejectedBy}) async {
    final index = _beneficiaries.indexWhere((b) => b.id == id);
    if (index != -1) {
      final b = _beneficiaries[index];
      _beneficiaries[index] = Beneficiary(
        id: b.id, name: b.name, location: b.location, householdSize: b.householdSize,
        group: b.group, status: b.status, syncStatus: 'deleted', assignedAgentId: b.assignedAgentId,
        registeredByAgentId: b.registeredByAgentId, registeredByAgentName: b.registeredByAgentName,
      );
      await _dbService.getBeneficiariesBox().put(b.id, _beneficiaries[index].toMap());

      final auditLog = AuditLog(
        id: _uuid.v4(),
        action: 'beneficiary_rejected',
        details: 'rejected beneficiary: ${b.name} (registered by: ${b.registeredByAgentName ?? 'Admin/System'})',
        userId: rejectedBy.id,
        userName: rejectedBy.name,
        timestamp: DateTime.now(),
        syncStatus: 'pending',
      );
      await _dbService.getAuditLogsBox().put(auditLog.id, auditLog.toMap());
      _auditLogs.insert(0, auditLog);

      notifyListeners();
    }
  }

  Future<void> importBeneficiariesFromCsv(String csvData) async {
    List<List<dynamic>> rows = const CsvToListConverter(eol: '\n').convert(csvData);
    if (rows.isEmpty) return;
    
    for (int i = 1; i < rows.length; i++) {
      if (rows[i].length < 3) continue;
      await addBeneficiary(
        rows[i][0].toString(), 
        rows[i][1].toString(), 
        int.tryParse(rows[i][2].toString()) ?? 1,
        group: rows[i].length > 3 ? rows[i][3].toString() : 'General',
        isAdmin: true, 
      );
    }
  }

  Future<void> importInventoryFromCsv(String csvData) async {
    List<List<dynamic>> rows = const CsvToListConverter(eol: '\n').convert(csvData);
    if (rows.isEmpty) return;
    
    for (int i = 1; i < rows.length; i++) {
      if (rows[i].length < 3) continue;
      await addInventoryItem(
        rows[i][0].toString(), 
        rows[i][1].toString(), 
        int.tryParse(rows[i][2].toString()) ?? 0,
        minStockLevel: rows[i].length > 3 ? (int.tryParse(rows[i][3].toString()) ?? 10) : 10,
      );
    }
  }

  Future<void> updateBeneficiary(String id, String name, String location, int householdSize, String group, {String? assignedAgentId}) async {
    final index = _beneficiaries.indexWhere((b) => b.id == id);
    if (index != -1) {
      final old = _beneficiaries[index];
      _beneficiaries[index] = Beneficiary(id: id, name: name, location: location, householdSize: householdSize, group: group, status: old.status, syncStatus: 'pending', assignedAgentId: assignedAgentId, registeredByAgentId: old.registeredByAgentId, registeredByAgentName: old.registeredByAgentName);
      await _dbService.getBeneficiariesBox().put(id, _beneficiaries[index].toMap());
      notifyListeners();
    }
  }

  Future<void> addInventoryItem(String name, String unit, int quantity, {int minStockLevel = 10, String? assignedAgentId, String? allocatedTo}) async {
    final item = InventoryItem(id: _uuid.v4(), name: name, unit: unit, quantity: quantity, minStockLevel: minStockLevel, syncStatus: 'pending', assignedAgentId: assignedAgentId, allocatedTo: allocatedTo);
    await _dbService.getInventoryBox().put(item.id, item.toMap());
    _inventory.add(item);
    notifyListeners();
  }

  Future<void> deleteBeneficiary(String id) async {
    final index = _beneficiaries.indexWhere((b) => b.id == id);
    if (index != -1) {
      final b = _beneficiaries[index];
      _beneficiaries[index] = Beneficiary(id: b.id, name: b.name, location: b.location, householdSize: b.householdSize, group: b.group, status: b.status, syncStatus: 'deleted', assignedAgentId: b.assignedAgentId, registeredByAgentId: b.registeredByAgentId, registeredByAgentName: b.registeredByAgentName);
      await _dbService.getBeneficiariesBox().put(b.id, _beneficiaries[index].toMap());
      notifyListeners();
    }
  }

  Future<void> deleteInventoryItem(String id) async {
    final index = _inventory.indexWhere((i) => i.id == id);
    if (index != -1) {
      final item = _inventory[index];
      _inventory[index] = InventoryItem(id: item.id, name: item.name, unit: item.unit, quantity: item.quantity, minStockLevel: item.minStockLevel, syncStatus: 'deleted', assignedAgentId: item.assignedAgentId, allocatedTo: item.allocatedTo);
      await _dbService.getInventoryBox().put(item.id, _inventory[index].toMap());
      notifyListeners();
    }
  }

  Future<void> recordDistribution(Beneficiary beneficiary, Map<InventoryItem, int> selectedItems, String notes, {required String agentId, required String agentName}) async {
    Map<String, int> storedItems = {};
    selectedItems.forEach((item, qty) { if (qty > 0) storedItems[item.id] = qty; });
    if (storedItems.isEmpty) return; 

    final distId = _uuid.v4();
    final distribution = Distribution(
      id: distId, 
      beneficiaryId: beneficiary.id, 
      beneficiaryName: beneficiary.name, 
      items: storedItems, 
      notes: notes, 
      date: DateTime.now(), 
      agentId: agentId, 
      agentName: agentName, 
      syncStatus: 'pending',
    ); 
    await _dbService.getDistributionsBox().put(distId, distribution.toMap());
    _distributions.insert(0, distribution); 

    for (var entry in storedItems.entries) {
      final itemId = entry.key;
      final qtyToDeduct = entry.value;
      final itemIndex = _inventory.indexWhere((i) => i.id == itemId);
      if (itemIndex != -1) {
        final item = _inventory[itemIndex];
        final updatedItem = InventoryItem(
          id: item.id, name: item.name, unit: item.unit, quantity: item.quantity - qtyToDeduct, minStockLevel: item.minStockLevel, syncStatus: 'pending', assignedAgentId: item.assignedAgentId, allocatedTo: item.allocatedTo,
        );
        await _dbService.getInventoryBox().put(item.id, updatedItem.toMap());
        _inventory[itemIndex] = updatedItem;
      }
    }
    notifyListeners();
  }

  Future<void> _pullCollection<T>({
    required String collectionName,
    required Box hiveBox,
    required T Function(Map<dynamic, dynamic> map) fromMap,
    required Map<String, dynamic> Function(T item) toMap,
    required String Function(T item) getId,
    required String? Function(T item) getSyncStatus,
    required T Function(T item, String status) withSyncStatus,
  }) async {
    try {
      final snapshot = await _firestore.collection(collectionName).get();
      final cloudDocs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return fromMap(data);
      }).toList();
      final cloudMap = {for (var doc in cloudDocs) getId(doc): doc};

      final localItems = hiveBox.values.map((e) => fromMap(Map<dynamic, dynamic>.from(e as Map))).toList();

      for (var local in localItems) {
        final id = getId(local);
        final status = getSyncStatus(local);

        if (status == 'pending' || status == 'deleted') {
          continue;
        }

        if (!cloudMap.containsKey(id)) {
          await hiveBox.delete(id);
        } else {
          final cloudItem = cloudMap[id];
          if (cloudItem != null) {
            final updatedItem = withSyncStatus(cloudItem, 'synced');
            await hiveBox.put(id, toMap(updatedItem));
          }
        }
      }

      for (var cloudItem in cloudDocs) {
        final id = getId(cloudItem);
        if (!hiveBox.containsKey(id)) {
          final updatedItem = withSyncStatus(cloudItem, 'synced');
          await hiveBox.put(id, toMap(updatedItem));
        }
      }
    } catch (e) {
      debugPrint("{pulling collection $collectionName failed}: $e");
    }
  }

  // modified to return a list of warnings
  Future<List<String>> syncPendingData({String? currentUserId}) async {
    List<String> syncWarnings = []; // tracks issues like deleted beneficiaries

    try {
      debugPrint("[sync system initiated]");
      debugPrint("(step 1: verifying internet connection)");
      await _firestore.collection('test').add({'ping': 'pong'}).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception("firebase connection hanging: network completely blocked");
      });
      debugPrint("{step 1: google servers reached successfully}");

      if (currentUserId != null) {
        final userDoc = await _firestore.collection('users').doc(currentUserId).get();
        if (userDoc.exists) {
          final isActive = userDoc.data()?['isActive'] ?? true;
          if (!isActive) {
            throw Exception("Account suspended. Sync rejected.");
          }
        }
      }

      debugPrint("<step 2: syncing team users>");
      for (int i = 0; i < _team.length; i++) {
        if (_team[i].syncStatus == 'pending') {
          var cloudData = _team[i].toMap()..remove('syncStatus');
          await _firestore.collection('users').doc(_team[i].id).set(cloudData);
          _team[i] = AppUser(id: _team[i].id, name: _team[i].name, email: _team[i].email, password: _team[i].password, role: _team[i].role, location: _team[i].location, isActive: _team[i].isActive, syncStatus: 'synced');
          await _dbService.getUsersBox().put(_team[i].id, _team[i].toMap());
        }
      }

      debugPrint("[step 3: syncing audit logs]");
      for (int i = 0; i < _auditLogs.length; i++) {
        if (_auditLogs[i].syncStatus == 'pending') {
          var cloudData = _auditLogs[i].toMap()..remove('syncStatus');
          await _firestore.collection('audit_logs').doc(_auditLogs[i].id).set(cloudData);
          _auditLogs[i] = AuditLog(id: _auditLogs[i].id, action: _auditLogs[i].action, details: _auditLogs[i].details, userId: _auditLogs[i].userId, userName: _auditLogs[i].userName, timestamp: _auditLogs[i].timestamp, syncStatus: 'synced');
          await _dbService.getAuditLogsBox().put(_auditLogs[i].id, _auditLogs[i].toMap());
        }
      }

      debugPrint("(step 4: syncing beneficiaries)");
      for (int i = _beneficiaries.length - 1; i >= 0; i--) {
        if (_beneficiaries[i].syncStatus == 'pending') {
          var cloudData = _beneficiaries[i].toMap()..remove('syncStatus'); 
          await _firestore.collection('beneficiaries').doc(_beneficiaries[i].id).set(cloudData);
          _beneficiaries[i] = Beneficiary(id: _beneficiaries[i].id, name: _beneficiaries[i].name, location: _beneficiaries[i].location, householdSize: _beneficiaries[i].householdSize, group: _beneficiaries[i].group, status: _beneficiaries[i].status, syncStatus: 'synced', assignedAgentId: _beneficiaries[i].assignedAgentId, registeredByAgentId: _beneficiaries[i].registeredByAgentId, registeredByAgentName: _beneficiaries[i].registeredByAgentName);
          await _dbService.getBeneficiariesBox().put(_beneficiaries[i].id, _beneficiaries[i].toMap());
        } else if (_beneficiaries[i].syncStatus == 'deleted') {
          await _firestore.collection('beneficiaries').doc(_beneficiaries[i].id).delete();
          await _dbService.getBeneficiariesBox().delete(_beneficiaries[i].id);
          _beneficiaries.removeAt(i);
        }
      }

      debugPrint("{step 5: syncing inventory}");
      for (int i = _inventory.length - 1; i >= 0; i--) {
        if (_inventory[i].syncStatus == 'pending') {
          var cloudData = _inventory[i].toMap()..remove('syncStatus');
          await _firestore.collection('inventory').doc(_inventory[i].id).set(cloudData);
          _inventory[i] = InventoryItem(id: _inventory[i].id, name: _inventory[i].name, unit: _inventory[i].unit, quantity: _inventory[i].quantity, minStockLevel: _inventory[i].minStockLevel, syncStatus: 'synced', assignedAgentId: _inventory[i].assignedAgentId, allocatedTo: _inventory[i].allocatedTo);
          await _dbService.getInventoryBox().put(_inventory[i].id, _inventory[i].toMap());
        } else if (_inventory[i].syncStatus == 'deleted') {
          await _firestore.collection('inventory').doc(_inventory[i].id).delete();
          await _dbService.getInventoryBox().delete(_inventory[i].id);
          _inventory.removeAt(i);
        }
      }

      debugPrint("<step 6: syncing distributions and catching deleted beneficiaries>");
      for (int i = _distributions.length - 1; i >= 0; i--) {
        if (_distributions[i].syncStatus == 'pending') {
          
          // check if beneficiary still exists on the cloud
          final benDoc = await _firestore.collection('beneficiaries').doc(_distributions[i].beneficiaryId).get();
          if (!benDoc.exists) {
            syncWarnings.add('Beneficiary deleted: ${_distributions[i].beneficiaryName}. Distribution cancelled and inventory replenished.');
            
            // replenish inventory locally
            for (var entry in _distributions[i].items.entries) {
              final invIdx = _inventory.indexWhere((inv) => inv.id == entry.key);
              if (invIdx != -1) {
                final item = _inventory[invIdx];
                final updatedItem = InventoryItem(
                  id: item.id, name: item.name, unit: item.unit, 
                  quantity: item.quantity + entry.value, minStockLevel: item.minStockLevel, 
                  syncStatus: 'pending', assignedAgentId: item.assignedAgentId, 
                  allocatedTo: item.allocatedTo
                );
                await _dbService.getInventoryBox().put(item.id, updatedItem.toMap());
                _inventory[invIdx] = updatedItem;
              }
            }
            
            // delete the invalid offline distribution
            await _dbService.getDistributionsBox().delete(_distributions[i].id);
            _distributions.removeAt(i);
            continue; // skip pushing to cloud
          }

          var cloudData = _distributions[i].toMap()..remove('syncStatus');
          
          bool hasConflict = false;
          for (var itemEntry in _distributions[i].items.entries) {
            final doc = await _firestore.collection('inventory').doc(itemEntry.key).get();
            if (doc.exists) {
              final int cloudQty = doc.data()?['quantity'] ?? 0;
              if (cloudQty < itemEntry.value) {
                hasConflict = true;
                await _firestore.collection('sync_conflicts').add({
                  'distributionId': _distributions[i].id,
                  'beneficiaryName': _distributions[i].beneficiaryName,
                  'itemId': itemEntry.key,
                  'requestedQty': itemEntry.value,
                  'availableCloudQty': cloudQty,
                  'timestamp': FieldValue.serverTimestamp(),
                });
              }
            }
          }

          await _firestore.collection('distributions').doc(_distributions[i].id).set(cloudData);
          _distributions[i] = Distribution(
            id: _distributions[i].id, beneficiaryId: _distributions[i].beneficiaryId, 
            beneficiaryName: _distributions[i].beneficiaryName, items: _distributions[i].items, 
            notes: _distributions[i].notes, date: _distributions[i].date, 
            agentId: _distributions[i].agentId, agentName: _distributions[i].agentName,
            syncStatus: hasConflict ? 'conflict' : 'synced',
          );
          await _dbService.getDistributionsBox().put(_distributions[i].id, _distributions[i].toMap());
        } else if (_distributions[i].syncStatus == 'deleted') {
          await _firestore.collection('distributions').doc(_distributions[i].id).delete();
          await _dbService.getDistributionsBox().delete(_distributions[i].id);
          _distributions.removeAt(i);
        }
      }

      debugPrint("[bidirectional pull: pulling updates from firestore]");
      await _pullCollection<AppUser>(
        collectionName: 'users',
        hiveBox: _dbService.getUsersBox(),
        fromMap: (map) => AppUser.fromMap(map),
        toMap: (user) => user.toMap(),
        getId: (user) => user.id,
        getSyncStatus: (user) => user.syncStatus,
        withSyncStatus: (user, status) => AppUser(
          id: user.id,
          name: user.name,
          email: user.email,
          password: user.password,
          role: user.role,
          location: user.location,
          isActive: user.isActive,
          syncStatus: status,
        ),
      );

      await _pullCollection<Beneficiary>(
        collectionName: 'beneficiaries',
        hiveBox: _dbService.getBeneficiariesBox(),
        fromMap: (map) => Beneficiary.fromMap(map),
        toMap: (b) => b.toMap(),
        getId: (b) => b.id,
        getSyncStatus: (b) => b.syncStatus,
        withSyncStatus: (b, status) => Beneficiary(
          id: b.id,
          name: b.name,
          location: b.location,
          householdSize: b.householdSize,
          group: b.group,
          status: b.status,
          syncStatus: status,
          assignedAgentId: b.assignedAgentId,
          registeredByAgentId: b.registeredByAgentId,
          registeredByAgentName: b.registeredByAgentName,
        ),
      );

      await _pullCollection<InventoryItem>(
        collectionName: 'inventory',
        hiveBox: _dbService.getInventoryBox(),
        fromMap: (map) => InventoryItem.fromMap(map),
        toMap: (i) => i.toMap(),
        getId: (i) => i.id,
        getSyncStatus: (i) => i.syncStatus,
        withSyncStatus: (i, status) => InventoryItem(
          id: i.id,
          name: i.name,
          unit: i.unit,
          quantity: i.quantity,
          minStockLevel: i.minStockLevel,
          syncStatus: status,
          assignedAgentId: i.assignedAgentId,
          allocatedTo: i.allocatedTo,
        ),
      );

      await _pullCollection<Distribution>(
        collectionName: 'distributions',
        hiveBox: _dbService.getDistributionsBox(),
        fromMap: (map) => Distribution.fromMap(map),
        toMap: (d) => d.toMap(),
        getId: (d) => d.id,
        getSyncStatus: (d) => d.syncStatus,
        withSyncStatus: (d, status) => Distribution(
          id: d.id,
          beneficiaryId: d.beneficiaryId,
          beneficiaryName: d.beneficiaryName,
          items: d.items,
          notes: d.notes,
          date: d.date,
          agentId: d.agentId,
          agentName: d.agentName,
          syncStatus: status,
        ),
      );

      await _pullCollection<AuditLog>(
        collectionName: 'audit_logs',
        hiveBox: _dbService.getAuditLogsBox(),
        fromMap: (map) => AuditLog.fromMap(map),
        toMap: (l) => l.toMap(),
        getId: (l) => l.id,
        getSyncStatus: (l) => l.syncStatus,
        withSyncStatus: (l, status) => AuditLog(
          id: l.id,
          action: l.action,
          details: l.details,
          userId: l.userId,
          userName: l.userName,
          timestamp: l.timestamp,
          syncStatus: status,
        ),
      );

      debugPrint("(reloading data from local storage)");
      await loadData();

      _lastSyncTime = DateTime.now();
      await _dbService.getCampaignsBox().put('last_sync_time', _lastSyncTime!.toIso8601String());
      notifyListeners();

      debugPrint("{bidirectional sync completed successfully}");
      
      // return warnings to the UI
      return syncWarnings;
      
    } catch (e) {
      debugPrint("<sync failed! error decoded: $e>");
      rethrow; 
    }
  }

  void startRealtimeSync() {
    _inventorySubscription?.cancel();
    _beneficiariesSubscription?.cancel();

    _inventorySubscription = _firestore.collection('inventory').snapshots().listen((snapshot) async {
      await _processSnapshotUpdate<InventoryItem>(
        snapshot: snapshot,
        hiveBox: _dbService.getInventoryBox(),
        fromMap: InventoryItem.fromMap,
        toMap: (item) => item.toMap(),
        getId: (item) => item.id,
        getSyncStatus: (item) => item.syncStatus,
        withSyncStatus: (item, status) => InventoryItem(
          id: item.id,
          name: item.name,
          unit: item.unit,
          quantity: item.quantity,
          minStockLevel: item.minStockLevel,
          syncStatus: status,
          assignedAgentId: item.assignedAgentId,
          allocatedTo: item.allocatedTo,
        ),
        localListUpdate: (items) {
          _inventory = items;
        },
      );
    });

    _beneficiariesSubscription = _firestore.collection('beneficiaries').snapshots().listen((snapshot) async {
      await _processSnapshotUpdate<Beneficiary>(
        snapshot: snapshot,
        hiveBox: _dbService.getBeneficiariesBox(),
        fromMap: Beneficiary.fromMap,
        toMap: (item) => item.toMap(),
        getId: (item) => item.id,
        getSyncStatus: (item) => item.syncStatus,
        withSyncStatus: (item, status) => Beneficiary(
          id: item.id,
          name: item.name,
          location: item.location,
          householdSize: item.householdSize,
          group: item.group,
          status: item.status,
          syncStatus: status,
          assignedAgentId: item.assignedAgentId,
          registeredByAgentId: item.registeredByAgentId,
          registeredByAgentName: item.registeredByAgentName,
        ),
        localListUpdate: (items) {
          _beneficiaries = items;
        },
      );
    });
  }

  Future<void> _processSnapshotUpdate<T>({
    required QuerySnapshot snapshot,
    required Box hiveBox,
    required T Function(Map<dynamic, dynamic> map) fromMap,
    required Map<String, dynamic> Function(T item) toMap,
    required String Function(T item) getId,
    required String? Function(T item) getSyncStatus,
    required T Function(T item, String status) withSyncStatus,
    required void Function(List<T> items) localListUpdate,
  }) async {
    try {
      final cloudDocs = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return fromMap(data);
      }).toList();
      final cloudMap = {for (var doc in cloudDocs) getId(doc): doc};

      final localItems = hiveBox.values.map((e) => fromMap(Map<dynamic, dynamic>.from(e as Map))).toList();

      for (var local in localItems) {
        final id = getId(local);
        final status = getSyncStatus(local);

        if (status == 'pending' || status == 'deleted') {
          continue;
        }

        if (!cloudMap.containsKey(id)) {
          await hiveBox.delete(id);
        } else {
          final cloudItem = cloudMap[id];
          if (cloudItem != null) {
            final updatedItem = withSyncStatus(cloudItem, 'synced');
            await hiveBox.put(id, toMap(updatedItem));
          }
        }
      }

      for (var cloudItem in cloudDocs) {
        final id = getId(cloudItem);
        if (!hiveBox.containsKey(id)) {
          final updatedItem = withSyncStatus(cloudItem, 'synced');
          await hiveBox.put(id, toMap(updatedItem));
        }
      }

      final updatedLocalItems = _safeLoadBox(hiveBox, fromMap);
      localListUpdate(updatedLocalItems);
      notifyListeners();
    } catch (e) {
      debugPrint("[processing snapshot update failed]: $e");
    }
  }

  @override
  void dispose() {
    _inventorySubscription?.cancel();
    _beneficiariesSubscription?.cancel();
    super.dispose();
  }
}