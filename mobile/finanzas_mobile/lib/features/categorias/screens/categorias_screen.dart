import 'package:finanzas_mobile/features/categorias/services/categorias_service.dart';
import 'package:finanzas_mobile/features/espacios/models/espacio_financiero.dart';
import 'package:finanzas_mobile/features/ingresos/models/categoria_ingreso.dart';
import 'package:flutter/material.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({
    required this.espacio,
    super.key,
  });

  final EspacioFinanciero espacio;

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final _categoriasService = const CategoriasService();
  late Future<List<CategoriaIngreso>> _categoriasFuture;

  @override
  void initState() {
    super.initState();
    _categoriasFuture = _loadCategorias();
  }

  Future<List<CategoriaIngreso>> _loadCategorias() {
    return _categoriasService.listarPorEspacio(widget.espacio.id);
  }

  void _refreshCategorias() {
    setState(() {
      _categoriasFuture = _loadCategorias();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _tipoLabel(int tipo) {
    return switch (tipo) {
      1 => 'Ingreso',
      2 => 'Gasto',
      _ => 'Sin tipo',
    };
  }

  Future<void> _showCrearCategoriaDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return _CategoriaFormDialog(
          onSubmit: (values) async {
            await _categoriasService.crear(
              espacioFinancieroId: widget.espacio.id,
              nombre: values.nombre,
              tipo: values.tipo,
            );
          },
          onSuccess: () {
            _refreshCategorias();
            _showMessage('Categoría creada correctamente.');
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
        title: const Text('Categorías'),
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
                    'Categorías de ingresos y gastos del espacio.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _showCrearCategoriaDialog,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Crear categoría'),
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder<List<CategoriaIngreso>>(
                    future: _categoriasFuture,
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
                          message: 'No se pudieron cargar las categorías.',
                          onRetry: _refreshCategorias,
                        );
                      }

                      final categorias = snapshot.data ?? [];
                      if (categorias.isEmpty) {
                        return Text(
                          'Aún no hay categorías registradas.',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        );
                      }

                      return Column(
                        children: categorias
                            .map(
                              (categoria) => Card(
                                child: ListTile(
                                  title: Text(categoria.nombre),
                                  subtitle: Text(
                                    'Tipo: ${_tipoLabel(categoria.tipo)}',
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

class _CategoriaFormValues {
  const _CategoriaFormValues({
    required this.nombre,
    required this.tipo,
  });

  final String nombre;
  final int tipo;
}

class _CategoriaFormDialog extends StatefulWidget {
  const _CategoriaFormDialog({
    required this.onSubmit,
    required this.onSuccess,
    required this.onError,
  });

  final Future<void> Function(_CategoriaFormValues values) onSubmit;
  final VoidCallback onSuccess;
  final void Function(String message) onError;

  @override
  State<_CategoriaFormDialog> createState() => _CategoriaFormDialogState();
}

class _CategoriaFormDialogState extends State<_CategoriaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  int _selectedTipo = 2;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
  }

  @override
  void dispose() {
    _nombreController.dispose();
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
        _CategoriaFormValues(
          nombre: _nombreController.text.trim(),
          tipo: _selectedTipo,
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      widget.onSuccess();
    } on CategoriasException catch (error) {
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
      widget.onError('No se pudo crear la categoría.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear categoría'),
      content: Form(
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
                initialValue: _selectedTipo,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Ingreso')),
                  DropdownMenuItem(value: 2, child: Text('Gasto')),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _selectedTipo = value;
                        });
                      },
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
