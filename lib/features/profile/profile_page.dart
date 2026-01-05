import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = user?.displayName ?? '';
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      if (user != null) {
        // Update Display Name
        if (_nameController.text.isNotEmpty) {
          await user!.updateDisplayName(_nameController.text);
          // Also update Firestore (use set with merge to create if not exists)
          await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
            'displayName': _nameController.text,
            'email': user!.email, // Ensure email is also saved if creating new
            'uid': user!.uid,
          }, SetOptions(merge: true));
        }
        
        // Update Password (if provided)
        if (_passwordController.text.isNotEmpty) {
           await user!.updatePassword(_passwordController.text);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile Updated Successfully!'), backgroundColor: AppTheme.secondaryGreen),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryBlue,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              user?.email ?? 'User',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            
            TextField(
              controller: _nameController,
              decoration: AppTheme.inputDecoration('Display Name', Icons.badge_outlined),
            ),
            const SizedBox(height: 16),
             Text(
              'Leave password blank to keep current one',
              style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: AppTheme.inputDecoration('New Password', Icons.lock_reset),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: AppTheme.primaryButtonStyle,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Update Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
