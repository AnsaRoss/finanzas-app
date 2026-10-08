import 'package:finanzas_mobile/features/auth/models/login_response.dart';
import 'package:finanzas_mobile/features/auth/services/session_service.dart';
import 'package:finanzas_mobile/features/cuentas/models/cuenta_financiera.dart';
import 'package:finanzas_mobile/features/cuentas/models/entidad_financiera.dart';
import 'package:finanzas_mobile/features/cuentas/services/cuentas_service.dart';
import 'package:finanzas_mobile/features/espacios/models/espacio_financiero.dart';
import 'package:finanzas_mobile/features/ingresos/models/usuario_ingreso.dart';
import 'package:finanzas_mobile/features/ingresos/services/ingresos_catalogos_service.dart';
import 'package:flutter/material.dart';

class CuentasScreen extends StatefulWidget {
  const CuentasScreen({
    required this.espacio,
    super.key,
  });

  final EspacioFinanciero espacio;

  @override
  State<CuentasScreen> createState() => _CuentasScreenState();
}

class _CuentasScreenState extends State<CuentasScreen> {
  final _cuentasService = const CuentasService();
  final _sessionService = const SessionService();
  late Future<List<CuentaFinanciera>> _cuentasFuture;

  @override
  void initState() {
    super.initState();
    _cuentasFuture = _loadCuentas();
  }

  Future<List<CuentaFinanciera>> _loadCuentas() {
    return _cuentasService.listarPorEspacio(widget.espacio.id);
  }

  void _refreshCuentas() {
    setState(() {
      _cuentasFuture = _loadCuentas();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showCrearCuentaDialog() async {
    final session = await _sessionService.getSession();

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) {
        return _CuentaFormDialog(
          espacio: widget.espacio,
          session: session,
          onSubmit: (values) async {
            await _cuentasService.crearCuenta(
              espacioFinancieroId: widget.espacio.id,
              propietarioId: values.propietarioId,
              entidadFinancieraId: values.entidadFinancieraId,
              nombre: values.nombre,
              tipo: values.tipo,
            );
          },
          onSuccess: () {
            _refreshCuentas();
            _showMessage('Cuenta creada correctamente.');
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas financieras'),
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
                    'Cuentas del espacio financiero.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _showCrearCuentaDialog,
                    icon: const Icon(Icons.add_card_outlined),
                    label: const Text('Crear cuenta'),
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder<List<CuentaFinanciera>>(
                    future: _cuentasFuture,
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
                          message: 'No se pudieron cargar las cuentas.',
                          onRetry: _refreshCuentas,
                        );
                      }

                      final cuentas = snapshot.data ?? [];
                      if (cuentas.isEmpty) {
                        return Text(
                          'Aún no hay cuentas financieras registradas.',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        );
                      }

                      return Column(
                        children: cuentas
                            .map(
                              (cuenta) => Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        cuenta.nombre,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Tipo: ${cuenta.tipoLabel}'),
                                      Text(
                                        'Propietario: ${cuenta.propietario}',
                                      ),
                                      Text(
                                        'Entidad financiera: ${cuenta.entidadFinanciera ?? 'Sin entidad'}',
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
    );
  }
}

class _CuentaCatalogos {
  const _CuentaCatalogos({
    required this.usuarios,
    required this.entidades,
  });

  final List<UsuarioIngreso> usuarios;
  final List<EntidadFinanciera> entidades;
}

class _CuentaFormValues {
  const _CuentaFormValues({
    required this.propietarioId,
    required this.entidadFinancieraId,
    required this.nombre,
    required this.tipo,
  });

  final int propietarioId;
  final int? entidadFinancieraId;
  final String nombre;
  final int tipo;
}

class _CuentaFormDialog extends StatefulWidget {
  const _CuentaFormDialog({
    required this.espacio,
    required this.session,
    required this.onSubmit,
    required this.onSuccess,
    required this.onError,
  });

  final EspacioFinanciero espacio;
  final LoginResponse? session;
  final Future<void> Function(_CuentaFormValues values) onSubmit;
  final VoidCallback onSuccess;
  final void Function(String message) onError;

  @override
  State<_CuentaFormDialog> createState() => _CuentaFormDialogState();
}

class _CuentaFormDialogState extends State<_CuentaFormDialog> {
  final _cuentasService = const CuentasService();
  final _catalogosService = const IngresosCatalogosService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late Future<_CuentaCatalogos> _catalogosFuture;
  int? _selectedPropietarioId;
  int? _selectedEntidadFinancieraId;
  int _selectedTipo = 2;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedPropietarioId =
        widget.espacio.esHogar ? null : widget.session?.usuarioId;
    _nombreController = TextEditingController();
    _catalogosFuture = _loadCatalogos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<_CuentaCatalogos> _loadCatalogos() async {
    final usuarios = widget.espacio.esHogar
        ? await _catalogosService.listarUsuariosHogar(widget.espacio.id)
        : [
            if (widget.session != null)
              UsuarioIngreso(
                usuarioId: widget.session!.usuarioId,
                usuario: widget.session!.nombre,
              ),
          ];
    final entidades = await _cuentasService.listarEntidadesFinancieras();

    return _CuentaCatalogos(
      usuarios: usuarios,
      entidades: entidades,
    );
  }

  void _retryCatalogos() {
    setState(() {
      _catalogosFuture = _loadCatalogos();
    });
  }

  Future<void> _showCrearEntidadDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var isSaving = false;

    final createdName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nueva entidad financiera'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  enabled: !isSaving,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'El nombre es requerido';
                    }

                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final formState = formKey.currentState;
                          if (formState == null || !formState.validate()) {
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          final nombre = controller.text.trim();
                          try {
                            await _cuentasService.crearEntidadFinanciera(
                              nombre,
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }

                            Navigator.of(dialogContext).pop(nombre);
                          } on CuentasException catch (error) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(() {
                              isSaving = false;
                            });
                            widget.onError(error.message);
                          } catch (_) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(() {
                              isSaving = false;
                            });
                            widget.onError(
                              'No se pudo crear la entidad financiera.',
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (createdName == null || !mounted) {
      return;
    }

    final entidades = await _cuentasService.listarEntidadesFinancieras();
    final created = entidades.where(
      (entidad) => entidad.nombre.toLowerCase() == createdName.toLowerCase(),
    );

    setState(() {
      if (created.isNotEmpty) {
        _selectedEntidadFinancieraId = created.last.id;
      }
      _catalogosFuture = Future.value(
        _CuentaCatalogos(
          usuarios: const [],
          entidades: entidades,
        ),
      ).then((catalogos) async {
        final current = await _loadCatalogos();

        return _CuentaCatalogos(
          usuarios: current.usuarios,
          entidades: catalogos.entidades,
        );
      });
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
        _CuentaFormValues(
          propietarioId: _selectedPropietarioId!,
          entidadFinancieraId: _selectedEntidadFinancieraId,
          nombre: _nombreController.text.trim(),
          tipo: _selectedTipo,
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      widget.onSuccess();
    } on CuentasException catch (error) {
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
      widget.onError('No se pudo crear la cuenta.');
    }
  }

  int? _validUsuarioValue(List<UsuarioIngreso> usuarios) {
    return usuarios.any((usuario) => usuario.usuarioId == _selectedPropietarioId)
        ? _selectedPropietarioId
        : null;
  }

  int? _validEntidadValue(List<EntidadFinanciera> entidades) {
    return entidades.any((entidad) => entidad.id == _selectedEntidadFinancieraId)
        ? _selectedEntidadFinancieraId
        : null;
  }

  bool get _requiereEntidad => _selectedTipo != 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear cuenta'),
      content: FutureBuilder<_CuentaCatalogos>(
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
                  TextFormField(
                    controller: _nombreController,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'El nombre es requerido';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _validUsuarioValue(catalogos.usuarios),
                    decoration: const InputDecoration(labelText: 'Propietario'),
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
                              _selectedPropietarioId = value;
                            });
                          },
                    validator: (value) {
                      if (value == null) {
                        return 'El propietario es requerido';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedTipo,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Efectivo')),
                      DropdownMenuItem(value: 2, child: Text('Ahorros')),
                      DropdownMenuItem(value: 3, child: Text('Corriente')),
                      DropdownMenuItem(
                        value: 4,
                        child: Text('Tarjeta de crédito'),
                      ),
                      DropdownMenuItem(value: 5, child: Text('Otro')),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              _selectedTipo = value;
                              if (!_requiereEntidad) {
                                _selectedEntidadFinancieraId = null;
                              }
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    initialValue: _validEntidadValue(catalogos.entidades),
                    decoration: InputDecoration(
                      labelText: _requiereEntidad
                          ? 'Entidad financiera'
                          : 'Entidad financiera opcional',
                    ),
                    items: [
                      if (!_requiereEntidad)
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Sin entidad'),
                        ),
                      ...catalogos.entidades.map(
                        (entidad) => DropdownMenuItem<int?>(
                          value: entidad.id,
                          child: Text(entidad.nombre),
                        ),
                      ),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() {
                              _selectedEntidadFinancieraId = value;
                            });
                          },
                    validator: (value) {
                      if (_requiereEntidad && value == null) {
                        return 'La entidad financiera es requerida';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _isSaving ? null : _showCrearEntidadDialog,
                      icon: const Icon(Icons.add_business_outlined),
                      label: const Text('Nueva entidad financiera'),
                    ),
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
