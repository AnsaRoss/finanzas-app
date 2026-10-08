class EntidadFinanciera {
  const EntidadFinanciera({
    required this.id,
    required this.nombre,
  });

  final int id;
  final String nombre;

  factory EntidadFinanciera.fromJson(Map<String, dynamic> json) {
    return EntidadFinanciera(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String,
    );
  }
}
