class VehicleColors {
  static const List<String> colors = [
    'Blanco',
    'Negro',
    'Gris',
    'Plata',
    'Rojo',
    'Azul',
    'Verde',
    'Amarillo',
    'Naranja',
    'Morado',
    'Café',
    'Beige',
    'Dorado',
    'Rosa',
    'Turquesa',
    'Vino Tinto',
    'Otro',
  ];

  static String getColorName(String color) {
    return colors.contains(color) ? color : 'Otro';
  }
}
