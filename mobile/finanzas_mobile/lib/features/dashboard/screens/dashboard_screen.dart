import 'package:finanzas_mobile/features/espacios/models/espacio_financiero.dart';
import 'package:finanzas_mobile/features/gastos/screens/gastos_variables_screen.dart';
import 'package:finanzas_mobile/features/ingresos/screens/ingresos_screen.dart';
import 'package:finanzas_mobile/features/reportes/models/resumen_financiero.dart';
import 'package:finanzas_mobile/features/reportes/services/reportes_service.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.espacio,
    super.key,
  });

  final EspacioFinanciero espacio;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _reportesService = const ReportesService();
  late int _anio;
  late int _mes;
  late Future<ResumenFinanciero> _resumenFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _anio = now.year;
    _mes = now.month;
    _loadResumen();
  }

  void _loadResumen() {
    _resumenFuture = _reportesService.getResumenMensual(
      espacioId: widget.espacio.id,
      anio: _anio,
      mes: _mes,
    );
  }

  void _retry() {
    setState(_loadResumen);
  }

  void _goToPreviousMonth() {
    setState(() {
      if (_mes == 1) {
        _mes = 12;
        _anio--;
      } else {
        _mes--;
      }

      _loadResumen();
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

      _loadResumen();
    });
  }

  String _formatMoney(double value) => '\$${value.toStringAsFixed(2)}';

  Future<void> _openIngresos({bool openCreateOnStart = false}) async {
    final shouldRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => IngresosScreen(
          espacio: widget.espacio,
          openCreateOnStart: openCreateOnStart,
        ),
      ),
    );

    if (shouldRefresh == true && mounted) {
      _retry();
    }
  }

  Future<void> _openGastos({bool openCreateOnStart = false}) async {
    final shouldRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GastosVariablesScreen(
          espacio: widget.espacio,
          openCreateOnStart: openCreateOnStart,
        ),
      ),
    );

    if (shouldRefresh == true && mounted) {
      _retry();
    }
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
        title: const Text('Dashboard'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                children: [
                  Text(
                    widget.espacio.nombre,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tipo: ${widget.espacio.tipoLabel}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Resumen financiero mensual del espacio.',
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
                  FutureBuilder<ResumenFinanciero>(
                    future: _resumenFuture,
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
                              'No se pudo cargar el resumen financiero.',
                          onRetry: _retry,
                        );
                      }

                      final resumen = snapshot.data;
                      if (resumen == null) {
                        return _ErrorState(
                          message:
                              'No se encontró resumen para este mes.',
                          onRetry: _retry,
                        );
                      }

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _SummaryCard(
                            title: 'Ingresos',
                            value: _formatMoney(resumen.totalIngresos),
                            icon: Icons.trending_up_outlined,
                          ),
                          _SummaryCard(
                            title: 'Gastos',
                            value: _formatMoney(resumen.totalGastos),
                            icon: Icons.trending_down_outlined,
                          ),
                          _SummaryCard(
                            title: 'Saldo',
                            value: _formatMoney(resumen.saldo),
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Acciones rápidas',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _QuickActionButton(
                        label: 'Registrar ingreso',
                        icon: Icons.add_circle_outline,
                        onPressed: () {
                          _openIngresos(openCreateOnStart: true);
                        },
                      ),
                      _QuickActionButton(
                        label: 'Registrar gasto',
                        icon: Icons.remove_circle_outline,
                        onPressed: () {
                          _openGastos(openCreateOnStart: true);
                        },
                      ),
                      _QuickActionButton(
                        label: 'Ver movimientos',
                        icon: Icons.receipt_long_outlined,
                        onPressed: null,
                      ),
                    ],
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

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
              Icon(
                icon,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
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

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
