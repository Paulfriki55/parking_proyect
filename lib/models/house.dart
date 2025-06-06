class House {
  final int? id;
  final String houseNumber;
  final String ownerName;
  final String? ownerPhone;
  final String? ownerEmail;
  final DateTime createdAt;
  final DateTime updatedAt;

  House({
    this.id,
    required this.houseNumber,
    required this.ownerName,
    this.ownerPhone,
    this.ownerEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'house_number': houseNumber,
      'owner_name': ownerName,
      'owner_phone': ownerPhone,
      'owner_email': ownerEmail,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory House.fromMap(Map<String, dynamic> map) {
    return House(
      id: map['id'],
      houseNumber: map['house_number'],
      ownerName: map['owner_name'],
      ownerPhone: map['owner_phone'],
      ownerEmail: map['owner_email'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  House copyWith({
    int? id,
    String? houseNumber,
    String? ownerName,
    String? ownerPhone,
    String? ownerEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return House(
      id: id ?? this.id,
      houseNumber: houseNumber ?? this.houseNumber,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
