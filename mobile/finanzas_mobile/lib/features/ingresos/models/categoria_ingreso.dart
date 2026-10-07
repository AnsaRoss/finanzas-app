class CategoriaIngreso {
  const CategoriaIngreso({
    required this.id,
    required this.nombre,
    required this.tipo,
  });

  final int id;
  final String nombre;
  final int tipo;

  bool get esIngreso => tipo == 1;

  factory CategoriaIngreso.fromJson(Map<String, dynamic> json) {
    return CategoriaIngreso(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String,
      tipo: (json['tipo'] as num).toInt(),
    );
  }
}
