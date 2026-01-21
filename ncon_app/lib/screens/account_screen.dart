import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../utils/colors.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart' as app_user;
import 'inbox_screen.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  app_user.User? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    try {
      final userData =
          await _firestoreService.getUser(currentUser.uid);

      if (!mounted) return;
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: "Current Password"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: "New Password"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: "Confirm New Password"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () async {
              if (newPasswordController.text.isEmpty ||
                  confirmPasswordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Please fill all password fields")),
                );
                return;
              }

              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("New passwords do not match")),
                );
                return;
              }

              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text("Password must be at least 6 characters")),
                );
                return;
              }

              try {
                final user =
                    firebase_auth.FirebaseAuth.instance.currentUser!;
                final cred =
                    firebase_auth.EmailAuthProvider.credential(
                  email: user.email!,
                  password: currentPasswordController.text,
                );

                await user.reauthenticateWithCredential(cred);
                await user.updatePassword(newPasswordController.text);

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Password updated successfully")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: ${e.toString()}")),
                );
              }
            },
            child:
                const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCharcoal, // Dark background
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.punchyCoral, width: 3), // Neon Coral Border
          borderRadius: BorderRadius.circular(5), // Sharp corners
        ),
        title: const Text(
          "LOGOUT?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        content: const Text(
          "ARE YOU SURE YOU WANT TO LEAVE THE SESSION?",
          style: TextStyle(color: AppColors.greyText, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL", style: TextStyle(color: AppColors.greyText, fontWeight: FontWeight.w900)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.punchyCoral,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkCharcoal,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title:
            const Text("My Account", style: TextStyle(color: AppColors.neonLime, fontWeight: FontWeight.w900, letterSpacing: 2)),
        shape: const Border(bottom: BorderSide(color: AppColors.neonLime, width: 2)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.neonLime))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // THEMED AVATAR
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(border: Border.all(color: AppColors.neonLime, width: 3)),
              child: Container(
                width: 80, height: 80,
                color: AppColors.neonLime,
                child: const Icon(Icons.person, size: 50, color: Colors.black),
              ),
            ),
            const SizedBox(height: 30),

            // USER INFO TILES
            _buildOptionTile(label: "Name", value: _userData?.name, icon: Icons.person_outline, color: AppColors.electricBlue),
            _buildOptionTile(label: "Email", value: _userData?.email, icon: Icons.email_outlined, color: AppColors.electricBlue),
            _buildOptionTile(label: "CMS ID", value: _userData?.cmsId, icon: Icons.badge_outlined, color: AppColors.electricBlue),

            const SizedBox(height: 20),

            // ACTION TILES
            _buildOptionTile(
              label: "Security",
              value: "CHANGE PASSWORD",
              icon: Icons.lock_outline,
              color: AppColors.electricYellow,
              onTap: _changePassword,
            ),
            _buildOptionTile(
              label: "Session",
              value: "LOGOUT",
              icon: Icons.logout,
              color: AppColors.punchyCoral,
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildOptionTile({
    required String label,
    String? value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(right:4, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: color, width: 2),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(label.toUpperCase(),
            style: const TextStyle(color: AppColors.greyText, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        subtitle: Text(value ?? (onTap != null ? "ACTION" : "NOT SET"),
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
        trailing: onTap != null ? Icon(Icons.arrow_forward_ios, color: color, size: 14) : null,
      ),
    );
  }
}

