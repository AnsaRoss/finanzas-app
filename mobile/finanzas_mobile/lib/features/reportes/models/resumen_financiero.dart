class ResumenFinanciero {
  const ResumenFinanciero({
    required this.espacioFinancieroId,
    required this.anio,
    required this.mes,
    required this.totalIngresos,
    required this.totalGastos,
    required this.saldo,
    required this.gastosPagados,
    required this.gastosPendientes,
    required this.gastosFijos,
    required this.gastosVariables,
    required this.devolucionesPendientes,
  });

  final int espacioFinancieroId;
  final int anio;
  final int mes;
  final double totalIngresos;
  final double totalGastos;
  final double saldo;
  final double gastosPagados;
  final double gastosPendientes;
  final double gastosFijos;
  final double gastosVariables;
  final double devolucionesPendientes;

  factory ResumenFinanciero.fromJson(Map<String, dynamic> json) {
    return ResumenFinanciero(
      espacioFinancieroId: (json['espacioFinancieroId'] as num).toInt(),
      anio: (json['anio'] as num).toInt(),
      mes: (json['mes'] as num).toInt(),
      totalIngresos: (json['totalIngresos'] as num).toDouble(),
      totalGastos: (json['totalGastos'] as num).toDouble(),
      saldo: (json['saldo'] as num).toDouble(),
      gastosPagados: (json['gastosPagados'] as num).toDouble(),
      gastosPendientes: (json['gastosPendientes'] as num).toDouble(),
      gastosFijos: (json['gastosFijos'] as num).toDouble(),
      gastosVariables: (json['gastosVariables'] as num).toDouble(),
      devolucionesPendientes:
          (json['devolucionesPendientes'] as num).toDouble(),
    );
  }
}
