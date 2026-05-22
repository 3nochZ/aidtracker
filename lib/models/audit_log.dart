class AuditLog {
  final String id;
  final String action; 
  final String details; 
  final String userId;
  final String userName;
  final DateTime timestamp;
  final String syncStatus;

  AuditLog({
    required this.id,
    required this.action,
    required this.details,
    required this.userId,
    required this.userName,
    required this.timestamp,
    this.syncStatus = 'pending',
  });

  factory AuditLog.fromMap(Map<dynamic, dynamic> map) {
    return AuditLog(
      id: map['id'],
      action: map['action'],
      details: map['details'],
      userId: map['userId'],
      userName: map['userName'],
      timestamp: DateTime.parse(map['timestamp']),
      syncStatus: map['syncStatus'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'details': details,
      'userId': userId,
      'userName': userName,
      'timestamp': timestamp.toIso8601String(),
      'syncStatus': syncStatus,
    };
  }
}