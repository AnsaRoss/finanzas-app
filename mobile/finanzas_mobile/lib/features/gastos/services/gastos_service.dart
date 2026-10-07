import 'dart:convert';

import 'package:finanzas_mobile/core/config/api_config.dart';
import 'package:finanzas_mobile/features/auth/services/session_service.dart';
import 'package:finanzas_mobile/features/gastos/models/gasto_variable.dart';
import 'package:http/http.dart' as http;

class GastosException implements Exception {
  const GastosException(this.message);

  final String message;
}

class GastosService {
  const GastosService({
    this.client,
    this.sessionService = const SessionService(),
  });

  final http.Client? client;
  final SessionService sessionService;

  Future<List<GastoVariable>> listarVariables({
    required int espacioId,
    int? anio,
    int? mes,
    int? estado,
  }) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final queryParameters = <String, String>{
        if (anio != null) 'anio': anio.toString(),
        if (mes != null) 'mes': mes.toString(),
        if (estado != null) 'estado': estado.toString(),
      };

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/Gastos/espacio/$espacioId',
      ).replace(queryParameters: queryParameters);

      final response = await httpClient.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List<dynamic>;

        return json
            .map(
              (item) => GastoVariable.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }

      _throwHttpError(response, 'No se pudieron cargar los gastos.');
    } on FormatException {
      throw const GastosException('La respuesta de gastos no es válida.');
    } on http.ClientException {
      throw const GastosException('No se pudo conectar con el servidor.');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<void> registrarVariable({
    required int espacioFinancieroId,
    required int categoriaId,
    required String concepto,
    required double valor,
    required DateTime fecha,
    required int? pagadoPorId,
    required int? cuentaId,
    required bool marcarPagado,
    required int tipoReparto,
    required int responsableId,
    required List<Map<String, Object>> distribucion,
    required String? observacion,
  }) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Gastos/variable'),
        headers: headers,
        body: jsonEncode({
          'espacioFinancieroId': espacioFinancieroId,
          'categoriaId': categoriaId,
          'concepto': concepto,
          'valor': valor,
          'fecha': _formatDate(fecha),
          'pagadoPorId': pagadoPorId,
          'cuentaId': cuentaId,
          'marcarPagado': marcarPagado,
          'tipoReparto': tipoReparto,
          'responsableId': responsableId,
          'distribucion': distribucion,
          'observacion': observacion,
        }),
      );

      _ensureSuccess(response, 'No se pudo registrar el gasto.');
    } on http.ClientException {
      throw const GastosException('No se pudo conectar con el servidor.');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<void> pagarGasto({
    required int gastoId,
    required int pagadoPorId,
    required int? cuentaId,
    required DateTime fechaPago,
  }) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/Gastos/$gastoId/pagar'),
        headers: headers,
        body: jsonEncode({
          'pagadoPorId': pagadoPorId,
          'cuentaId': cuentaId,
          'fechaPago': _formatDate(fechaPago),
        }),
      );

      _ensureSuccess(response, 'No se pudo pagar el gasto.');
    } on http.ClientException {
      throw const GastosException('No se pudo conectar con el servidor.');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<void> anularGasto(int gastoId) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/Gastos/$gastoId/anular'),
        headers: headers,
      );

      _ensureSuccess(response, 'No se pudo anular el gasto.');
    } on http.ClientException {
      throw const GastosException('No se pudo conectar con el servidor.');
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
      throw const GastosException('No hay una sesión activa.');
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
      throw const GastosException('Tu sesión expiró. Vuelve a iniciar sesión.');
    }

    final responseMessage = response.body.trim();
    if (responseMessage.isNotEmpty) {
      throw GastosException(responseMessage);
    }

    throw GastosException(fallbackMessage);
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
