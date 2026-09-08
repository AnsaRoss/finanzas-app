import 'package:finanzas_mobile/core/theme/app_theme.dart';
import 'package:finanzas_mobile/features/auth/screens/login_screen.dart';
import 'package:finanzas_mobile/features/auth/services/session_service.dart';
import 'package:finanzas_mobile/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const FinanzasApp());
}

class FinanzasApp extends StatelessWidget {
  const FinanzasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finanzas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _sessionService = const SessionService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _sessionService.getSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final session = snapshot.data;
        if (session != null && session.token.isNotEmpty) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
