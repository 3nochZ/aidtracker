class Beneficiary {
  final String id;
  final String name;
  final String location;
  final int householdSize;
  final String group; // e.g. general, elderly, vulnerable
  final String status; // pending, approved
  final String syncStatus;
  final String? assignedAgentId;
  final String? registeredByAgentId; // tracks who created this record (null = admin/system)
  final String? registeredByAgentName; // human-readable name for display

  Beneficiary({
    required this.id,
    required this.name,
    required this.location,
    required this.householdSize,
    this.group = 'General',
    this.status = 'approved',
    this.syncStatus = 'pending',
    this.assignedAgentId,
    this.registeredByAgentId,
    this.registeredByAgentName,
  });

  factory Beneficiary.fromMap(Map<dynamic, dynamic> map) {
    return Beneficiary(
      id: map['id'],
      name: map['name'],
      location: map['location'],
      householdSize: map['householdSize'],
      group: map['group'] ?? 'General',
      status: map['status'] ?? 'approved',
      syncStatus: map['syncStatus'] ?? 'pending',
      assignedAgentId: map['assignedAgentId'],
      registeredByAgentId: map['registeredByAgentId'],
      registeredByAgentName: map['registeredByAgentName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'householdSize': householdSize,
      'group': group,
      'status': status,
      'syncStatus': syncStatus,
      'assignedAgentId': assignedAgentId,
      'registeredByAgentId': registeredByAgentId,
      'registeredByAgentName': registeredByAgentName,
    };
  }
}