class EditRequest {
  final String id;
  final String distributionId;
  final String agentId;
  final String agentName;
  final String reason;
  final String status; // pending, approved, denied
  final DateTime createdAt;
  final String syncStatus;

  EditRequest({
    required this.id,
    required this.distributionId,
    required this.agentId,
    required this.agentName,
    required this.reason,
    this.status = 'pending',
    required this.createdAt,
    this.syncStatus = 'pending',
  });

  factory EditRequest.fromMap(Map<dynamic, dynamic> map) {
    return EditRequest(
      id: map['id'],
      distributionId: map['distributionId'],
      agentId: map['agentId'],
      agentName: map['agentName'],
      reason: map['reason'],
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['createdAt']),
      syncStatus: map['syncStatus'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'distributionId': distributionId,
      'agentId': agentId,
      'agentName': agentName,
      'reason': reason,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'syncStatus': syncStatus,
    };
  }
}