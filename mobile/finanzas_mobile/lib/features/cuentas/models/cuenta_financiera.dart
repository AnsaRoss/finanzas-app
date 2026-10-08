class CuentaFinanciera {
  const CuentaFinanciera({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.propietarioId,
    required this.propietario,
    required this.entidadFinancieraId,
    required this.entidadFinanciera,
  });

  final int id;
  final String nombre;
  final int tipo;
  final int propietarioId;
  final String propietario;
  final int? entidadFinancieraId;
  final String? entidadFinanciera;

  String get tipoLabel {
    return switch (tipo) {
      1 => 'Efectivo',
      2 => 'Ahorros',
      3 => 'Corriente',
      4 => 'Tarjeta de crédito',
      5 => 'Otro',
      _ => 'Sin tipo',
    };
  }

  factory CuentaFinanciera.fromJson(Map<String, dynamic> json) {
    return CuentaFinanciera(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String,
      tipo: (json['tipo'] as num).toInt(),
      propietarioId: (json['propietarioId'] as num).toInt(),
      propietario: json['propietario'] as String,
      entidadFinancieraId: (json['entidadFinancieraId'] as num?)?.toInt(),
      entidadFinanciera: json['entidadFinanciera'] as String?,
    );
  }
}
