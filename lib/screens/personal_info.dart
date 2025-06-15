import 'package:flutter/material.dart';
import 'package:happy_farm/models/user_model.dart';
import 'package:happy_farm/models/user_provider.dart';
import 'package:happy_farm/service/user_service.dart';
import 'package:provider/provider.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> updatePersonalInfo() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isLoading = true;
  });

  final authService = UserService();
  final result = await authService.updatePersonalInfo(
    name: _nameController.text,
    email: _emailController.text,
    phone: _phoneController.text,
  );

  setState(() {
    _isLoading = false;
  });

  if (result.containsKey('error')) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['error'])),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Details updated successfully!')),
    );
    Provider.of<UserProvider>(context, listen: false).updateUserDetails(
      UserModel(
        username: result['name'],
        email: result['email'],
        phoneNumber: result['phone'],
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    _nameController.text = user.username ?? "";
    _emailController.text = user.email ?? "";
    _phoneController.text = user.phoneNumber ?? "";
    return Scaffold(
      appBar: AppBar(
        title: const Text("Personal Info"),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _nameController.text.isEmpty &&
              _emailController.text.isEmpty &&
              _phoneController.text.isEmpty
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
                      validator: (val) => val!.isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      icon: Icons.email,
                      label: 'Email Address',
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) =>
                          val!.contains('@') ? null : 'Enter valid email',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      icon: Icons.phone,
                      label: 'Phone Number',
                      keyboardType: TextInputType.phone,
                      validator: (val) =>
                          val!.length >= 10 ? null : 'Enter valid phone number',
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : updatePersonalInfo,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Save Changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
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
        prefixIcon: Icon(icon, color: Colors.green.shade700),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green.shade700, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
