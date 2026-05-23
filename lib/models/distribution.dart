class Distribution {
  final String id;
  final String beneficiaryId;
  final String beneficiaryName; 
  final Map<String, int> items; 
  final String notes;
  final DateTime date;
  final String agentId; // added to track agent performance
  final String agentName; // added to track agent performance
  final String syncStatus;

  Distribution({
    required this.id,
    required this.beneficiaryId,
    required this.beneficiaryName,
    required this.items,
    this.notes = '',
    required this.date,
    required this.agentId,
    required this.agentName,
    this.syncStatus = 'pending',
  });

  factory Distribution.fromMap(Map<dynamic, dynamic> map) {
    return Distribution(
      id: map['id'],
      beneficiaryId: map['beneficiaryId'],
      beneficiaryName: map['beneficiaryName'],
      items: Map<String, int>.from(map['items'] ?? {}),
      notes: map['notes'] ?? '',
      date: DateTime.parse(map['date']),
      agentId: map['agentId'] ?? 'unknown',
      agentName: map['agentName'] ?? 'unknown',
      syncStatus: map['syncStatus'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'beneficiaryId': beneficiaryId,
      'beneficiaryName': beneficiaryName,
      'items': items,
      'notes': notes,
      'date': date.toIso8601String(),
      'agentId': agentId,
      'agentName': agentName,
      'syncStatus': syncStatus,
    };
  }
}