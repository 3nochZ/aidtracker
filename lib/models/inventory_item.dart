class InventoryItem {
  final String id;
  final String name;
  final String unit;
  final int quantity;
  final int minStockLevel;
  final String syncStatus;
  final String? assignedAgentId;
  final String? allocatedTo;

  InventoryItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.quantity,
    this.minStockLevel = 10,
    this.syncStatus = 'pending',
    this.assignedAgentId,
    this.allocatedTo,
  });

  factory InventoryItem.fromMap(Map<dynamic, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      name: map['name'],
      unit: map['unit'],
      quantity: map['quantity'],
      minStockLevel: map['minStockLevel'] ?? 10,
      syncStatus: map['syncStatus'] ?? 'pending',
      assignedAgentId: map['assignedAgentId'],
      allocatedTo: map['allocatedTo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'quantity': quantity,
      'minStockLevel': minStockLevel,
      'syncStatus': syncStatus,
      'assignedAgentId': assignedAgentId,
      'allocatedTo': allocatedTo,
    };
  }
}