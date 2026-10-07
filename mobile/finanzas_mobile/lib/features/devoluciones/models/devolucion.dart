class Devolucion {
  const Devolucion({
    required this.id,
    required this.gastoId,
    required this.gasto,
    required this.valorGasto,
    required this.debeUsuarioId,
    required this.debeUsuario,
    required this.recibeUsuarioId,
    required this.recibeUsuario,
    required this.recibeCuentaId,
    required this.recibeCuenta,
    required this.valor,
    required this.valorPagado,
    required this.pendiente,
    required this.estado,
    required this.fechaPago,
    required this.observacion,
  });

  final int id;
  final int gastoId;
  final String gasto;
  final double valorGasto;
  final int debeUsuarioId;
  final String debeUsuario;
  final int recibeUsuarioId;
  final String recibeUsuario;
  final int? recibeCuentaId;
  final String? recibeCuenta;
  final double valor;
  final double valorPagado;
  final double pendiente;
  final int estado;
  final DateTime? fechaPago;
  final String? observacion;

  String get estadoLabel {
    return switch (estado) {
      1 => 'Pendiente',
      2 => 'Parcial',
      3 => 'Pagada',
      _ => 'Sin estado',
    };
  }

  bool get permitePago => estado == 1 || estado == 2;

  factory Devolucion.fromJson(Map<String, dynamic> json) {
    return Devolucion(
      id: (json['id'] as num).toInt(),
      gastoId: (json['gastoId'] as num).toInt(),
      gasto: json['gasto'] as String,
      valorGasto: (json['valorGasto'] as num).toDouble(),
      debeUsuarioId: (json['debeUsuarioId'] as num).toInt(),
      debeUsuario: json['debeUsuario'] as String,
      recibeUsuarioId: (json['recibeUsuarioId'] as num).toInt(),
      recibeUsuario: json['recibeUsuario'] as String,
      recibeCuentaId: (json['recibeCuentaId'] as num?)?.toInt(),
      recibeCuenta: json['recibeCuenta'] as String?,
      valor: (json['valor'] as num).toDouble(),
      valorPagado: (json['valorPagado'] as num).toDouble(),
      pendiente: (json['pendiente'] as num).toDouble(),
      estado: (json['estado'] as num).toInt(),
      fechaPago: json['fechaPago'] == null
          ? null
          : DateTime.parse(json['fechaPago'] as String),
      observacion: json['observacion'] as String?,
    );
  }
}
