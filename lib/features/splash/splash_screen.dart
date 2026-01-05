import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../auth/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home/product_list_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    // Simulate loading/check auth
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
             Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProductListPage()),
            );
        } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo / Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Image.asset(
                'assets/images/logo.png',
                 width: 64,
                 height: 64,
              ),
            ).animate()
              .scale(duration: 600.ms, curve: Curves.easeOutBack)
              .fade(),
            
            const SizedBox(height: 24),
            
            // App Name
            Text(
              'Lumina Stock',
              style: AppTheme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),

            const SizedBox(height: 10),

            Text(
              'Premium Inventory Management',
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 48),

            // Loading Indicator
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ).animate().fadeIn(delay: 800.ms),
          ],
        ),
      ),
    );
  }
}
