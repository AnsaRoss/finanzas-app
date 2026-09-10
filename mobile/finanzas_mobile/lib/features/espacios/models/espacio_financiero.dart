class EspacioFinanciero {
  const EspacioFinanciero({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.rol,
  });

  final int id;
  final String nombre;
  final Object? tipo;
  final Object? rol;

  bool get esHogar => tipo == 2;

  String get tipoLabel {
    return switch (tipo) {
      1 => 'Personal',
      2 => 'Hogar',
      final String value => value,
      _ => 'Sin tipo',
    };
  }

  factory EspacioFinanciero.fromJson(Map<String, dynamic> json) {
    return EspacioFinanciero(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String,
      tipo: json['tipo'],
      rol: json['rol'],
    );
  }
}
