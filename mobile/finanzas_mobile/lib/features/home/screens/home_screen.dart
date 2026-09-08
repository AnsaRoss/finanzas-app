import 'package:finanzas_mobile/features/auth/models/login_response.dart';
import 'package:finanzas_mobile/features/auth/screens/login_screen.dart';
import 'package:finanzas_mobile/features/auth/services/session_service.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _sessionService = const SessionService();
  late final Future<LoginResponse?> _sessionFuture;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _sessionFuture = _sessionService.getSession();
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
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final session = snapshot.data;

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
