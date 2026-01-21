import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cmsIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  final AuthService _authService = AuthService();
  bool _isObscured = true;
  bool _isLoading = false;
  String _error = '';
  bool _isSociety = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkCharcoal,
      appBar: AppBar(
        backgroundColor: AppColors.darkCharcoal,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.neonLime),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset(
                  'assets/images/app_logo.png',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.neonLime,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join NUST Community App',
                  style: TextStyle(fontSize: 16, color: AppColors.greyText),
                ),
                const SizedBox(height: 32),

                _buildTextField('Full Name', Icons.person, _nameController),
                const SizedBox(height: 16),
                _buildTextField('CMS ID (6 digits)', Icons.badge, _cmsIdController),
                const SizedBox(height: 16),
                _buildTextField('Email', Icons.email, _emailController),
                const SizedBox(height: 16),
                _buildTextField('Password', Icons.lock, _passwordController, isPassword: true),
                const SizedBox(height: 16),
                _buildTextField('Confirm Password', Icons.lock, _confirmPasswordController, isPassword: true),
                const SizedBox(height: 16),

                CheckboxListTile(
                  title: const Text('Register as a Society', style: TextStyle(color: Colors.white)),
                  value: _isSociety,
                  activeColor: AppColors.neonLime,
                  checkColor: Colors.black,
                  onChanged: (value) {
                    setState(() => _isSociety = value ?? false);
                  },
                ),

                if (_isSociety)
                  const Text(
                    'Note: Society accounts require admin approval.',
                    style: TextStyle(color: AppColors.greyText),
                  ),

                const SizedBox(height: 24),

                if (_error.isNotEmpty)
                  Text(_error, style: const TextStyle(color: AppColors.punchyCoral)),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.black, width: 3),
                        ),
                        margin: const EdgeInsets.only(left: 4, top: 4),
                      ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.electricYellow,
                          disabledBackgroundColor: AppColors.electricYellow.withOpacity(0.5), // Stay visible while loading
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                            side: const BorderSide(color: Colors.black, width: 3),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                            : const Text(
                          'REGISTER',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller,
      {bool isPassword = false}) {
    return TextFormField(
      obscureText: isPassword ? _isObscured : false,
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.greyText),
        prefixIcon: Icon(icon, color: AppColors.electricYellow),
        filled: true,
        fillColor: AppColors.surface,
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _isObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: AppColors.neonLime,
            size: 22,
          ),
          onPressed: () => setState(() => _isObscured = !_isObscured),
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: AppColors.electricYellow, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: AppColors.electricYellow, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (label.contains('CMS')) {
          if (!RegExp(r'^\d{6}$').hasMatch(value)) {
            return 'CMS ID must be 6 digits';
          }
        }
        if (label == 'Email') {
          if (!value.endsWith('@seecs.edu.pk') &&
              !value.endsWith('@nust.edu.pk') &&
              !value.endsWith('@student.nust.edu.pk')) {
            return 'Please use a valid NUST email';
          }
        }
        if (label == 'Confirm Password') {
          if (value != _passwordController.text) {
            return 'Passwords do not match';
          }
        }
        return null;
      },
    );
  }

  // 1. IMPROVED REGISTER FUNCTION
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = ''; // Clear previous errors
    });

    try {
      await _authService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        _cmsIdController.text.trim(),
        isSociety: _isSociety,
      );

      // If it gets here, it's successful!
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));

    } on firebase_auth.FirebaseAuthException catch (e) {
      // THIS IS THE UI PART: Update the _error variable
      setState(() {
        if (e.code == 'email-already-in-use') {
          _error = "THAT EMAIL IS ALREADY REGISTERED. TRY LOGGING IN!";
        } else if (e.code == 'invalid-email') {
          _error = "THE EMAIL FORMAT IS WRONG.";
        } else {
          _error = e.message ?? "REGISTRATION FAILED.";
        }
      });
    } catch (e) {
      setState(() => _error = "AN UNEXPECTED ERROR OCCURRED.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
