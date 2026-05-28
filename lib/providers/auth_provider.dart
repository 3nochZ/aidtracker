import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../services/local_db_service.dart';
import '../core/hash_utils.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  final LocalDbService _dbService = LocalDbService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';

  void updateCurrentUser(AppUser user) {
    _currentUser = user;
    _dbService.getUsersBox().put('current_session', user.toMap());
    notifyListeners();
  }

  void checkAuth() {
    try {
      final usersBox = _dbService.getUsersBox();
      final session = usersBox.get('current_session');
      if (session != null) {
        final rawMap = session is Map ? Map<dynamic, dynamic>.fromEntries(
          session.entries.map((e) => MapEntry(e.key, e.value is Map ? Map<dynamic, dynamic>.from(e.value) : e.value)),
        ) : <dynamic, dynamic>{};
        final user = AppUser.fromMap(rawMap);
        if (user.isActive) {
          _currentUser = user;
          debugPrint("[auth initialized from saved session]");
        } else {
           usersBox.delete('current_session');
        }
      }
    } catch (e) {
      debugPrint("{checkAuth failed}: $e");
    }
  }

  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    // waiting a moment for the spinner
    await Future.delayed(const Duration(milliseconds: 500)); 

    final usersBox = _dbService.getUsersBox();
    
    // clean and lowercase the email to prevent any case-sensitive login bugs
    final cleanEmail = email.trim().toLowerCase();
    final hashedPassword = HashUtils.hashPassword(password);
    
    // 1. try offline local login first (instant check)
    for (var value in usersBox.values) {
      try {
        final rawMap = value is Map ? Map<dynamic, dynamic>.fromEntries(
          value.entries.map((e) => MapEntry(e.key, e.value is Map ? Map<dynamic, dynamic>.from(e.value) : e.value)),
        ) : <dynamic, dynamic>{};
        final user = AppUser.fromMap(rawMap);
        if (user.email.trim().toLowerCase() == cleanEmail && (user.password == password || user.password == hashedPassword)) {
          
          if (!user.isActive) {
            debugPrint("[local auth block: user is suspended]");
            return false; 
          }

          _currentUser = user;
          usersBox.put('current_session', user.toMap());
          notifyListeners();
          debugPrint("(auth success: user found in local database)");
          return true;
        }
      } catch (e) {
        debugPrint("{skipping corrupted user entry during login}: $e");
      }
    }
    
    // 2. try cloud login (for new devices)
    try {
      debugPrint("<user not found locally: checking cloud database>");
      
      // Try with hashed password first
      var querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .where('password', isEqualTo: hashedPassword)
          .limit(1)
          .get();

      // Fallback for plain text
      if (querySnapshot.docs.isEmpty) {
        querySnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: cleanEmail)
            .where('password', isEqualTo: password)
            .limit(1)
            .get();
      }

      debugPrint("(cloud query executed: documents found: ${querySnapshot.docs.length})");

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final rawData = doc.data();
        debugPrint("{raw cloud data retrieved: $rawData}");

        final user = AppUser.fromMap(rawData);

        if (!user.isActive) {
          debugPrint("<cloud auth block: user is suspended globally>");
          return false;
        }

        // cache this user locally for future offline logins if requested
        if (rememberMe) {
          await usersBox.put(user.id, user.toMap());
        }

        _currentUser = user;
        usersBox.put('current_session', user.toMap());
        notifyListeners();
        debugPrint("[cloud auth success: user cached and logged in]");
        return true;
      } else {
        debugPrint("(cloud login failed: no matching document found in firestore)");
      }
    } catch (e, stack) {
      debugPrint("{cloud auth failed with exception}: $e");
      debugPrint("<stacktrace>: $stack");
    }

    return false; 
  }

  void logout() {
    _currentUser = null;
    try {
      _dbService.getUsersBox().delete('current_session');
    } catch (e) {}
    notifyListeners();
  }
}
