import 'dart:convert';

import 'package:finanzas_mobile/core/config/api_config.dart';
import 'package:finanzas_mobile/features/auth/services/session_service.dart';
import 'package:finanzas_mobile/features/ingresos/models/categoria_ingreso.dart';
import 'package:finanzas_mobile/features/ingresos/models/cuenta_ingreso.dart';
import 'package:finanzas_mobile/features/ingresos/models/usuario_ingreso.dart';
import 'package:http/http.dart' as http;

class IngresosCatalogosException implements Exception {
  const IngresosCatalogosException(this.message);

  final String message;
}

class IngresosCatalogosService {
  const IngresosCatalogosService({
    this.client,
    this.sessionService = const SessionService(),
  });

  final http.Client? client;
  final SessionService sessionService;

  Future<List<UsuarioIngreso>> listarUsuariosHogar(int espacioId) async {
    final response = await _get('/api/ReglasReparto/espacio/$espacioId');
    final json = jsonDecode(response.body) as List<dynamic>;

    return json
        .map((item) => UsuarioIngreso.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<CategoriaIngreso>> listarCategoriasIngreso(int espacioId) async {
    final response = await _get('/api/Categorias/espacio/$espacioId');
    final json = jsonDecode(response.body) as List<dynamic>;

    return json
        .map((item) => CategoriaIngreso.fromJson(item as Map<String, dynamic>))
        .where((categoria) => categoria.esIngreso)
        .toList();
  }

  Future<List<CategoriaIngreso>> listarCategoriasGasto(int espacioId) async {
    final response = await _get('/api/Categorias/espacio/$espacioId');
    final json = jsonDecode(response.body) as List<dynamic>;

    return json
        .map((item) => CategoriaIngreso.fromJson(item as Map<String, dynamic>))
        .where((categoria) => categoria.tipo == 2)
        .toList();
  }

  Future<List<CuentaIngreso>> listarCuentas(int espacioId) async {
    final response = await _get('/api/Cuentas/espacio/$espacioId');
    final json = jsonDecode(response.body) as List<dynamic>;

    return json
        .map((item) => CuentaIngreso.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<http.Response> _get(String path) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }

      _throwHttpError(response, 'No se pudieron cargar los catálogos.');
    } on FormatException {
      throw const IngresosCatalogosException(
        'La respuesta de catálogos no es válida.',
      );
    } on http.ClientException {
      throw const IngresosCatalogosException(
        'No se pudo conectar con el servidor.',
      );
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final session = await sessionService.getSession();
    final token = session?.token;

    if (token == null || token.isEmpty) {
      throw const IngresosCatalogosException('No hay una sesión activa.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Never _throwHttpError(http.Response response, String fallbackMessage) {
    if (response.statusCode == 401) {
      throw const IngresosCatalogosException(
        'Tu sesión expiró. Vuelve a iniciar sesión.',
      );
    }

    final responseMessage = response.body.trim();
    if (responseMessage.isNotEmpty) {
      throw IngresosCatalogosException(responseMessage);
    }

    throw IngresosCatalogosException(fallbackMessage);
  }
}
