import 'package:finanzas_mobile/features/espacios/models/espacio_financiero.dart';
import 'package:finanzas_mobile/features/gastos/services/gastos_service.dart';
import 'package:finanzas_mobile/features/gastos_fijos/models/gasto_fijo.dart';
import 'package:finanzas_mobile/features/gastos_fijos/services/gastos_fijos_service.dart';
import 'package:finanzas_mobile/features/ingresos/models/categoria_ingreso.dart';
import 'package:finanzas_mobile/features/ingresos/services/ingresos_catalogos_service.dart';
import 'package:flutter/material.dart';

class GastosFijosScreen extends StatefulWidget {
  const GastosFijosScreen({
    required this.espacio,
    super.key,
  });

  final EspacioFinanciero espacio;

  @override
  State<GastosFijosScreen> createState() => _GastosFijosScreenState();
}

class _GastosFijosScreenState extends State<GastosFijosScreen> {
  final _gastosFijosService = const GastosFijosService();
  final _gastosService = const GastosService();
  late Future<_GastosFijosData> _gastosFijosFuture;
  bool _shouldRefreshDashboard = false;

  @override
  void initState() {
    super.initState();
    _gastosFijosFuture = _loadGastosFijos();
  }

  Future<_GastosFijosData> _loadGastosFijos() async {
    final today = DateTime.now();
    final gastosFijos = await _gastosFijosService.listarPorEspacio(
      widget.espacio.id,
    );
    final gastosDelMes = await _gastosService.listarVariables(
      espacioId: widget.espacio.id,
      anio: today.year,
      mes: today.month,
    );

    return _GastosFijosData(
      gastosFijos: gastosFijos,
      gastosFijosGenerados: gastosDelMes
          .map((gasto) => gasto.gastoFijoId)
          .whereType<int>()
          .toSet(),
    );
  }

  void _refreshGastosFijos() {
    setState(() {
      _gastosFijosFuture = _loadGastosFijos();
    });
  }

  void _markChangedAndRefresh({bool refreshDashboard = false}) {
    _shouldRefreshDashboard = _shouldRefreshDashboard || refreshDashboard;
    _refreshGastosFijos();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatMoney(double value) => '\$${value.toStringAsFixed(2)}';

  Future<void> _showCrearDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return _GastoFijoFormDialog(
          espacio: widget.espacio,
          gastoFijo: null,
          onSubmit: (values) async {
            await _gastosFijosService.crear(
              espacioFinancieroId: widget.espacio.id,
              categoriaId: values.categoriaId,
              concepto: values.concepto,
              valorEstimado: values.valorEstimado,
              diaVencimiento: values.diaVencimiento,
            );
          },
          onSuccess: () {
            _markChangedAndRefresh();
            _showMessage('Gasto fijo creado correctamente.');
          },
          onError: _showMessage,
        );
      },
    );
  }

  Future<void> _showEditarDialog(GastoFijo gastoFijo) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return _GastoFijoFormDialog(
          espacio: widget.espacio,
          gastoFijo: gastoFijo,
          onSubmit: (values) async {
            await _gastosFijosService.editar(
              id: gastoFijo.id,
              espacioFinancieroId: widget.espacio.id,
              categoriaId: values.categoriaId,
              concepto: values.concepto,
              valorEstimado: values.valorEstimado,
              diaVencimiento: values.diaVencimiento,
            );
          },
          onSuccess: () {
            _markChangedAndRefresh();
            _showMessage('Gasto fijo editado correctamente.');
          },
          onError: _showMessage,
        );
      },
    );
  }

  Future<void> _toggleEstado(GastoFijo gastoFijo) async {
    try {
      await _gastosFijosService.cambiarEstado(
        id: gastoFijo.id,
        activo: !gastoFijo.activo,
      );

      if (!mounted) {
        return;
      }

      _markChangedAndRefresh();
      _showMessage(
        gastoFijo.activo
            ? 'Gasto fijo desactivado correctamente.'
            : 'Gasto fijo activado correctamente.',
      );
    } on GastosFijosException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('No se pudo cambiar el estado.');
    }
  }

  Future<void> _showGenerarDialog(GastoFijo gastoFijo) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return _GenerarGastoFijoDialog(
          gastoFijo: gastoFijo,
          onSubmit: (values) async {
            await _gastosFijosService.generar(
              id: gastoFijo.id,
              valor: values.valor,
              fecha: values.fecha,
              observacion: values.observacion,
            );
          },
          onSuccess: () {
            _markChangedAndRefresh(refreshDashboard: true);
            _showMessage('Gasto del mes generado correctamente.');
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
          title: const Text('Gastos fijos'),
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
                      'Gastos recurrentes configurados para este espacio.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _showCrearDialog,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Crear gasto fijo'),
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder<_GastosFijosData>(
                      future: _gastosFijosFuture,
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
                            message: 'No se pudieron cargar los gastos fijos.',
                            onRetry: _refreshGastosFijos,
                          );
                        }

                        final data = snapshot.data;
                        final gastosFijos = data?.gastosFijos ?? [];
                        final gastosFijosGenerados =
                            data?.gastosFijosGenerados ?? <int>{};
                        if (gastosFijos.isEmpty) {
                          return Text(
                            'Aún no hay gastos fijos configurados.',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          );
                        }

                        return Column(
                          children: gastosFijos
                              .map(
                                (gastoFijo) {
                                  final estaGenerado = gastosFijosGenerados
                                      .contains(gastoFijo.id);

                                  return Card(
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
                                                  gastoFijo.concepto,
                                                  style: theme
                                                      .textTheme.titleMedium
                                                      ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                _formatMoney(
                                                  gastoFijo.valorEstimado,
                                                ),
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
                                            'Día de vencimiento: ${gastoFijo.diaVencimiento}',
                                          ),
                                          Text(
                                            'Categoría: ${gastoFijo.categoria}',
                                          ),
                                          Text(
                                            'Estado: ${gastoFijo.estadoLabel}',
                                          ),
                                          if (estaGenerado)
                                            const Text('Generado ✓'),
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            alignment: WrapAlignment.end,
                                            children: [
                                              TextButton.icon(
                                                onPressed: () {
                                                  _showEditarDialog(gastoFijo);
                                                },
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                ),
                                                label: const Text('Editar'),
                                              ),
                                              if (gastoFijo.activo &&
                                                  !estaGenerado)
                                                TextButton.icon(
                                                  onPressed: () {
                                                    _showGenerarDialog(
                                                      gastoFijo,
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.event_repeat_outlined,
                                                  ),
                                                  label: const Text('Generar'),
                                                )
                                              else if (gastoFijo.activo)
                                                OutlinedButton.icon(
                                                  onPressed: null,
                                                  icon: const Icon(
                                                    Icons.check_circle_outline,
                                                  ),
                                                  label: const Text(
                                                    'Generado ✓',
                                                  ),
                                                ),
                                              TextButton.icon(
                                                onPressed: () {
                                                  _toggleEstado(gastoFijo);
                                                },
                                                icon: Icon(
                                                  gastoFijo.activo
                                                      ? Icons
                                                          .pause_circle_outline
                                                      : Icons
                                                          .play_circle_outline,
                                                ),
                                                label: Text(
                                                  gastoFijo.activo
                                                      ? 'Desactivar'
                                                      : 'Activar',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
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

class _GastosFijosData {
  const _GastosFijosData({
    required this.gastosFijos,
    required this.gastosFijosGenerados,
  });

  final List<GastoFijo> gastosFijos;
  final Set<int> gastosFijosGenerados;
}

class _GastoFijoFormValues {
  const _GastoFijoFormValues({
    required this.categoriaId,
    required this.concepto,
    required this.valorEstimado,
    required this.diaVencimiento,
  });

  final int categoriaId;
  final String concepto;
  final double valorEstimado;
  final int diaVencimiento;
}

class _GenerarGastoFijoValues {
  const _GenerarGastoFijoValues({
    required this.valor,
    required this.fecha,
    required this.observacion,
  });

  final double? valor;
  final DateTime fecha;
  final String? observacion;
}

class _GastoFijoFormDialog extends StatefulWidget {
  const _GastoFijoFormDialog({
    required this.espacio,
    required this.gastoFijo,
    required this.onSubmit,
    required this.onSuccess,
    required this.onError,
  });

  final EspacioFinanciero espacio;
  final GastoFijo? gastoFijo;
  final Future<void> Function(_GastoFijoFormValues values) onSubmit;
  final VoidCallback onSuccess;
  final void Function(String message) onError;

  @override
  State<_GastoFijoFormDialog> createState() => _GastoFijoFormDialogState();
}

class _GastoFijoFormDialogState extends State<_GastoFijoFormDialog> {
  final _catalogosService = const IngresosCatalogosService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _conceptoController;
  late final TextEditingController _valorEstimadoController;
  late final TextEditingController _diaVencimientoController;
  late Future<List<CategoriaIngreso>> _categoriasFuture;
  int? _selectedCategoriaId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final gastoFijo = widget.gastoFijo;

    _selectedCategoriaId = gastoFijo?.categoriaId;
    _conceptoController = TextEditingController(
      text: gastoFijo?.concepto ?? '',
    );
    _valorEstimadoController = TextEditingController(
      text: gastoFijo == null ? '' : gastoFijo.valorEstimado.toStringAsFixed(2),
    );
    _diaVencimientoController = TextEditingController(
      text: gastoFijo?.diaVencimiento.toString() ?? '',
    );
    _categoriasFuture = _loadCategorias();
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    _valorEstimadoController.dispose();
    _diaVencimientoController.dispose();
    super.dispose();
  }

  Future<List<CategoriaIngreso>> _loadCategorias() {
    return _catalogosService.listarCategoriasGasto(widget.espacio.id);
  }

  void _retryCategorias() {
    setState(() {
      _categoriasFuture = _loadCategorias();
    });
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
        _GastoFijoFormValues(
          categoriaId: _selectedCategoriaId!,
          concepto: _conceptoController.text.trim(),
          valorEstimado: double.parse(_valorEstimadoController.text.trim()),
          diaVencimiento: int.parse(_diaVencimientoController.text.trim()),
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      widget.onSuccess();
    } on GastosFijosException catch (error) {
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
      widget.onError('No se pudo guardar el gasto fijo.');
    }
  }

  String? _validateRequired(String? value, String message) {
    if ((value ?? '').trim().isEmpty) {
      return message;
    }

    return null;
  }

  String? _validateMoney(String? value) {
    final text = value?.trim() ?? '';
    final number = double.tryParse(text);

    if (text.isEmpty) {
      return 'El valor estimado es requerido';
    }

    if (number == null || number <= 0) {
      return 'Ingresa un valor mayor que 0';
    }

    return null;
  }

  String? _validateDueDay(String? value) {
    final text = value?.trim() ?? '';
    final day = int.tryParse(text);

    if (text.isEmpty) {
      return 'El día de vencimiento es requerido';
    }

    if (day == null || day < 1 || day > 31) {
      return 'Ingresa un día entre 1 y 31';
    }

    return null;
  }

  int? _validCategoryValue(List<CategoriaIngreso> categorias) {
    return categorias.any((categoria) => categoria.id == _selectedCategoriaId)
        ? _selectedCategoriaId
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.gastoFijo == null ? 'Crear gasto fijo' : 'Editar gasto fijo'),
      content: FutureBuilder<List<CategoriaIngreso>>(
        future: _categoriasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              width: 320,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: 'No se pudieron cargar las categorías.',
              onRetry: _retryCategorias,
            );
          }

          final categorias = snapshot.data ?? [];

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _validCategoryValue(categorias),
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: categorias
                        .map(
                          (categoria) => DropdownMenuItem(
                            value: categoria.id,
                            child: Text(categoria.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() {
                              _selectedCategoriaId = value;
                            });
                          },
                    validator: (value) {
                      if (value == null) {
                        return 'La categoría es requerida';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _conceptoController,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(labelText: 'Concepto'),
                    textInputAction: TextInputAction.next,
                    validator: (value) => _validateRequired(
                      value,
                      'El concepto es requerido',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _valorEstimadoController,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Valor estimado',
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: _validateMoney,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _diaVencimientoController,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Día de vencimiento',
                    ),
                    keyboardType: TextInputType.number,
                    validator: _validateDueDay,
                  ),
                ],
              ),
            ),
          );
        },
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

class _GenerarGastoFijoDialog extends StatefulWidget {
  const _GenerarGastoFijoDialog({
    required this.gastoFijo,
    required this.onSubmit,
    required this.onSuccess,
    required this.onError,
  });

  final GastoFijo gastoFijo;
  final Future<void> Function(_GenerarGastoFijoValues values) onSubmit;
  final VoidCallback onSuccess;
  final void Function(String message) onError;

  @override
  State<_GenerarGastoFijoDialog> createState() =>
      _GenerarGastoFijoDialogState();
}

class _GenerarGastoFijoDialogState extends State<_GenerarGastoFijoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valorController;
  late final TextEditingController _fechaController;
  late final TextEditingController _observacionController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();

    _valorController = TextEditingController(
      text: widget.gastoFijo.valorEstimado.toStringAsFixed(2),
    );
    _fechaController = TextEditingController(text: _formatDate(today));
    _observacionController = TextEditingController();
  }

  @override
  void dispose() {
    _valorController.dispose();
    _fechaController.dispose();
    _observacionController.dispose();
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
        _GenerarGastoFijoValues(
          valor: _emptyToNull(_valorController.text) == null
              ? null
              : double.parse(_valorController.text.trim()),
          fecha: DateTime.parse(_fechaController.text.trim()),
          observacion: _emptyToNull(_observacionController.text),
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      widget.onSuccess();
    } on GastosFijosException catch (error) {
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
      widget.onError('No se pudo generar el gasto.');
    }
  }

  String? _validateOptionalMoney(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }

    final number = double.tryParse(text);
    if (number == null || number <= 0) {
      return 'Ingresa un valor mayor que 0';
    }

    return null;
  }

  String? _validateDate(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'La fecha es requerida';
    }

    if (DateTime.tryParse(text) == null) {
      return 'Usa el formato yyyy-MM-dd';
    }

    return null;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String? _emptyToNull(String value) {
    final text = value.trim();

    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generar gasto del mes'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _valorController,
                enabled: !_isSaving,
                decoration: const InputDecoration(labelText: 'Valor'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: _validateOptionalMoney,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fechaController,
                enabled: !_isSaving,
                decoration: const InputDecoration(labelText: 'Fecha'),
                textInputAction: TextInputAction.next,
                validator: _validateDate,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _observacionController,
                enabled: !_isSaving,
                decoration: const InputDecoration(labelText: 'Observación'),
                minLines: 2,
                maxLines: 3,
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
              : const Text('Generar'),
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
