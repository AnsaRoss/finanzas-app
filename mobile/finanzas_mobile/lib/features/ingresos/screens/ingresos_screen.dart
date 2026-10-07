import 'package:finanzas_mobile/features/auth/models/login_response.dart';
import 'package:finanzas_mobile/features/auth/services/session_service.dart';
import 'package:finanzas_mobile/features/espacios/models/espacio_financiero.dart';
import 'package:finanzas_mobile/features/ingresos/models/categoria_ingreso.dart';
import 'package:finanzas_mobile/features/ingresos/models/cuenta_ingreso.dart';
import 'package:finanzas_mobile/features/ingresos/models/ingreso.dart';
import 'package:finanzas_mobile/features/ingresos/models/usuario_ingreso.dart';
import 'package:finanzas_mobile/features/ingresos/services/ingresos_catalogos_service.dart';
import 'package:finanzas_mobile/features/ingresos/services/ingresos_service.dart';
import 'package:flutter/material.dart';

class IngresosScreen extends StatefulWidget {
  const IngresosScreen({
    required this.espacio,
    this.openCreateOnStart = false,
    super.key,
  });

  final EspacioFinanciero espacio;
  final bool openCreateOnStart;

  @override
  State<IngresosScreen> createState() => _IngresosScreenState();
}

class _IngresosScreenState extends State<IngresosScreen> {
  final _ingresosService = const IngresosService();
  final _sessionService = const SessionService();
  late Future<List<Ingreso>> _ingresosFuture;
  bool _shouldRefreshDashboard = false;

  @override
  void initState() {
    super.initState();
    _ingresosFuture = _loadIngresos();

    if (widget.openCreateOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCrearIngresoDialog();
      });
    }
  }

  Future<List<Ingreso>> _loadIngresos() {
    return _ingresosService.listarPorEspacio(widget.espacio.id);
  }

  void _refreshIngresos() {
    setState(() {
      _ingresosFuture = _loadIngresos();
    });
  }

  void _markChangedAndRefresh() {
    _shouldRefreshDashboard = true;
    _refreshIngresos();
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

  Future<void> _showCrearIngresoDialog() async {
    final session = await _sessionService.getSession();

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) {
        return _IngresoFormDialog(
          title: 'Registrar ingreso',
          submitLabel: 'Guardar',
          espacio: widget.espacio,
          session: session,
          ingreso: null,
          onSubmit: (values) async {
            await _ingresosService.crearIngreso(
              espacioFinancieroId: widget.espacio.id,
              usuarioId: values.usuarioId!,
              categoriaId: values.categoriaId!,
              cuentaId: values.cuentaId,
              concepto: values.concepto,
              valor: values.valor,
              fecha: values.fecha,
              observacion: values.observacion,
            );
          },
          onSuccess: () {
            _markChangedAndRefresh();
            _showMessage('Ingreso registrado correctamente.');
          },
          onError: _showMessage,
        );
      },
    );
  }

  Future<void> _showEditarIngresoDialog(Ingreso ingreso) async {
    final session = await _sessionService.getSession();

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) {
        return _IngresoFormDialog(
          title: 'Editar ingreso',
          submitLabel: 'Guardar',
          espacio: widget.espacio,
          session: session,
          ingreso: ingreso,
          onSubmit: (values) async {
            await _ingresosService.editarIngreso(
              id: ingreso.id,
              categoriaId: values.categoriaId!,
              cuentaId: values.cuentaId,
              concepto: values.concepto,
              valor: values.valor,
              fecha: values.fecha,
              observacion: values.observacion,
            );
          },
          onSuccess: () {
            _markChangedAndRefresh();
            _showMessage('Ingreso editado correctamente.');
          },
          onError: _showMessage,
        );
      },
    );
  }

  Future<void> _confirmarAnularIngreso(Ingreso ingreso) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Anular ingreso'),
          content: Text('¿Deseas anular "${ingreso.concepto}"?'),
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
      await _ingresosService.anularIngreso(ingreso.id);

      if (!mounted) {
        return;
      }

      _markChangedAndRefresh();
      _showMessage('Ingreso anulado correctamente.');
    } on IngresosException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('No se pudo anular el ingreso.');
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
          title: const Text('Ingresos'),
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
                constraints: const BoxConstraints(maxWidth: 720),
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
                      'Ingresos registrados en este espacio.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _showCrearIngresoDialog,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Registrar ingreso'),
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder<List<Ingreso>>(
                      future: _ingresosFuture,
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
                            message: 'No se pudieron cargar los ingresos.',
                            onRetry: _refreshIngresos,
                          );
                        }

                        final ingresos = snapshot.data ?? [];
                        if (ingresos.isEmpty) {
                          return Text(
                            'Aún no hay ingresos registrados.',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          );
                        }

                        return Column(
                          children: ingresos
                              .map(
                                (ingreso) => Card(
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
                                                ingreso.concepto,
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _formatMoney(ingreso.valor),
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
                                          'Fecha: ${_formatDate(ingreso.fecha)}',
                                        ),
                                        Text('Usuario: ${ingreso.usuario}'),
                                        Text(
                                          'Categoría: ${ingreso.categoria}',
                                        ),
                                        if (ingreso.cuenta != null)
                                          Text('Cuenta: ${ingreso.cuenta}'),
                                        if ((ingreso.observacion ?? '')
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(ingreso.observacion!),
                                        ],
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          alignment: WrapAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () {
                                                _showEditarIngresoDialog(
                                                  ingreso,
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                              ),
                                              label: const Text('Editar'),
                                            ),
                                            TextButton.icon(
                                              onPressed: () {
                                                _confirmarAnularIngreso(
                                                  ingreso,
                                                );
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

class _IngresoCatalogos {
  const _IngresoCatalogos({
    required this.usuarios,
    required this.categorias,
    required this.cuentas,
  });

  final List<UsuarioIngreso> usuarios;
  final List<CategoriaIngreso> categorias;
  final List<CuentaIngreso> cuentas;
}

class _IngresoFormValues {
  const _IngresoFormValues({
    required this.usuarioId,
    required this.concepto,
    required this.valor,
    required this.fecha,
    required this.observacion,
    required this.categoriaId,
    required this.cuentaId,
  });

  final int? usuarioId;
  final String concepto;
  final double valor;
  final DateTime fecha;
  final String? observacion;
  final int? categoriaId;
  final int? cuentaId;
}

class _IngresoFormDialog extends StatefulWidget {
  const _IngresoFormDialog({
    required this.title,
    required this.submitLabel,
    required this.espacio,
    required this.session,
    required this.ingreso,
    required this.onSubmit,
    required this.onSuccess,
    required this.onError,
  });

  final String title;
  final String submitLabel;
  final EspacioFinanciero espacio;
  final LoginResponse? session;
  final Ingreso? ingreso;
  final Future<void> Function(_IngresoFormValues values) onSubmit;
  final VoidCallback onSuccess;
  final void Function(String message) onError;

  @override
  State<_IngresoFormDialog> createState() => _IngresoFormDialogState();
}

class _IngresoFormDialogState extends State<_IngresoFormDialog> {
  final _catalogosService = const IngresosCatalogosService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _conceptoController;
  late final TextEditingController _valorController;
  late final TextEditingController _fechaController;
  late final TextEditingController _observacionController;
  late Future<_IngresoCatalogos> _catalogosFuture;
  int? _selectedUsuarioId;
  int? _selectedCategoriaId;
  int? _selectedCuentaId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final ingreso = widget.ingreso;
    final today = DateTime.now();

    _selectedUsuarioId = ingreso?.usuarioId ??
        (widget.espacio.esHogar ? null : widget.session?.usuarioId);
    _selectedCategoriaId = ingreso?.categoriaId;
    _selectedCuentaId = ingreso?.cuentaId;
    _conceptoController = TextEditingController(text: ingreso?.concepto ?? '');
    _valorController = TextEditingController(
      text: ingreso == null ? '' : ingreso.valor.toStringAsFixed(2),
    );
    _fechaController = TextEditingController(
      text: _formatDate(ingreso?.fecha ?? today),
    );
    _observacionController = TextEditingController(
      text: ingreso?.observacion ?? '',
    );
    _catalogosFuture = _loadCatalogos();
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    _valorController.dispose();
    _fechaController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  Future<_IngresoCatalogos> _loadCatalogos() async {
    final categorias = await _catalogosService.listarCategoriasIngreso(
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

    return _IngresoCatalogos(
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

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate() || _isSaving) {
      return;
    }

    if (widget.ingreso == null && _selectedUsuarioId == null) {
      widget.onError('El usuario es requerido.');
      return;
    }

    if (_selectedCategoriaId == null) {
      widget.onError('La categoría es requerida.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSubmit(
        _IngresoFormValues(
          usuarioId: _selectedUsuarioId,
          concepto: _conceptoController.text.trim(),
          valor: double.parse(_valorController.text.trim()),
          fecha: DateTime.parse(_fechaController.text.trim()),
          observacion: _emptyToNull(_observacionController.text),
          categoriaId: _selectedCategoriaId,
          cuentaId: _selectedCuentaId,
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      widget.onSuccess();
    } on IngresosException catch (error) {
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
      widget.onError('No se pudo guardar el ingreso.');
    }
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

  int? _validUsuarioValue(List<UsuarioIngreso> usuarios) {
    return usuarios.any((usuario) => usuario.usuarioId == _selectedUsuarioId)
        ? _selectedUsuarioId
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final ingreso = widget.ingreso;

    return AlertDialog(
      title: Text(widget.title),
      content: FutureBuilder<_IngresoCatalogos>(
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
                  if (ingreso == null && widget.espacio.esHogar)
                    DropdownButtonFormField<int>(
                      initialValue: _validUsuarioValue(catalogos.usuarios),
                      decoration: const InputDecoration(labelText: 'Usuario'),
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
                                _selectedUsuarioId = value;
                              });
                            },
                      validator: (value) => _validateSelected(
                        value,
                        'El usuario es requerido',
                      ),
                    )
                  else
                    TextFormField(
                      enabled: false,
                      initialValue:
                          ingreso?.usuario ?? widget.session?.nombre ?? '',
                      decoration: const InputDecoration(labelText: 'Usuario'),
                    ),
                  const SizedBox(height: 12),
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
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.submitLabel),
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
