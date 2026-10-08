class MiembroEspacio {
  const MiembroEspacio({
    required this.usuarioId,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  final int usuarioId;
  final String nombre;
  final String email;
  final int rol;

  factory MiembroEspacio.fromJson(Map<String, dynamic> json) {
    return MiembroEspacio(
      usuarioId: (json['usuarioId'] as num).toInt(),
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      rol: (json['rol'] as num).toInt(),
    );
  }
}
