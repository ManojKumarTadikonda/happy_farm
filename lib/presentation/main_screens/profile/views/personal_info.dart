import 'package:flutter/material.dart';
import 'package:happy_farm/models/user_model.dart';
import 'package:happy_farm/models/user_provider.dart';
import 'package:happy_farm/presentation/auth/services/user_service.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:happy_farm/widgets/custom_snackbar.dart';
import 'package:provider/provider.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isFetching = true; // for first screen build
  bool _isSaving   = false; // for Save button

  final _nameController  = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;

    _nameController.text  = user.username     ?? '';
    _emailController.text = user.email        ?? '';
    _phoneController.text = user.phoneNumber  ?? '';

    _isFetching = false; // done populating
  }

  Future<void> updatePersonalInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final result = await UserService().updatePersonalInfo(
      name:  _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
    );

    setState(() => _isSaving = false);
    print('maaa$result');
    if (result.containsKey('error')) {
      showErrorSnackbar(context, result['error']);
    } else {
      showSuccessSnackbar(context, 'Details updated successfully!');
      Provider.of<UserProvider>(context, listen: false).updateUserDetails(
        UserModel(
          username:    result['user']['name'],
          email:       result['user']['email'],
          phoneNumber: result['user']['phone'],
          image: result['user']['image']
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Info'),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      icon: Icons.person,
                      label: 'Full Name',
                      validator: (v) =>
                          v!.isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      icon: Icons.email,
                      label: 'Email Address',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v!.contains('@') ? null : 'Enter valid email',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      icon: Icons.phone,
                      label: 'Phone Number',
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v!.length >= 10 ? null : 'Enter valid phone number',
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : updatePersonalInfo,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Save Changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
