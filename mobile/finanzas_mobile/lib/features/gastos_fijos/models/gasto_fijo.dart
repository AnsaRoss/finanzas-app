class GastoFijo {
  const GastoFijo({
    required this.id,
    required this.concepto,
    required this.valorEstimado,
    required this.diaVencimiento,
    required this.categoriaId,
    required this.categoria,
    required this.activo,
    required this.tipoReparto,
    required this.responsableId,
    required this.responsable,
    required this.distribucion,
  });

  final int id;
  final String concepto;
  final double valorEstimado;
  final int diaVencimiento;
  final int categoriaId;
  final String categoria;
  final bool activo;
  final int tipoReparto;
  final int? responsableId;
  final String? responsable;
  final List<DistribucionGastoFijo> distribucion;

  String get estadoLabel => activo ? 'Activo' : 'Inactivo';

  String get tipoRepartoLabel {
    return switch (tipoReparto) {
      1 => 'Regla del hogar',
      2 => 'Individual',
      3 => 'Personalizado',
      _ => 'Sin reparto',
    };
  }

  factory GastoFijo.fromJson(Map<String, dynamic> json) {
    return GastoFijo(
      id: (json['id'] as num).toInt(),
      concepto: json['concepto'] as String,
      valorEstimado: (json['valorEstimado'] as num).toDouble(),
      diaVencimiento: (json['diaVencimiento'] as num).toInt(),
      categoriaId: (json['categoriaId'] as num).toInt(),
      categoria: json['categoria'] as String,
      activo: json['activo'] as bool,
      tipoReparto: (json['tipoReparto'] as num?)?.toInt() ?? 1,
      responsableId: (json['responsableId'] as num?)?.toInt(),
      responsable: json['responsable'] as String?,
      distribucion: ((json['distribucion'] as List<dynamic>?) ?? [])
          .map(
            (item) => DistribucionGastoFijo.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class DistribucionGastoFijo {
  const DistribucionGastoFijo({
    required this.usuarioId,
    required this.porcentaje,
  });

  final int usuarioId;
  final double porcentaje;

  factory DistribucionGastoFijo.fromJson(Map<String, dynamic> json) {
    return DistribucionGastoFijo(
      usuarioId: (json['usuarioId'] as num).toInt(),
      porcentaje: (json['porcentaje'] as num).toDouble(),
    );
  }
}
