class Vehicle {
  final int? id;
  final String licensePlate;
  final String? brand;
  final String? model;
  final String? color;
  final String? vehicleType;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vehicle({
    this.id,
    required this.licensePlate,
    this.brand,
    this.model,
    this.color,
    this.vehicleType,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'license_plate': licensePlate,
      'brand': brand,
      'model': model,
      'color': color,
      'vehicle_type': vehicleType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'],
      licensePlate: map['license_plate'],
      brand: map['brand'],
      model: map['model'],
      color: map['color'],
      vehicleType: map['vehicle_type'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Vehicle copyWith({
    int? id,
    String? licensePlate,
    String? brand,
    String? model,
    String? color,
    String? vehicleType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      licensePlate: licensePlate ?? this.licensePlate,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      color: color ?? this.color,
      vehicleType: vehicleType ?? this.vehicleType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
