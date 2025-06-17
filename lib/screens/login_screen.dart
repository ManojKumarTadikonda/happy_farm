import 'package:flutter/material.dart';
import 'package:happy_farm/main.dart';
import 'package:happy_farm/models/user_provider.dart';
import 'package:happy_farm/screens/forgot_pasword.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:happy_farm/screens/signup_screen.dart';
import 'package:happy_farm/service/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserService authService = UserService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await authService.signIn(
      phone: _phoneController.text,
      password: _passwordController.text,
    );

    if (result != null && result['error'] == null) {
      Provider.of<UserProvider>(context, listen: false).setUser(
        username: result['user']['name'],
        email: result['user']['email'],
        phoneNumber: result['user']['phone'],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful!')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (Route<dynamic> route) => false,
      );
    } else {
      setState(() {
        _errorMessage = result?['error'] ?? 'Something went wrong';
      });
    }

    setState(() {
      _isLoading = false;
    });
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
                  const Text('Welcome Back',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('Sign in to continue',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 40),

                  // Phone Field
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration('Phone Number', Icons.phone),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Phone number is required';
                      if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                        return 'Enter a valid 10-digit phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _inputDecoration('Password', Icons.lock,
                        isPassword: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Password is required';
                      if (value.length < 6)
                        return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 6),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ForgotPassWord()));
                      },
                      child: const Text('Forgot Password?',
                          style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _login();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SignUpScreen()));
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold),
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
