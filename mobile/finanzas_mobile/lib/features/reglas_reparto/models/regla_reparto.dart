class ReglaReparto {
  const ReglaReparto({
    required this.usuarioId,
    required this.usuario,
    required this.porcentaje,
  });

  final int usuarioId;
  final String usuario;
  final double porcentaje;

  factory ReglaReparto.fromJson(Map<String, dynamic> json) {
    return ReglaReparto(
      usuarioId: (json['usuarioId'] as num).toInt(),
      usuario: json['usuario'] as String,
      porcentaje: (json['porcentaje'] as num).toDouble(),
    );
  }
}
