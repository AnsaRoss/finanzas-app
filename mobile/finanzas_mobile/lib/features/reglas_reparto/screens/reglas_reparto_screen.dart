import 'package:finanzas_mobile/features/espacios/models/espacio_financiero.dart';
import 'package:finanzas_mobile/features/espacios/models/miembro_espacio.dart';
import 'package:finanzas_mobile/features/espacios/services/espacios_service.dart';
import 'package:finanzas_mobile/features/reglas_reparto/models/regla_reparto.dart';
import 'package:finanzas_mobile/features/reglas_reparto/services/reglas_reparto_service.dart';
import 'package:flutter/material.dart';

class ReglasRepartoScreen extends StatefulWidget {
  const ReglasRepartoScreen({
    required this.espacio,
    super.key,
  });

  final EspacioFinanciero espacio;

  @override
  State<ReglasRepartoScreen> createState() => _ReglasRepartoScreenState();
}

class _ReglasRepartoScreenState extends State<ReglasRepartoScreen> {
  final _reglasService = const ReglasRepartoService();
  final _espaciosService = const EspaciosService();
  late Future<_ReglasRepartoData> _reglasFuture;
  final Map<int, TextEditingController> _porcentajeControllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _reglasFuture = _loadReglas();
  }

  @override
  void dispose() {
    for (final controller in _porcentajeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<_ReglasRepartoData> _loadReglas() async {
    final miembros = await _espaciosService.listarMiembros(widget.espacio.id);
    final reglas = await _reglasService.listarPorEspacio(widget.espacio.id);
    final reglasPorUsuario = {
      for (final regla in reglas) regla.usuarioId: regla,
    };

    for (final miembro in miembros) {
      final porcentaje = reglasPorUsuario[miembro.usuarioId]?.porcentaje ?? 0;
      final controller = _porcentajeControllers.putIfAbsent(
        miembro.usuarioId,
        () => TextEditingController(),
      );
      controller.text = _formatPercentage(porcentaje);
    }

    return _ReglasRepartoData(
      miembros: miembros,
      reglas: reglas,
    );
  }

  void _refreshReglas() {
    setState(() {
      _reglasFuture = _loadReglas();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatPercentage(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  Future<void> _guardar(List<MiembroEspacio> miembros) async {
    if (_isSaving) {
      return;
    }

    if (miembros.isEmpty) {
      _showMessage('No existen miembros para configurar.');
      return;
    }

    final distribuciones = <ReglaRepartoUpdate>[];
    var total = 0.0;

    for (final miembro in miembros) {
      final text =
          _porcentajeControllers[miembro.usuarioId]?.text.trim() ?? '';
      final porcentaje = double.tryParse(text);

      if (porcentaje == null || porcentaje <= 0 || porcentaje > 100) {
        _showMessage('Cada porcentaje debe ser mayor a 0 y máximo 100.');
        return;
      }

      total += porcentaje;
      distribuciones.add(
        ReglaRepartoUpdate(
          usuarioId: miembro.usuarioId,
          porcentaje: porcentaje,
        ),
      );
    }

    if ((total - 100).abs() > 0.0001) {
      _showMessage('La suma total debe ser exactamente 100%.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _reglasService.guardar(
        espacioId: widget.espacio.id,
        distribuciones: distribuciones,
      );

      if (!mounted) {
        return;
      }

      _showMessage('Reglas de reparto guardadas correctamente.');
      setState(() {
        _isSaving = false;
        _reglasFuture = _loadReglas();
      });
    } on ReglasRepartoException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });
      _showMessage('No se pudieron guardar las reglas de reparto.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reglas de reparto'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                children: [
                  Text(
                    widget.espacio.nombre,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Porcentajes de reparto para gastos del espacio.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder<_ReglasRepartoData>(
                    future: _reglasFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return _ErrorState(
                          message:
                              'No se pudieron cargar las reglas de reparto.',
                          onRetry: _refreshReglas,
                        );
                      }

                      final data = snapshot.data;
                      final miembros = data?.miembros ?? [];
                      final reglas = data?.reglas ?? [];
                      if (miembros.isEmpty) {
                        return Text(
                          'No existen miembros para configurar.',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Miembros del hogar',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...miembros.map(
                            (miembro) => Card(
                              child: ListTile(
                                title: Text(miembro.nombre),
                                subtitle: Text(miembro.email),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            reglas.isEmpty
                                ? 'Configura los porcentajes iniciales'
                                : 'Porcentajes configurados',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...miembros.map(
                            (miembro) => Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      miembro.nombre,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _porcentajeControllers[
                                          miembro.usuarioId],
                                      enabled: !_isSaving,
                                      decoration: const InputDecoration(
                                        labelText: 'Porcentaje',
                                        suffixText: '%',
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed:
                                  _isSaving ? null : () => _guardar(miembros),
                              child: _isSaving
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Guardar'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReglasRepartoData {
  const _ReglasRepartoData({
    required this.miembros,
    required this.reglas,
  });

  final List<MiembroEspacio> miembros;
  final List<ReglaReparto> reglas;
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          message,
          style: TextStyle(color: colorScheme.error),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ),
      ],
    );
  }
}
