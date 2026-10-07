import 'package:finanzas_mobile/features/espacios/models/espacio_financiero.dart';
import 'package:finanzas_mobile/features/reportes/models/movimiento_libro_diario.dart';
import 'package:finanzas_mobile/features/reportes/services/libro_diario_service.dart';
import 'package:flutter/material.dart';

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({
    required this.espacio,
    super.key,
  });

  final EspacioFinanciero espacio;

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  final _libroDiarioService = const LibroDiarioService();
  late int _anio;
  late int _mes;
  late Future<List<MovimientoLibroDiario>> _movimientosFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _anio = now.year;
    _mes = now.month;
    _loadMovimientos();
  }

  void _loadMovimientos() {
    _movimientosFuture = _libroDiarioService.listarMovimientos(
      espacioId: widget.espacio.id,
      anio: _anio,
      mes: _mes,
    );
  }

  void _retry() {
    setState(_loadMovimientos);
  }

  void _goToPreviousMonth() {
    setState(() {
      if (_mes == 1) {
        _mes = 12;
        _anio--;
      } else {
        _mes--;
      }

      _loadMovimientos();
    });
  }

  void _goToNextMonth() {
    setState(() {
      if (_mes == 12) {
        _mes = 1;
        _anio++;
      } else {
        _mes++;
      }

      _loadMovimientos();
    });
  }

  String _formatMoney(double value) => '\$${value.toStringAsFixed(2)}';

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _monthName(int month) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
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
                    'Libro diario del espacio financiero.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _MonthSelector(
                    label: '${_monthName(_mes)} $_anio',
                    onPrevious: _goToPreviousMonth,
                    onNext: _goToNextMonth,
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder<List<MovimientoLibroDiario>>(
                    future: _movimientosFuture,
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
                          message: 'No se pudieron cargar los movimientos.',
                          onRetry: _retry,
                        );
                      }

                      final movimientos = snapshot.data ?? [];
                      final totalIngresos = movimientos.fold<double>(
                        0,
                        (total, movimiento) => total + movimiento.ingreso,
                      );
                      final totalGastos = movimientos.fold<double>(
                        0,
                        (total, movimiento) => total + movimiento.gasto,
                      );
                      final balance = totalIngresos - totalGastos;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _SummaryCard(
                                title: 'Total ingresos',
                                value: _formatMoney(totalIngresos),
                              ),
                              _SummaryCard(
                                title: 'Total gastos',
                                value: _formatMoney(totalGastos),
                              ),
                              _SummaryCard(
                                title: 'Balance',
                                value: _formatMoney(balance),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (movimientos.isEmpty)
                            Text(
                              'No hay movimientos para este mes.',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            )
                          else
                            ...movimientos.map(
                              (movimiento) => _MovimientoCard(
                                movimiento: movimiento,
                                formatMoney: _formatMoney,
                                formatDate: _formatDate,
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

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          tooltip: 'Mes anterior',
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          tooltip: 'Mes siguiente',
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovimientoCard extends StatelessWidget {
  const _MovimientoCard({
    required this.movimiento,
    required this.formatMoney,
    required this.formatDate,
  });

  final MovimientoLibroDiario movimiento;
  final String Function(double value) formatMoney;
  final String Function(DateTime date) formatDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = movimiento.esIngreso ? movimiento.ingreso : movimiento.gasto;
    final valueLabel = movimiento.esIngreso ? 'Ingreso' : 'Gasto';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    movimiento.concepto,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$valueLabel: ${formatMoney(value)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Fecha: ${formatDate(movimiento.fecha)}'),
            Text('Tipo: ${movimiento.tipoLabel}'),
            if (movimiento.persona != null)
              Text('Persona: ${movimiento.persona}'),
            if (movimiento.categoria != null)
              Text('Categoría: ${movimiento.categoria}'),
            if (movimiento.cuenta != null) Text('Cuenta: ${movimiento.cuenta}'),
            if ((movimiento.observacion ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(movimiento.observacion!),
            ],
          ],
        ),
      ),
    );
  }
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
