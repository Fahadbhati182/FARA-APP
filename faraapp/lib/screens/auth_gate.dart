import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'role_selection_screen.dart';
import '../main.dart'; // for CustomerMainNavigation

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: ApiService.isAuthenticated(),
      builder: (context, snapshot) {
        // While waiting for the future
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B2C),
              ),
            ),
          );
        }

        final isAuthenticated = snapshot.data ?? false;

        if (!isAuthenticated) {
          return const RoleSelectionScreen();
        }

        return const CustomerMainNavigation();
      },
    );
  }
}