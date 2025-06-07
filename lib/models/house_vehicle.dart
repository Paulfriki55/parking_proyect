class HouseVehicle {
  final int? id;
  final int houseId;
  final int vehicleId;
  final bool isOwnerVehicle; // true = propietario, false = visita
  final DateTime registeredAt;
  final DateTime? removedAt;
  final bool isActive;

  HouseVehicle({
    this.id,
    required this.houseId,
    required this.vehicleId,
    this.isOwnerVehicle = false,
    required this.registeredAt,
    this.removedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'house_id': houseId,
      'vehicle_id': vehicleId,
      'is_owner_vehicle': isOwnerVehicle ? 1 : 0,
      'registered_at': registeredAt.toIso8601String(),
      'removed_at': removedAt?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory HouseVehicle.fromMap(Map<String, dynamic> map) {
    return HouseVehicle(
      id: map['id'],
      houseId: map['house_id'],
      vehicleId: map['vehicle_id'],
      isOwnerVehicle: map['is_owner_vehicle'] == 1,
      registeredAt: DateTime.parse(map['registered_at']),
      removedAt: map['removed_at'] != null ? DateTime.parse(map['removed_at']) : null,
      isActive: map['is_active'] == 1,
    );
  }
}
