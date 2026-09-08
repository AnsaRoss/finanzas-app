import 'package:finanzas_mobile/features/auth/models/login_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  const SessionService();

  static const _usuarioIdKey = 'auth_usuario_id';
  static const _nombreKey = 'auth_nombre';
  static const _emailKey = 'auth_email';
  static const _tokenKey = 'auth_token';

  Future<void> saveSession(LoginResponse session) async {
    final preferences = SharedPreferencesAsync();

    await preferences.setInt(_usuarioIdKey, session.usuarioId);
    await preferences.setString(_nombreKey, session.nombre);
    await preferences.setString(_emailKey, session.email);
    await preferences.setString(_tokenKey, session.token);
  }

  Future<LoginResponse?> getSession() async {
    final preferences = SharedPreferencesAsync();

    final usuarioId = await preferences.getInt(_usuarioIdKey);
    final nombre = await preferences.getString(_nombreKey);
    final email = await preferences.getString(_emailKey);
    final token = await preferences.getString(_tokenKey);

    if (usuarioId == null || nombre == null || email == null || token == null) {
      return null;
    }

    return LoginResponse(
      usuarioId: usuarioId,
      nombre: nombre,
      email: email,
      token: token,
    );
  }

  Future<void> clearSession() async {
    final preferences = SharedPreferencesAsync();

    await preferences.remove(_usuarioIdKey);
    await preferences.remove(_nombreKey);
    await preferences.remove(_emailKey);
    await preferences.remove(_tokenKey);
  }
}
