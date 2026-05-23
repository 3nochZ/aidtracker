class Campaign {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String targetGroup; // matches the beneficiary group
  final String itemId; // ties campaign to an inventory item
  final String itemName;
  final int quota; // amount of items per household
  final String syncStatus;

  Campaign({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.targetGroup,
    required this.itemId,
    required this.itemName,
    required this.quota,
    this.syncStatus = 'pending',
  });

  factory Campaign.fromMap(Map<dynamic, dynamic> map) {
    return Campaign(
      id: map['id'],
      name: map['name'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      targetGroup: map['targetGroup'],
      itemId: map['itemId'],
      itemName: map['itemName'],
      quota: map['quota'],
      syncStatus: map['syncStatus'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'targetGroup': targetGroup,
      'itemId': itemId,
      'itemName': itemName,
      'quota': quota,
      'syncStatus': syncStatus,
    };
  }
}