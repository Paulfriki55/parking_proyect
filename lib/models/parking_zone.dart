enum ZoneType {
  visitor, // Zonas 1-9
  overflow, // Zona 10
  communal, // Casa comunal
}

class ParkingZone {
  final int? id;
  final int zoneNumber;
  final ZoneType type;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ParkingZone({
    this.id,
    required this.zoneNumber,
    required this.type,
    required this.name,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_number': zoneNumber,
      'type': type.name,
      'name': name,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ParkingZone.fromMap(Map<String, dynamic> map) {
    return ParkingZone(
      id: map['id'],
      zoneNumber: map['zone_number'],
      type: ZoneType.values.firstWhere((e) => e.name == map['type']),
      name: map['name'],
      description: map['description'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
