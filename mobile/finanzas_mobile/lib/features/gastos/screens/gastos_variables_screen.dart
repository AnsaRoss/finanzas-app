import 'package:finanzas_mobile/features/auth/models/login_response.dart';
import 'package:finanzas_mobile/features/auth/services/session_service.dart';
import 'package:finanzas_mobile/features/espacios/models/espacio_financiero.dart';
import 'package:finanzas_mobile/features/gastos/models/gasto_variable.dart';
import 'package:finanzas_mobile/features/gastos/services/gastos_service.dart';
import 'package:finanzas_mobile/features/ingresos/models/categoria_ingreso.dart';
import 'package:finanzas_mobile/features/ingresos/models/cuenta_ingreso.dart';
import 'package:finanzas_mobile/features/ingresos/models/usuario_ingreso.dart';
import 'package:finanzas_mobile/features/ingresos/services/ingresos_catalogos_service.dart';
import 'package:flutter/material.dart';

class GastosVariablesScreen extends StatefulWidget {
  const GastosVariablesScreen({
    required this.espacio,
    this.openCreateOnStart = false,
    super.key,
  });

  final EspacioFinanciero espacio;
  final bool openCreateOnStart;

  @override
  State<GastosVariablesScreen> createState() => _GastosVariablesScreenState();
}

class _GastosVariablesScreenState extends State<GastosVariablesScreen> {
  final _gastosService = const GastosService();
  final _sessionService = const SessionService();
  late Future<List<GastoVariable>> _gastosFuture;
  bool _shouldRefreshDashboard = false;

  @override
  void initState() {
    super.initState();
    _gastosFuture = _loadGastos();

    if (widget.openCreateOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRegistrarGastoDialog();
      });
    }
  }

  Future<List<GastoVariable>> _loadGastos() {
    return _gastosService.listarVariables(espacioId: widget.espacio.id);
  }

  void _refreshGastos() {
    setState(() {
      _gastosFuture = _loadGastos();
    });
  }

  void _markChangedAndRefresh() {
    _shouldRefreshDashboard = true;
    _refreshGastos();
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

  Future<void> _showRegistrarGastoDialog() async {
    final session = await _sessionService.getSession();

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) {
        return _GastoVariableFormDialog(
          espacio: widget.espacio,
          session: session,
          onSubmit: (values) async {
            await _gastosService.registrarVariable(
              espacioFinancieroId: widget.espacio.id,
              categoriaId: values.categoriaId,
              concepto: values.concepto,
              valor: values.valor,
              fecha: values.fecha,
              pagadoPorId: values.marcarPagado ? values.pagadoPorId : null,
              cuentaId: values.marcarPagado ? values.cuentaId : null,
              marcarPagado: values.marcarPagado,
              tipoReparto: values.tipoReparto,
              responsableId: values.responsableId,
              distribucion: values.distribucion,
              observacion: values.observacion,
            );
          },
          onSuccess: () {
            _markChangedAndRefresh();
            _showMessage('Gasto registrado correctamente.');
          },
          onError: _showMessage,
        );
      },
    );
  }

  Future<void> _showPagarGastoDialog(GastoVariable gasto) async {
    final session = await _sessionService.getSession();

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) {
        return _PagarGastoDialog(
          espacio: widget.espacio,
          session: session,
          gasto: gasto,
          onSubmit: (values) async {
            await _gastosService.pagarGasto(
              gastoId: gasto.id,
              pagadoPorId: values.pagadoPorId,
              cuentaId: values.cuentaId,
              fechaPago: values.fechaPago,
            );
          },
          onSuccess: () {
            _markChangedAndRefresh();
            _showMessage('Gasto pagado correctamente.');
          },
          onError: _showMessage,
        );
      },
    );
  }

  Future<void> _confirmarAnularGasto(GastoVariable gasto) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Anular gasto'),
          content: Text('¿Deseas anular "${gasto.concepto}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Anular'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _gastosService.anularGasto(gasto.id);

      if (!mounted) {
        return;
      }

      _markChangedAndRefresh();
      _showMessage('Gasto anulado correctamente.');
    } on GastosException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('No se pudo anular el gasto.');
    }
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
          title: const Text('Gastos'),
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
                      'Gastos registrados en este espacio.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _showRegistrarGastoDialog,
                      icon: const Icon(Icons.remove_circle_outline),
                      label: const Text('Registrar gasto'),
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder<List<GastoVariable>>(
                      future: _gastosFuture,
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
                            message: 'No se pudieron cargar los gastos.',
                            onRetry: _refreshGastos,
                          );
                        }

                        final gastos = snapshot.data ?? [];
                        if (gastos.isEmpty) {
                          return Text(
                            'Aún no hay gastos registrados.',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          );
                        }

                        return Column(
                          children: gastos
                              .map(
                                (gasto) => Card(
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
                                                gasto.concepto,
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _formatMoney(gasto.valor),
                                              style: theme
                                                  .textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text('Fecha: ${_formatDate(gasto.fecha)}'),
                                        Text('Tipo: ${gasto.tipoLabel}'),
                                        Text('Estado: ${gasto.estadoLabel}'),
                                        Text('Categoría: ${gasto.categoria}'),
                                        if (gasto.pagadoPor != null)
                                          Text('Pagado por: ${gasto.pagadoPor}'),
                                        if (gasto.cuenta != null)
                                          Text('Cuenta: ${gasto.cuenta}'),
                                        if (gasto.distribucion.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            'Distribución',
                                            style: theme.textTheme.labelLarge,
                                          ),
                                          ...gasto.distribucion.map(
                                            (item) => Text(
                                              '${item.usuario}: ${item.porcentaje.toStringAsFixed(2)}% - ${_formatMoney(item.valor)}',
                                            ),
                                          ),
                                        ],
                                        if ((gasto.observacion ?? '')
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(gasto.observacion!),
                                        ],
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          alignment: WrapAlignment.end,
                                          children: [
                                            if (gasto.estaPendiente)
                                              TextButton.icon(
                                                onPressed: () {
                                                  _showPagarGastoDialog(gasto);
                                                },
                                                icon: const Icon(
                                                  Icons.payments_outlined,
                                                ),
                                                label: const Text('Pagar'),
                                              ),
                                            if (!gasto.estaAnulado)
                                              TextButton.icon(
                                                onPressed: () {
                                                  _confirmarAnularGasto(gasto);
                                                },
                                                icon: const Icon(
                                                  Icons.block_outlined,
                                                ),
                                                label: const Text('Anular'),
                                              ),
                                          ],
                                        ),
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

class _GastoCatalogos {
  const _GastoCatalogos({
    required this.usuarios,
    required this.categorias,
    required this.cuentas,
  });

  final List<UsuarioIngreso> usuarios;
  final List<CategoriaIngreso> categorias;
  final List<CuentaIngreso> cuentas;
}

class _GastoVariableFormValues {
  const _GastoVariableFormValues({
    required this.categoriaId,
    required this.concepto,
    required this.valor,
    required this.fecha,
    required this.pagadoPorId,
    required this.cuentaId,
    required this.marcarPagado,
    required this.tipoReparto,
    required this.responsableId,
    required this.distribucion,
    required this.observacion,
  });

  final int categoriaId;
  final String concepto;
  final double valor;
  final DateTime fecha;
  final int? pagadoPorId;
  final int? cuentaId;
  final bool marcarPagado;
  final int tipoReparto;
  final int responsableId;
  final List<Map<String, Object>> distribucion;
  final String? observacion;
}

class _PagarGastoValues {
  const _PagarGastoValues({
    required this.pagadoPorId,
    required this.cuentaId,
    required this.fechaPago,
  });

  final int pagadoPorId;
  final int? cuentaId;
  final DateTime fechaPago;
}

class _GastoVariableFormDialog extends StatefulWidget {
  const _GastoVariableFormDialog({
    required this.espacio,
    required this.session,
    required this.onSubmit,
    required this.onSuccess,
    required this.onError,
  });

  final EspacioFinanciero espacio;
  final LoginResponse? session;
  final Future<void> Function(_GastoVariableFormValues values) onSubmit;
  final VoidCallback onSuccess;
  final void Function(String message) onError;

  @override
  State<_GastoVariableFormDialog> createState() =>
      _GastoVariableFormDialogState();
}

class _GastoVariableFormDialogState extends State<_GastoVariableFormDialog> {
  final _catalogosService = const IngresosCatalogosService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _conceptoController;
  late final TextEditingController _valorController;
  late final TextEditingController _fechaController;
  late final TextEditingController _observacionController;
  late Future<_GastoCatalogos> _catalogosFuture;
  final Map<int, TextEditingController> _porcentajeControllers = {};
  int? _selectedCategoriaId;
  int? _selectedPagadoPorId;
  int? _selectedCuentaId;
  int? _selectedResponsableId;
  bool _marcarPagado = true;
  int _tipoReparto = 1;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();

    _selectedPagadoPorId =
        widget.espacio.esHogar ? null : widget.session?.usuarioId;
    _selectedResponsableId =
        widget.espacio.esHogar ? null : widget.session?.usuarioId;
    _tipoReparto = widget.espacio.esHogar ? 1 : 2;
    _conceptoController = TextEditingController();
    _valorController = TextEditingController();
    _fechaController = TextEditingController(text: _formatDate(today));
    _observacionController = TextEditingController();
    _catalogosFuture = _loadCatalogos();
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    _valorController.dispose();
    _fechaController.dispose();
    _observacionController.dispose();
    for (final controller in _porcentajeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<_GastoCatalogos> _loadCatalogos() async {
    final categorias = await _catalogosService.listarCategoriasGasto(
      widget.espacio.id,
    );
    final cuentas = await _catalogosService.listarCuentas(widget.espacio.id);
    final usuarios = widget.espacio.esHogar
        ? await _catalogosService.listarUsuariosHogar(widget.espacio.id)
        : [
            if (widget.session != null)
              UsuarioIngreso(
                usuarioId: widget.session!.usuarioId,
                usuario: widget.session!.nombre,
              ),
          ];

    for (final usuario in usuarios) {
      _porcentajeControllers.putIfAbsent(
        usuario.usuarioId,
        () => TextEditingController(text: usuario.porcentajeText),
      );
    }

    return _GastoCatalogos(
      usuarios: usuarios,
      categorias: categorias,
      cuentas: cuentas,
    );
  }

  void _retryCatalogos() {
    setState(() {
      _catalogosFuture = _loadCatalogos();
    });
  }

  Future<void> _submit(_GastoCatalogos catalogos) async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate() || _isSaving) {
      return;
    }

    final distribucion = _buildDistribucion(catalogos.usuarios);
    if (distribucion == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSubmit(
        _GastoVariableFormValues(
          categoriaId: _selectedCategoriaId!,
          concepto: _conceptoController.text.trim(),
          valor: double.parse(_valorController.text.trim()),
          fecha: DateTime.parse(_fechaController.text.trim()),
          pagadoPorId: _selectedPagadoPorId,
          cuentaId: _selectedCuentaId,
          marcarPagado: _marcarPagado,
          tipoReparto: _tipoReparto,
          responsableId: _selectedResponsableId ?? 0,
          distribucion: distribucion,
          observacion: _emptyToNull(_observacionController.text),
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      widget.onSuccess();
    } on GastosException catch (error) {
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
      widget.onError('No se pudo guardar el gasto.');
    }
  }

  List<Map<String, Object>>? _buildDistribucion(List<UsuarioIngreso> usuarios) {
    if (_tipoReparto == 1) {
      return usuarios
          .map(
            (usuario) => {
              'usuarioId': usuario.usuarioId,
              'porcentaje': usuario.porcentaje,
            },
          )
          .toList();
    }

    if (_tipoReparto == 2) {
      if (_selectedResponsableId == null) {
        widget.onError('Selecciona el responsable del gasto.');
        return null;
      }

      return const [];
    }

    final distribucion = <Map<String, Object>>[];
    var total = 0.0;

    for (final usuario in usuarios) {
      final porcentaje = double.tryParse(
            _porcentajeControllers[usuario.usuarioId]?.text.trim() ?? '',
          ) ??
          0;
      total += porcentaje;
      distribucion.add({
        'usuarioId': usuario.usuarioId,
        'porcentaje': porcentaje,
      });
    }

    if ((total - 100).abs() > 0.01) {
      widget.onError('La distribución personalizada debe sumar 100%.');
      return null;
    }

    return distribucion;
  }

  String? _validateRequired(String? value, String message) {
    if ((value ?? '').trim().isEmpty) {
      return message;
    }

    return null;
  }

  String? _validateSelected<T>(T? value, String message) {
    if (value == null) {
      return message;
    }

    return null;
  }

  String? _validateValue(String? value) {
    final text = value?.trim() ?? '';
    final number = double.tryParse(text);

    if (text.isEmpty) {
      return 'El valor es requerido';
    }

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

  int? _validUsuarioValue(List<UsuarioIngreso> usuarios, int? selected) {
    return usuarios.any((usuario) => usuario.usuarioId == selected)
        ? selected
        : null;
  }

  int? _validCategoryValue(List<CategoriaIngreso> categorias) {
    return categorias.any((categoria) => categoria.id == _selectedCategoriaId)
        ? _selectedCategoriaId
        : null;
  }

  int? _validCuentaValue(List<CuentaIngreso> cuentas) {
    return cuentas.any((cuenta) => cuenta.id == _selectedCuentaId)
        ? _selectedCuentaId
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar gasto'),
      content: FutureBuilder<_GastoCatalogos>(
        future: _catalogosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              width: 340,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: 'No se pudieron cargar los catálogos.',
              onRetry: _retryCatalogos,
            );
          }

          final catalogos = snapshot.data!;

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _validCategoryValue(catalogos.categorias),
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: catalogos.categorias
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
                    validator: (value) => _validateSelected(
                      value,
                      'La categoría es requerida',
                    ),
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
                    controller: _valorController,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(labelText: 'Valor'),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: _validateValue,
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
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _marcarPagado,
                    title: const Text('Marcar como pagado'),
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() {
                              _marcarPagado = value;
                            });
                          },
                  ),
                  if (_marcarPagado) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _validUsuarioValue(
                        catalogos.usuarios,
                        _selectedPagadoPorId,
                      ),
                      decoration: const InputDecoration(labelText: 'Quién pagó'),
                      items: catalogos.usuarios
                          .map(
                            (usuario) => DropdownMenuItem(
                              value: usuario.usuarioId,
                              child: Text(usuario.usuario),
                            ),
                          )
                          .toList(),
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              setState(() {
                                _selectedPagadoPorId = value;
                              });
                            },
                      validator: (value) => _validateSelected(
                        value,
                        'Selecciona quién pagó',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      initialValue: _validCuentaValue(catalogos.cuentas),
                      decoration: const InputDecoration(labelText: 'Cuenta'),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Sin cuenta'),
                        ),
                        ...catalogos.cuentas.map(
                          (cuenta) => DropdownMenuItem<int?>(
                            value: cuenta.id,
                            child: Text(cuenta.label),
                          ),
                        ),
                      ],
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              setState(() {
                                _selectedCuentaId = value;
                              });
                            },
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _tipoReparto,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de reparto',
                    ),
                    items: [
                      if (widget.espacio.esHogar)
                        const DropdownMenuItem(
                          value: 1,
                          child: Text('Regla del hogar'),
                        ),
                      const DropdownMenuItem(
                        value: 2,
                        child: Text('Individual'),
                      ),
                      if (widget.espacio.esHogar)
                        const DropdownMenuItem(
                          value: 3,
                          child: Text('Personalizado'),
                        ),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              _tipoReparto = value;
                            });
                          },
                  ),
                  if (_tipoReparto == 2) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _validUsuarioValue(
                        catalogos.usuarios,
                        _selectedResponsableId,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Responsable',
                      ),
                      items: catalogos.usuarios
                          .map(
                            (usuario) => DropdownMenuItem(
                              value: usuario.usuarioId,
                              child: Text(usuario.usuario),
                            ),
                          )
                          .toList(),
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              setState(() {
                                _selectedResponsableId = value;
                              });
                            },
                      validator: (value) => _validateSelected(
                        value,
                        'Selecciona el responsable',
                      ),
                    ),
                  ],
                  if (_tipoReparto == 3) ...[
                    const SizedBox(height: 12),
                    ...catalogos.usuarios.map(
                      (usuario) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _porcentajeControllers[usuario.usuarioId],
                          enabled: !_isSaving,
                          decoration: InputDecoration(
                            labelText: '${usuario.usuario} (%)',
                          ),
                          keyboardType: TextInputType.number,
                          validator: _validateValue,
                        ),
                      ),
                    ),
                  ],
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
          onPressed: _isSaving
              ? null
              : () async {
                  final catalogos = await _catalogosFuture;
                  await _submit(catalogos);
                },
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

class _PagarGastoDialog extends StatefulWidget {
  const _PagarGastoDialog({
    required this.espacio,
    required this.session,
    required this.gasto,
    required this.onSubmit,
    required this.onSuccess,
    required this.onError,
  });

  final EspacioFinanciero espacio;
  final LoginResponse? session;
  final GastoVariable gasto;
  final Future<void> Function(_PagarGastoValues values) onSubmit;
  final VoidCallback onSuccess;
  final void Function(String message) onError;

  @override
  State<_PagarGastoDialog> createState() => _PagarGastoDialogState();
}

class _PagarGastoDialogState extends State<_PagarGastoDialog> {
  final _catalogosService = const IngresosCatalogosService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fechaPagoController;
  late Future<_GastoCatalogos> _catalogosFuture;
  int? _selectedPagadoPorId;
  int? _selectedCuentaId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();

    _selectedPagadoPorId =
        widget.espacio.esHogar ? null : widget.session?.usuarioId;
    _fechaPagoController = TextEditingController(text: _formatDate(today));
    _catalogosFuture = _loadCatalogos();
  }

  @override
  void dispose() {
    _fechaPagoController.dispose();
    super.dispose();
  }

  Future<_GastoCatalogos> _loadCatalogos() async {
    final cuentas = await _catalogosService.listarCuentas(widget.espacio.id);
    final usuarios = widget.espacio.esHogar
        ? await _catalogosService.listarUsuariosHogar(widget.espacio.id)
        : [
            if (widget.session != null)
              UsuarioIngreso(
                usuarioId: widget.session!.usuarioId,
                usuario: widget.session!.nombre,
              ),
          ];

    return _GastoCatalogos(
      usuarios: usuarios,
      categorias: const [],
      cuentas: cuentas,
    );
  }

  void _retryCatalogos() {
    setState(() {
      _catalogosFuture = _loadCatalogos();
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
        _PagarGastoValues(
          pagadoPorId: _selectedPagadoPorId!,
          cuentaId: _selectedCuentaId,
          fechaPago: DateTime.parse(_fechaPagoController.text.trim()),
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      widget.onSuccess();
    } on GastosException catch (error) {
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
      widget.onError('No se pudo pagar el gasto.');
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
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

  int? _validUsuarioValue(List<UsuarioIngreso> usuarios) {
    return usuarios.any((usuario) => usuario.usuarioId == _selectedPagadoPorId)
        ? _selectedPagadoPorId
        : null;
  }

  int? _validCuentaValue(List<CuentaIngreso> cuentas) {
    return cuentas.any((cuenta) => cuenta.id == _selectedCuentaId)
        ? _selectedCuentaId
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pagar gasto'),
      content: FutureBuilder<_GastoCatalogos>(
        future: _catalogosFuture,
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
              message: 'No se pudieron cargar los catálogos.',
              onRetry: _retryCatalogos,
            );
          }

          final catalogos = snapshot.data!;

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _validUsuarioValue(catalogos.usuarios),
                    decoration: const InputDecoration(labelText: 'Quién pagó'),
                    items: catalogos.usuarios
                        .map(
                          (usuario) => DropdownMenuItem(
                            value: usuario.usuarioId,
                            child: Text(usuario.usuario),
                          ),
                        )
                        .toList(),
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() {
                              _selectedPagadoPorId = value;
                            });
                          },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona quién pagó';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    initialValue: _validCuentaValue(catalogos.cuentas),
                    decoration: const InputDecoration(labelText: 'Cuenta'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Sin cuenta'),
                      ),
                      ...catalogos.cuentas.map(
                        (cuenta) => DropdownMenuItem<int?>(
                          value: cuenta.id,
                          child: Text(cuenta.label),
                        ),
                      ),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() {
                              _selectedCuentaId = value;
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fechaPagoController,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(labelText: 'Fecha pago'),
                    validator: _validateDate,
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
              : const Text('Pagar'),
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

extension on UsuarioIngreso {
  String get porcentajeText {
    final value = porcentaje;
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }
}
