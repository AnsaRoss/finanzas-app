class Ingreso {
  const Ingreso({
    required this.id,
    required this.concepto,
    required this.valor,
    required this.fecha,
    required this.observacion,
    required this.usuarioId,
    required this.usuario,
    required this.categoriaId,
    required this.categoria,
    required this.cuentaId,
    required this.cuenta,
  });

  final int id;
  final String concepto;
  final double valor;
  final DateTime fecha;
  final String? observacion;
  final int usuarioId;
  final String usuario;
  final int categoriaId;
  final String categoria;
  final int? cuentaId;
  final String? cuenta;

  factory Ingreso.fromJson(Map<String, dynamic> json) {
    return Ingreso(
      id: (json['id'] as num).toInt(),
      concepto: json['concepto'] as String,
      valor: (json['valor'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha'] as String),
      observacion: json['observacion'] as String?,
      usuarioId: (json['usuarioId'] as num).toInt(),
      usuario: json['usuario'] as String,
      categoriaId: (json['categoriaId'] as num).toInt(),
      categoria: json['categoria'] as String,
      cuentaId: (json['cuentaId'] as num?)?.toInt(),
      cuenta: json['cuenta'] as String?,
    );
  }
}
