class Visit {
  final int? id;
  final int vehicleId;
  final int houseId;
  final int? zoneId;
  final DateTime entryTime;
  final DateTime? exitTime;
  final String? photoPath;
  final double? amount;
  final bool isPaid;
  final String? notes;
  final String agentName;
  final bool isWeekendParking; // Domingo noche a viernes mañana
  final bool isCommunalParking; // Parqueado en casa comunal
  final DateTime createdAt;
  final DateTime updatedAt;

  // Calculated fields
  Duration? get duration {
    if (exitTime != null) {
      return exitTime!.difference(entryTime);
    }
    return DateTime.now().difference(entryTime);
  }

  bool get isActive => exitTime == null;

  bool get needsAlert {
    if (!isActive) return false;
    final now = DateTime.now();
    final daysDiff = now.difference(entryTime).inDays;
    return daysDiff >= 2 && !isWeekendParking;
  }

  Visit({
    this.id,
    required this.vehicleId,
    required this.houseId,
    this.zoneId,
    required this.entryTime,
    this.exitTime,
    this.photoPath,
    this.amount,
    this.isPaid = false,
    this.notes,
    required this.agentName,
    this.isWeekendParking = false,
    this.isCommunalParking = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'house_id': houseId,
      'zone_id': zoneId,
      'entry_time': entryTime.toIso8601String(),
      'exit_time': exitTime?.toIso8601String(),
      'photo_path': photoPath,
      'amount': amount,
      'is_paid': isPaid ? 1 : 0,
      'notes': notes,
      'agent_name': agentName,
      'is_weekend_parking': isWeekendParking ? 1 : 0,
      'is_communal_parking': isCommunalParking ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Visit.fromMap(Map<String, dynamic> map) {
    return Visit(
      id: map['id'],
      vehicleId: map['vehicle_id'],
      houseId: map['house_id'],
      zoneId: map['zone_id'],
      entryTime: DateTime.parse(map['entry_time']),
      exitTime: map['exit_time'] != null ? DateTime.parse(map['exit_time']) : null,
      photoPath: map['photo_path'],
      amount: map['amount']?.toDouble(),
      isPaid: map['is_paid'] == 1,
      notes: map['notes'],
      agentName: map['agent_name'],
      isWeekendParking: map['is_weekend_parking'] == 1,
      isCommunalParking: map['is_communal_parking'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Visit copyWith({
    int? id,
    int? vehicleId,
    int? houseId,
    int? zoneId,
    DateTime? entryTime,
    DateTime? exitTime,
    String? photoPath,
    double? amount,
    bool? isPaid,
    String? notes,
    String? agentName,
    bool? isWeekendParking,
    bool? isCommunalParking,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Visit(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      houseId: houseId ?? this.houseId,
      zoneId: zoneId ?? this.zoneId,
      entryTime: entryTime ?? this.entryTime,
      exitTime: exitTime ?? this.exitTime,
      photoPath: photoPath ?? this.photoPath,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
      notes: notes ?? this.notes,
      agentName: agentName ?? this.agentName,
      isWeekendParking: isWeekendParking ?? this.isWeekendParking,
      isCommunalParking: isCommunalParking ?? this.isCommunalParking,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
