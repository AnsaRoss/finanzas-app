class GastoFijo {
  const GastoFijo({
    required this.id,
    required this.concepto,
    required this.valorEstimado,
    required this.diaVencimiento,
    required this.categoriaId,
    required this.categoria,
    required this.activo,
  });

  final int id;
  final String concepto;
  final double valorEstimado;
  final int diaVencimiento;
  final int categoriaId;
  final String categoria;
  final bool activo;

  String get estadoLabel => activo ? 'Activo' : 'Inactivo';

  factory GastoFijo.fromJson(Map<String, dynamic> json) {
    return GastoFijo(
      id: (json['id'] as num).toInt(),
      concepto: json['concepto'] as String,
      valorEstimado: (json['valorEstimado'] as num).toDouble(),
      diaVencimiento: (json['diaVencimiento'] as num).toInt(),
      categoriaId: (json['categoriaId'] as num).toInt(),
      categoria: json['categoria'] as String,
      activo: json['activo'] as bool,
    );
  }
}
