import 'dart:convert';

import 'package:finanzas_mobile/core/config/api_config.dart';
import 'package:finanzas_mobile/features/auth/services/session_service.dart';
import 'package:finanzas_mobile/features/cuentas/models/cuenta_financiera.dart';
import 'package:finanzas_mobile/features/cuentas/models/entidad_financiera.dart';
import 'package:http/http.dart' as http;

class CuentasException implements Exception {
  const CuentasException(this.message);

  final String message;
}

class CuentasService {
  const CuentasService({
    this.client,
    this.sessionService = const SessionService(),
  });

  final http.Client? client;
  final SessionService sessionService;

  Future<List<CuentaFinanciera>> listarPorEspacio(int espacioId) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Cuentas/espacio/$espacioId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List<dynamic>;

        return json
            .map((item) => CuentaFinanciera.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      _throwHttpError(response, 'No se pudieron cargar las cuentas.');
    } on FormatException {
      throw const CuentasException('La respuesta de cuentas no es válida.');
    } on http.ClientException {
      throw const CuentasException('No se pudo conectar con el servidor.');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<void> crearCuenta({
    required int espacioFinancieroId,
    required int propietarioId,
    required int? entidadFinancieraId,
    required String nombre,
    required int tipo,
  }) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Cuentas'),
        headers: headers,
        body: jsonEncode({
          'espacioFinancieroId': espacioFinancieroId,
          'propietarioId': propietarioId,
          'entidadFinancieraId': entidadFinancieraId,
          'nombre': nombre,
          'tipo': tipo,
        }),
      );

      _ensureSuccess(response, 'No se pudo crear la cuenta.');
    } on http.ClientException {
      throw const CuentasException('No se pudo conectar con el servidor.');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<List<EntidadFinanciera>> listarEntidadesFinancieras() async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}/api/EntidadesFinancieras'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List<dynamic>;

        return json
            .map((item) => EntidadFinanciera.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      _throwHttpError(
        response,
        'No se pudieron cargar las entidades financieras.',
      );
    } on FormatException {
      throw const CuentasException(
        'La respuesta de entidades financieras no es válida.',
      );
    } on http.ClientException {
      throw const CuentasException('No se pudo conectar con el servidor.');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<void> crearEntidadFinanciera(String nombre) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/api/EntidadesFinancieras'),
        headers: headers,
        body: jsonEncode({'nombre': nombre}),
      );

      _ensureSuccess(response, 'No se pudo crear la entidad financiera.');
    } on http.ClientException {
      throw const CuentasException('No se pudo conectar con el servidor.');
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
      throw const CuentasException('No hay una sesión activa.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  void _ensureSuccess(http.Response response, String fallbackMessage) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    _throwHttpError(response, fallbackMessage);
  }

  Never _throwHttpError(http.Response response, String fallbackMessage) {
    if (response.statusCode == 401) {
      throw const CuentasException('Tu sesión expiró. Vuelve a iniciar sesión.');
    }

    final responseMessage = response.body.trim();
    if (responseMessage.isNotEmpty) {
      throw CuentasException(responseMessage);
    }

    throw CuentasException(fallbackMessage);
  }
}
