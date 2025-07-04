import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/main_screen.dart';
import 'package:happy_farm/presentation/auth/services/user_service.dart';
import 'package:happy_farm/utils/app_theme.dart';

class ForgotPassWord extends StatefulWidget {
  const ForgotPassWord({Key? key}) : super(key: key);

  @override
  State<ForgotPassWord> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ForgotPassWord> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordControler =TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
Future<void> _changePassword(String email) async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  final newPassword = _newPasswordController.text.trim();

  try {
    final success = await UserService().changeForgotPassword(email, newPassword);

    if (success) {
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainScreen()),
      );
    } else {
      
    }
  } catch (e) {
    print('Error: $e');
    setState(() {
      _errorMessage = 'An unexpected error occurred.';
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


  InputDecoration _inputDecoration(String label, IconData prefixIcon,
      {bool isPassword = false}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.grey[600],
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: AppTheme.primaryColor,
        size: 22,
      ),
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
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      // Add a subtle shadow effect
      floatingLabelBehavior: FloatingLabelBehavior.auto,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', height: 80),

                const SizedBox(height: 24),
                const Text(
                  'Change Password',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 40),

                // Enhanced Text Fields with decorative container
                Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: _inputDecoration(
                          'Your email', Icons.lock_outline,
                          isPassword: true),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration(
                          'New Password', Icons.lock_outline,
                          isPassword: true),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _confirmPasswordControler,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration(
                          'Confirm Password', Icons.lock_outline,
                          isPassword: true),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                if (_errorMessage != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                if (_errorMessage != null)
                  SizedBox(
                    height: 20,
                  ),

                // Enhanced Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A64F),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: AppTheme.primaryColor.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () {
                            final email = _emailController.text.trim();
                            final newPwd = _newPasswordController.text.trim();
                            final confirmPwd =
                                _confirmPasswordControler.text.trim();

                            if (email.isEmpty ||
                                newPwd.isEmpty ||
                                confirmPwd.isEmpty) {
                              setState(() =>
                                  _errorMessage = 'All fields are required.');
                              return;
                            }

                            if (newPwd != confirmPwd) {
                              setState(() =>
                                  _errorMessage = 'Passwords do not match.');
                              return;
                            }

                            _changePassword(email);
                          },
                    child: _isLoading
                        ?const Text(
                            'Loading ...',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w600),
                          )
                        : const Text(
                            'Change Password',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
