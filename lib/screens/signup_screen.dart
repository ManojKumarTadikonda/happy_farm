import 'package:flutter/material.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:happy_farm/screens/login_screen.dart';
import 'package:happy_farm/service/user_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserService _authService = UserService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final result = await _authService.signUp(
      name: _fullNameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

//  SUCCESS case
    if (result?['success'] == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: Text("$result?['message'].Login to expolre"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
// ERROR case
    else {
      final errorMessage = result?['error'] ??
          result?['message'] ??
          'Registration failed. Please try again.';

      // ✅ Show Floating SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData prefixIcon,
      {bool isPassword = false}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(prefixIcon, color: AppTheme.primaryColor),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            )
          : null,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAFBF3), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Image.asset('assets/images/logo.png', height: 80),
                  const SizedBox(height: 24),
                  const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Join Sabba Farm and start your journey',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: _inputDecoration('Full Name', Icons.person),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Full name is required';
                      if (value.length < 3)
                        return 'Full name must be at least 3 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration:
                        _inputDecoration('Phone Number', Icons.phone_android),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Phone number is required';
                      if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                        return 'Enter a valid 10-digit phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('Email', Icons.email),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Email is required';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _inputDecoration('Password', Icons.lock,
                        isPassword: true),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Password is required';
                      if (value.length < 6)
                        return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_errorMessage != null) const SizedBox(height: 20),
                  SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isLoading ? null : _submitForm,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Create Account',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          );
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
