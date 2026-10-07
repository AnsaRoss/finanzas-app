import 'package:finanzas_mobile/features/devoluciones/models/devolucion.dart';
import 'package:finanzas_mobile/features/devoluciones/services/devoluciones_service.dart';
import 'package:finanzas_mobile/features/espacios/models/espacio_financiero.dart';
import 'package:flutter/material.dart';

class DevolucionesScreen extends StatefulWidget {
  const DevolucionesScreen({
    required this.espacio,
    super.key,
  });

  final EspacioFinanciero espacio;

  @override
  State<DevolucionesScreen> createState() => _DevolucionesScreenState();
}

class _DevolucionesScreenState extends State<DevolucionesScreen> {
  final _devolucionesService = const DevolucionesService();
  late Future<List<Devolucion>> _devolucionesFuture;
  bool _shouldRefreshDashboard = false;

  @override
  void initState() {
    super.initState();
    _devolucionesFuture = _loadDevoluciones();
  }

  Future<List<Devolucion>> _loadDevoluciones() {
    return _devolucionesService.listarPorEspacio(widget.espacio.id);
  }

  void _refreshDevoluciones() {
    setState(() {
      _devolucionesFuture = _loadDevoluciones();
    });
  }

  void _markChangedAndRefresh() {
    _shouldRefreshDashboard = true;
    _refreshDevoluciones();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatMoney(double value) => '\$${value.toStringAsFixed(2)}';

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  Future<void> _showRegistrarPagoDialog(Devolucion devolucion) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return _RegistrarPagoDialog(
          devolucion: devolucion,
          onSubmit: (values) async {
            await _devolucionesService.registrarPago(
              id: devolucion.id,
              valor: values.valor,
              fechaPago: values.fechaPago,
            );
          },
          onSuccess: () {
            _markChangedAndRefresh();
            _showMessage('Pago registrado correctamente.');
          },
          onError: _showMessage,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        Navigator.of(context).pop(_shouldRefreshDashboard);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Devoluciones'),
          leading: BackButton(
            onPressed: () {
              Navigator.of(context).pop(_shouldRefreshDashboard);
            },
          ),
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
                      'Devoluciones pendientes y pagadas del espacio.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder<List<Devolucion>>(
                      future: _devolucionesFuture,
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
                                'No se pudieron cargar las devoluciones.',
                            onRetry: _refreshDevoluciones,
                          );
                        }

                        final devoluciones = snapshot.data ?? [];
                        if (devoluciones.isEmpty) {
                          return Text(
                            'Aún no hay devoluciones registradas.',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          );
                        }

                        return Column(
                          children: devoluciones
                              .map(
                                (devolucion) => Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                devolucion.gasto,
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _formatMoney(devolucion.valor),
                                              style: theme
                                                  .textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Debe: ${devolucion.debeUsuario}',
                                        ),
                                        Text(
                                          'Recibe: ${devolucion.recibeUsuario}',
                                        ),
                                        Text(
                                          'Valor total: ${_formatMoney(devolucion.valor)}',
                                        ),
                                        Text(
                                          'Valor pagado: ${_formatMoney(devolucion.valorPagado)}',
                                        ),
                                        Text(
                                          'Pendiente: ${_formatMoney(devolucion.pendiente)}',
                                        ),
                                        Text(
                                          'Estado: ${devolucion.estadoLabel}',
                                        ),
                                        if (devolucion.fechaPago != null)
                                          Text(
                                            'Fecha de pago: ${_formatDate(devolucion.fechaPago!)}',
                                          ),
                                        if (devolucion.recibeCuenta != null)
                                          Text(
                                            'Cuenta receptora: ${devolucion.recibeCuenta}',
                                          ),
                                        if ((devolucion.observacion ?? '')
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(devolucion.observacion!),
                                        ],
                                        if (devolucion.permitePago) ...[
                                          const SizedBox(height: 12),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton.icon(
                                              onPressed: () {
                                                _showRegistrarPagoDialog(
                                                  devolucion,
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.payments_outlined,
                                              ),
                                              label: const Text(
                                                'Registrar pago',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegistrarPagoValues {
  const _RegistrarPagoValues({
    required this.valor,
    required this.fechaPago,
  });

  final double valor;
  final DateTime fechaPago;
}

class _RegistrarPagoDialog extends StatefulWidget {
  const _RegistrarPagoDialog({
    required this.devolucion,
    required this.onSubmit,
    required this.onSuccess,
    required this.onError,
  });

  final Devolucion devolucion;
  final Future<void> Function(_RegistrarPagoValues values) onSubmit;
  final VoidCallback onSuccess;
  final void Function(String message) onError;

  @override
  State<_RegistrarPagoDialog> createState() => _RegistrarPagoDialogState();
}

class _RegistrarPagoDialogState extends State<_RegistrarPagoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valorController;
  late final TextEditingController _fechaPagoController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();

    _valorController = TextEditingController(
      text: widget.devolucion.pendiente.toStringAsFixed(2),
    );
    _fechaPagoController = TextEditingController(text: _formatDate(today));
  }

  @override
  void dispose() {
    _valorController.dispose();
    _fechaPagoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate() || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSubmit(
        _RegistrarPagoValues(
          valor: double.parse(_valorController.text.trim()),
          fechaPago: DateTime.parse(_fechaPagoController.text.trim()),
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      widget.onSuccess();
    } on DevolucionesException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });
      widget.onError(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });
      widget.onError('No se pudo registrar el pago.');
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String? _validateMoney(String? value) {
    final text = value?.trim() ?? '';
    final number = double.tryParse(text);

    if (text.isEmpty) {
      return 'El valor es requerido';
    }

    if (number == null || number <= 0) {
      return 'Ingresa un valor mayor que 0';
    }

    if (number > widget.devolucion.pendiente) {
      return 'El valor no puede superar el pendiente';
    }

    return null;
  }

  String? _validateDate(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'La fecha de pago es requerida';
    }

    if (DateTime.tryParse(text) == null) {
      return 'Usa el formato yyyy-MM-dd';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar pago'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _valorController,
                enabled: !_isSaving,
                decoration: const InputDecoration(labelText: 'Valor a pagar'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: _validateMoney,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fechaPagoController,
                enabled: !_isSaving,
                decoration: const InputDecoration(labelText: 'Fecha de pago'),
                textInputAction: TextInputAction.next,
                validator: _validateDate,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
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
