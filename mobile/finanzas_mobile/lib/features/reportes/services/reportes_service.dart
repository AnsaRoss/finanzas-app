import 'dart:convert';

import 'package:finanzas_mobile/core/config/api_config.dart';
import 'package:finanzas_mobile/features/auth/services/session_service.dart';
import 'package:finanzas_mobile/features/reportes/models/resumen_financiero.dart';
import 'package:http/http.dart' as http;

class ReportesException implements Exception {
  const ReportesException(this.message);

  final String message;
}

class ReportesService {
  const ReportesService({
    this.client,
    this.sessionService = const SessionService(),
  });

  final http.Client? client;
  final SessionService sessionService;

  Future<ResumenFinanciero> getResumenMensual({
    required int espacioId,
    required int anio,
    required int mes,
  }) async {
    final session = await sessionService.getSession();
    final token = session?.token;

    if (token == null || token.isEmpty) {
      throw const ReportesException('No hay una sesión activa.');
    }

    final httpClient = client ?? http.Client();

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/Reportes/resumen')
          .replace(
        queryParameters: {
          'espacioId': espacioId.toString(),
          'anio': anio.toString(),
          'mes': mes.toString(),
        },
      );

      final response = await httpClient.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return ResumenFinanciero.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      if (response.statusCode == 401) {
        throw const ReportesException(
          'Tu sesión expiró. Vuelve a iniciar sesión.',
        );
      }

      final responseMessage = response.body.trim();
      if (responseMessage.isNotEmpty) {
        throw ReportesException(responseMessage);
      }

      throw const ReportesException(
        'No se pudo cargar el resumen financiero.',
      );
    } on FormatException {
      throw const ReportesException('La respuesta del resumen no es válida.');
    } on http.ClientException {
      throw const ReportesException(
        'No se pudo conectar con el servidor.',
      );
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }
}
