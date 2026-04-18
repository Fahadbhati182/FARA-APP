import 'package:flutter/material.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  static const Color primaryOrange = Color(0xFFFF6B2C);
  static const Color darkOrange = Color(0xFFE85A1A);
  static const Color lightOrange = Color(0xFFFFF3EE);

  void navigate(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(selectedRole: role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: lightOrange,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Image.asset(
                  "assets/app_logo.jpg",
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                "Welcome to FARA",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Choose how you'd like to continue",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade500,
                ),
              ),

              const SizedBox(height: 52),

              // Role Cards
              _RoleCard(
                icon: Icons.person_rounded,
                title: "Customer",
                subtitle: "Browse and book services",
                onTap: () => navigate(context, "customer"),
              ),

              const SizedBox(height: 16),

              _RoleCard(
                icon: Icons.store_rounded,
                title: "Business Owner",
                subtitle: "Manage your business & staff",
                onTap: () => navigate(context, "owner"),
              ),

              const SizedBox(height: 16),

              _RoleCard(
                icon: Icons.work_rounded,
                title: "Worker",
                subtitle: "View your schedule & jobs",
                onTap: () => navigate(context, "worker"),
              ),

              const SizedBox(height: 48),

              Text(
                "Powered by FARA",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  static const Color primaryOrange = Color(0xFFFF6B2C);
  static const Color lightOrange = Color(0xFFFFF3EE);

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: lightOrange,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primaryOrange, size: 26),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: lightOrange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: primaryOrange,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}