class GastoVariable {
  const GastoVariable({
    required this.id,
    required this.concepto,
    required this.tipo,
    required this.gastoFijoId,
    required this.valor,
    required this.fecha,
    required this.fechaPago,
    required this.estado,
    required this.observacion,
    required this.categoriaId,
    required this.categoria,
    required this.pagadoPorId,
    required this.pagadoPor,
    required this.cuentaId,
    required this.cuenta,
    required this.distribucion,
  });

  final int id;
  final String concepto;
  final int tipo;
  final int? gastoFijoId;
  final double valor;
  final DateTime fecha;
  final DateTime? fechaPago;
  final int estado;
  final String? observacion;
  final int categoriaId;
  final String categoria;
  final int? pagadoPorId;
  final String? pagadoPor;
  final int? cuentaId;
  final String? cuenta;
  final List<DistribucionGasto> distribucion;

  String get estadoLabel {
    return switch (estado) {
      1 => 'Pendiente',
      2 => 'Pagado',
      3 => 'Anulado',
      _ => 'Sin estado',
    };
  }

  String get tipoLabel {
    return switch (tipo) {
      1 => 'Fijo',
      2 => 'Variable',
      _ => 'Sin tipo',
    };
  }

  bool get estaPendiente => estado == 1;
  bool get estaAnulado => estado == 3;

  factory GastoVariable.fromJson(Map<String, dynamic> json) {
    return GastoVariable(
      id: (json['id'] as num).toInt(),
      concepto: json['concepto'] as String,
      tipo: (json['tipo'] as num).toInt(),
      gastoFijoId: (json['gastoFijoId'] as num?)?.toInt(),
      valor: (json['valor'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha'] as String),
      fechaPago: json['fechaPago'] == null
          ? null
          : DateTime.parse(json['fechaPago'] as String),
      estado: (json['estado'] as num).toInt(),
      observacion: json['observacion'] as String?,
      categoriaId: (json['categoriaId'] as num).toInt(),
      categoria: json['categoria'] as String,
      pagadoPorId: (json['pagadoPorId'] as num?)?.toInt(),
      pagadoPor: json['pagadoPor'] as String?,
      cuentaId: (json['cuentaId'] as num?)?.toInt(),
      cuenta: json['cuenta'] as String?,
      distribucion: ((json['distribucion'] as List<dynamic>?) ?? [])
          .map(
            (item) => DistribucionGasto.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class DistribucionGasto {
  const DistribucionGasto({
    required this.usuarioId,
    required this.usuario,
    required this.porcentaje,
    required this.valor,
  });

  final int usuarioId;
  final String usuario;
  final double porcentaje;
  final double valor;

  factory DistribucionGasto.fromJson(Map<String, dynamic> json) {
    return DistribucionGasto(
      usuarioId: (json['usuarioId'] as num).toInt(),
      usuario: json['usuario'] as String,
      porcentaje: (json['porcentaje'] as num).toDouble(),
      valor: (json['valor'] as num).toDouble(),
    );
  }
}
