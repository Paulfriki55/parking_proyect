class PricingConfig {
  final int? id;
  final double hourlyRate;
  final int freeMinutes;
  final double minimumCharge;
  final double maximumCharge;
  final DateTime createdAt;
  final DateTime updatedAt;

  PricingConfig({
    this.id,
    required this.hourlyRate,
    this.freeMinutes = 15,
    required this.minimumCharge,
    required this.maximumCharge,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hourly_rate': hourlyRate,
      'free_minutes': freeMinutes,
      'minimum_charge': minimumCharge,
      'maximum_charge': maximumCharge,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PricingConfig.fromMap(Map<String, dynamic> map) {
    return PricingConfig(
      id: map['id'],
      hourlyRate: map['hourly_rate'].toDouble(),
      freeMinutes: map['free_minutes'],
      minimumCharge: map['minimum_charge'].toDouble(),
      maximumCharge: map['maximum_charge'].toDouble(),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  double calculateAmount(Duration duration) {
    final totalMinutes = duration.inMinutes;

    if (totalMinutes <= freeMinutes) {
      return 0.0;
    }

    final chargeableMinutes = totalMinutes - freeMinutes;
    final hours = chargeableMinutes / 60.0;
    double amount = hours * hourlyRate;

    if (amount < minimumCharge) {
      amount = minimumCharge;
    } else if (amount > maximumCharge) {
      amount = maximumCharge;
    }

    return amount;
  }
}
