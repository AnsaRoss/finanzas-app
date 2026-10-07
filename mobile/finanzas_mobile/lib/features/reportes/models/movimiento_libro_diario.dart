class MovimientoLibroDiario {
  const MovimientoLibroDiario({
    required this.id,
    required this.fecha,
    required this.tipo,
    required this.concepto,
    required this.ingreso,
    required this.gasto,
    required this.estado,
    required this.persona,
    required this.categoria,
    required this.cuenta,
    required this.observacion,
  });

  final int id;
  final DateTime fecha;
  final String tipo;
  final String concepto;
  final double ingreso;
  final double gasto;
  final int? estado;
  final String? persona;
  final String? categoria;
  final String? cuenta;
  final String? observacion;

  String get tipoLabel {
    return switch (tipo) {
      'GASTO_FIJO' => 'Gasto fijo',
      'GASTO_VARIABLE' => 'Gasto variable',
      'INGRESO' => 'Ingreso',
      _ => tipo,
    };
  }

  bool get esIngreso => ingreso > 0;

  factory MovimientoLibroDiario.fromJson(Map<String, dynamic> json) {
    return MovimientoLibroDiario(
      id: (json['id'] as num).toInt(),
      fecha: DateTime.parse(json['fecha'] as String),
      tipo: json['tipo'] as String,
      concepto: json['concepto'] as String,
      ingreso: (json['ingreso'] as num).toDouble(),
      gasto: (json['gasto'] as num).toDouble(),
      estado: (json['estado'] as num?)?.toInt(),
      persona: json['persona'] as String?,
      categoria: json['categoria'] as String?,
      cuenta: json['cuenta'] as String?,
      observacion: json['observacion'] as String?,
    );
  }
}
