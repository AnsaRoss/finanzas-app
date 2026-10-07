class UsuarioIngreso {
  const UsuarioIngreso({
    required this.usuarioId,
    required this.usuario,
  });

  final int usuarioId;
  final String usuario;

  factory UsuarioIngreso.fromJson(Map<String, dynamic> json) {
    return UsuarioIngreso(
      usuarioId: (json['usuarioId'] as num).toInt(),
      usuario: json['usuario'] as String,
    );
  }
}
