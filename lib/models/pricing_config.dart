class PricingConfig {
  final int? id;
  final double hourlyRate;
  final double dailyRate; // Tarifa por día (24 horas)
  final int freeMinutes;
  final double minimumCharge;
  final double maximumCharge;
  final DateTime createdAt;
  final DateTime updatedAt;

  PricingConfig({
    this.id,
    required this.hourlyRate,
    required this.dailyRate,
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
      'daily_rate': dailyRate,
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
      dailyRate: map['daily_rate'].toDouble(),
      freeMinutes: map['free_minutes'],
      minimumCharge: map['minimum_charge'].toDouble(),
      maximumCharge: map['maximum_charge'].toDouble(),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  double calculateAmount(Duration duration) {
    final totalMinutes = duration.inMinutes;
    
    // Si está dentro del tiempo gratis, no se cobra
    if (totalMinutes <= freeMinutes) {
      return 0.0;
    }
    
    final chargeableMinutes = totalMinutes - freeMinutes;
    final totalHours = chargeableMinutes / 60.0;
    final totalDays = totalHours / 24.0;
    
    double amount = 0.0;
    
    // Si es menos de 24 horas, cobrar por horas
    if (totalHours < 24) {
      amount = totalHours * hourlyRate;
    } 
    // Si es 24 horas o más, cobrar por días completos + horas restantes
    else {
      final completeDays = totalHours ~/ 24; // Días completos
      final remainingHours = totalHours % 24; // Horas restantes
      
      amount = (completeDays * dailyRate) + (remainingHours * hourlyRate);
    }
    
    // Aplicar mínimo y máximo
    if (amount < minimumCharge) {
      amount = minimumCharge;
    } else if (amount > maximumCharge) {
      amount = maximumCharge;
    }
    
    return amount;
  }

  // Método para obtener detalles del cálculo
  Map<String, dynamic> getCalculationDetails(Duration duration) {
    final totalMinutes = duration.inMinutes;
    
    if (totalMinutes <= freeMinutes) {
      return {
        'isFree': true,
        'freeMinutes': freeMinutes,
        'totalMinutes': totalMinutes,
        'amount': 0.0,
        'description': 'Tiempo gratuito'
      };
    }
    
    final chargeableMinutes = totalMinutes - freeMinutes;
    final totalHours = chargeableMinutes / 60.0;
    
    if (totalHours < 24) {
      final amount = totalHours * hourlyRate;
      return {
        'isFree': false,
        'totalHours': totalHours,
        'hourlyRate': hourlyRate,
        'amount': amount,
        'description': 'Cobro por ${totalHours.toStringAsFixed(1)} horas'
      };
    } else {
      final completeDays = totalHours ~/ 24;
      final remainingHours = totalHours % 24;
      final dayAmount = completeDays * dailyRate;
      final hourAmount = remainingHours * hourlyRate;
      final totalAmount = dayAmount + hourAmount;
      
      return {
        'isFree': false,
        'completeDays': completeDays,
        'remainingHours': remainingHours,
        'dailyRate': dailyRate,
        'hourlyRate': hourlyRate,
        'dayAmount': dayAmount,
        'hourAmount': hourAmount,
        'amount': totalAmount,
        'description': '$completeDays día(s) + ${remainingHours.toStringAsFixed(1)} horas'
      };
    }
  }
}
