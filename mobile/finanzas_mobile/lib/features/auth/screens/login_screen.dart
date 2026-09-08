import 'package:finanzas_mobile/features/auth/models/login_response.dart';
import 'package:finanzas_mobile/features/auth/services/auth_service.dart';
import 'package:finanzas_mobile/features/auth/services/session_service.dart';
import 'package:finanzas_mobile/features/home/screens/home_screen.dart';
import 'package:finanzas_mobile/shared/widgets/app_text_form_field.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = const AuthService();
  final _sessionService = const SessionService();

  LoginResponse? _loginResponse;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loginResponse = response;
      });

      final storedToken = _loginResponse?.token;
      if (storedToken == null || storedToken.isEmpty) {
        throw const AuthException('No se recibió el token de autenticación.');
      }

      await _sessionService.saveSession(response);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicio de sesión correcto')),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error inesperado. Intenta nuevamente.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'El correo electrónico es requerido';
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Ingresa un correo electrónico válido';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'La contraseña es requerida';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: colorScheme.onPrimaryContainer,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'Finanzas',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Organiza tus finanzas personales y del hogar',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 36),
                            AppTextFormField(
                              controller: _emailController,
                              enabled: !_isLoading,
                              labelText: 'Correo electrónico',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 16),
                            AppTextFormField(
                              controller: _passwordController,
                              enabled: !_isLoading,
                              labelText: 'Contraseña',
                              keyboardType: TextInputType.visiblePassword,
                              textInputAction: TextInputAction.done,
                              obscureText: _obscurePassword,
                              validator: _validatePassword,
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              child: _isLoading
                                  ? const SizedBox.square(
                                      dimension: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text('Iniciar sesión'),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _isLoading ? null : () {},
                              child: const Text('Crear cuenta'),
                            ),
                          ],
                        ),
                      ),
                    ),
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
