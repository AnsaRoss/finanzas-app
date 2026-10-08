import 'package:finanzas_mobile/features/auth/services/auth_service.dart';
import 'package:finanzas_mobile/features/auth/services/session_service.dart';
import 'package:finanzas_mobile/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = const AuthService();
  final _sessionService = const SessionService();
  late final TextEditingController _nombreController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate() || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.register(
        nombre: _nombreController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await _sessionService.saveSession(response);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada correctamente.')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
      _showMessage('No se pudo crear la cuenta.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String? _validateRequired(String? value, String message) {
    if ((value ?? '').trim().isEmpty) {
      return message;
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'El correo es requerido';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Ingresa un correo válido';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'La contraseña es requerida';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Confirma la contraseña';
    }

    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Finanzas',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crea tu cuenta para organizar tus finanzas.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nombreController,
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) => _validateRequired(
                        value,
                        'El nombre es requerido',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        suffixIcon: IconButton(
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
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        suffixIcon: IconButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      validator: _validateConfirmPassword,
                      onFieldSubmitted: (_) {
                        _submit();
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Crear cuenta'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      child: const Text('Volver al login'),
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
