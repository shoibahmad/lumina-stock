import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signup() async {
    if (_passwordController.text != _confirmPasswordController.text) {
       ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppTheme.errorRed),
        );
        return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthService>().signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Save user to Firestore for Admin stats
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'displayName': '', 
        });
      }

      if (mounted) {
        Navigator.pop(context); // Go back to Login
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Account Created! Please Login.'), backgroundColor: AppTheme.secondaryGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Signup Failed: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.darkText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.person_add_outlined, size: 50, color: AppTheme.primaryBlue)
                .animate().scale(),
            const SizedBox(height: 20),
            Text(
              'Create Account',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ).animate().fadeIn().slideY(begin: -0.2),
            
            const SizedBox(height: 48),

            TextField(
              controller: _emailController,
              decoration: AppTheme.inputDecoration('Email', Icons.email_outlined),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
            
            const SizedBox(height: 16),
            
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: AppTheme.inputDecoration('Password', Icons.lock_outlined),
            ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

            const SizedBox(height: 16),

            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: AppTheme.inputDecoration('Confirm Password', Icons.lock_outline),
            ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

            const SizedBox(height: 32),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signup,
                style: AppTheme.primaryButtonStyle,
                child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Sign Up'),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}
