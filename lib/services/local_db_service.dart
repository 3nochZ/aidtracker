import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalDbService {
  static const String beneficiariesBox = 'beneficiaries';
  static const String inventoryBox = 'inventory';
  static const String distributionsBox = 'distributions';
  static const String usersBox = 'users';
  static const String campaignsBox = 'campaigns';
  static const String editRequestsBox = 'editRequests'; // new edit requests box
  static const String auditLogsBox = 'auditLogs'; // new audit logs box

  static Future<void> init() async {
    await Hive.initFlutter();

    const secureStorage = FlutterSecureStorage();
    String? encryptionKeyString = await secureStorage.read(key: 'hive_encryption_key');
    
    if (encryptionKeyString == null) {
      final key = Hive.generateSecureKey();
      await secureStorage.write(key: 'hive_encryption_key', value: base64UrlEncode(key));
      encryptionKeyString = base64UrlEncode(key);
    }
    
    final encryptionKeyUint8List = base64Url.decode(encryptionKeyString);

    await Hive.openBox(beneficiariesBox, encryptionCipher: HiveAesCipher(encryptionKeyUint8List));
    await Hive.openBox(inventoryBox, encryptionCipher: HiveAesCipher(encryptionKeyUint8List));
    await Hive.openBox(distributionsBox, encryptionCipher: HiveAesCipher(encryptionKeyUint8List));
    await Hive.openBox(usersBox, encryptionCipher: HiveAesCipher(encryptionKeyUint8List));
    await Hive.openBox(campaignsBox, encryptionCipher: HiveAesCipher(encryptionKeyUint8List));
    await Hive.openBox(editRequestsBox, encryptionCipher: HiveAesCipher(encryptionKeyUint8List));
    await Hive.openBox(auditLogsBox, encryptionCipher: HiveAesCipher(encryptionKeyUint8List));
  }

  Box getBeneficiariesBox() => Hive.box(beneficiariesBox);
  Box getInventoryBox() => Hive.box(inventoryBox);
  Box getDistributionsBox() => Hive.box(distributionsBox);
  Box getUsersBox() => Hive.box(usersBox);
  Box getCampaignsBox() => Hive.box(campaignsBox);
  Box getEditRequestsBox() => Hive.box(editRequestsBox);
  Box getAuditLogsBox() => Hive.box(auditLogsBox);
}