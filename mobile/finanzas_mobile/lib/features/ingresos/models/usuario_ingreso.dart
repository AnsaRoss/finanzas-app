class UsuarioIngreso {
  const UsuarioIngreso({
    required this.usuarioId,
    required this.usuario,
    this.porcentaje = 0,
  });

  final int usuarioId;
  final String usuario;
  final double porcentaje;

  factory UsuarioIngreso.fromJson(Map<String, dynamic> json) {
    return UsuarioIngreso(
      usuarioId: (json['usuarioId'] as num).toInt(),
      usuario: json['usuario'] as String,
      porcentaje: (json['porcentaje'] as num?)?.toDouble() ?? 0,
    );
  }
}
