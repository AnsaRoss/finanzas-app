import 'package:finanzas_mobile/features/auth/models/login_response.dart';
import 'package:finanzas_mobile/features/auth/screens/login_screen.dart';
import 'package:finanzas_mobile/features/auth/services/session_service.dart';
import 'package:finanzas_mobile/features/dashboard/screens/dashboard_screen.dart';
import 'package:finanzas_mobile/features/espacios/models/espacio_financiero.dart';
import 'package:finanzas_mobile/features/espacios/services/espacios_service.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _sessionService = const SessionService();
  final _espaciosService = const EspaciosService();
  late final Future<LoginResponse?> _sessionFuture;
  late Future<List<EspacioFinanciero>> _espaciosFuture;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _sessionFuture = _sessionService.getSession();
    _espaciosFuture = _espaciosService.getEspacios();
  }

  void _refreshEspacios() {
    setState(() {
      _espaciosFuture = _espaciosService.getEspacios();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openDashboard(EspacioFinanciero espacio) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(espacio: espacio),
      ),
    );
  }

  Future<void> _showCrearHogarDialog() async {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              if (!(formKey.currentState?.validate() ?? false) || isSaving) {
                return;
              }

              final navigator = Navigator.of(dialogContext);

              setDialogState(() {
                isSaving = true;
              });

              try {
                await _espaciosService.crearHogar(
                  nombreController.text.trim(),
                );

                if (!mounted) {
                  return;
                }

                navigator.pop();
                _showMessage('Hogar creado correctamente.');
                _refreshEspacios();
              } on EspaciosException catch (error) {
                if (!mounted) {
                  return;
                }

                setDialogState(() {
                  isSaving = false;
                });
                _showMessage(error.message);
              } catch (_) {
                if (!mounted) {
                  return;
                }

                setDialogState(() {
                  isSaving = false;
                });
                _showMessage('No se pudo crear el hogar.');
              }
            }

            return AlertDialog(
              title: const Text('Crear hogar'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: nombreController,
                  enabled: !isSaving,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'El nombre es requerido';
                    }

                    return null;
                  },
                  onFieldSubmitted: (_) => submit(),
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
                  onPressed: isSaving ? null : submit,
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

    nombreController.dispose();
  }

  Future<void> _showAgregarMiembroDialog(EspacioFinanciero espacio) async {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              if (!(formKey.currentState?.validate() ?? false) || isSaving) {
                return;
              }

              final navigator = Navigator.of(dialogContext);

              setDialogState(() {
                isSaving = true;
              });

              try {
                await _espaciosService.agregarMiembro(
                  espacioId: espacio.id,
                  email: emailController.text.trim(),
                );

                if (!mounted) {
                  return;
                }

                navigator.pop();
                _showMessage('Miembro agregado correctamente.');
              } on EspaciosException catch (error) {
                if (!mounted) {
                  return;
                }

                setDialogState(() {
                  isSaving = false;
                });
                _showMessage(error.message);
              } catch (_) {
                if (!mounted) {
                  return;
                }

                setDialogState(() {
                  isSaving = false;
                });
                _showMessage('No se pudo agregar el miembro.');
              }
            }

            return AlertDialog(
              title: const Text('Agregar miembro'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: emailController,
                  enabled: !isSaving,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: _validateEmail,
                  onFieldSubmitted: (_) => submit(),
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
                  onPressed: isSaving ? null : submit,
                  child: isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'El email es requerido';
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Ingresa un email válido';
    }

    return null;
  }

  Future<void> _signOut() async {
    if (_isSigningOut) {
      return;
    }

    setState(() {
      _isSigningOut = true;
    });

    await _sessionService.clearSession();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finanzas'),
      ),
      body: SafeArea(
        child: FutureBuilder<LoginResponse?>(
          future: _sessionFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final session = snapshot.data;

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Text(
                        'Hola, ${session?.nombre ?? 'usuario'}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        session?.email ?? '',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Espacios financieros',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _showCrearHogarDialog,
                            icon: const Icon(Icons.add_home_outlined),
                            label: const Text('Crear hogar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<EspacioFinanciero>>(
                        future: _espaciosFuture,
                        builder: (context, espaciosSnapshot) {
                          if (espaciosSnapshot.connectionState !=
                              ConnectionState.done) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (espaciosSnapshot.hasError) {
                            return Text(
                              'No se pudieron cargar tus espacios. Intenta nuevamente más tarde.',
                              style: TextStyle(color: colorScheme.error),
                            );
                          }

                          final espacios = espaciosSnapshot.data ?? [];

                          if (espacios.isEmpty) {
                            return Text(
                              'Aún no tienes espacios financieros.',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            );
                          }

                          return Column(
                            children: espacios
                                .map(
                                  (espacio) => Card(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ListTile(
                                          onTap: () {
                                            _openDashboard(espacio);
                                          },
                                          title: Text(espacio.nombre),
                                          subtitle: Text(espacio.tipoLabel),
                                          trailing: const Icon(
                                            Icons.chevron_right,
                                          ),
                                        ),
                                        if (espacio.esHogar)
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              16,
                                              0,
                                              16,
                                              8,
                                            ),
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: TextButton(
                                                onPressed: () {
                                                  _showAgregarMiembroDialog(
                                                    espacio,
                                                  );
                                                },
                                                child: const Text(
                                                  'Agregar miembro',
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      OutlinedButton.icon(
                        onPressed: _isSigningOut ? null : _signOut,
                        icon: _isSigningOut
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.logout_outlined),
                        label: const Text('Cerrar sesión'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
