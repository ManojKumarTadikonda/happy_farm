import 'package:flutter/material.dart';
import 'package:happy_farm/models/user_model.dart';
import 'package:happy_farm/models/user_provider.dart';
import 'package:happy_farm/presentation/main_screens/profile/services/address_service.dart';
import 'package:happy_farm/service/user_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:happy_farm/presentation/main_screens/profile/views/addAddressScreen.dart';

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
  List<dynamic> _addresses = [];
  dynamic _selectedAddress;
  bool _isLoadingAddresses = false;
  String? userId;

  @override
  void initState() {
    super.initState();
    _getaddress().then((_) {
      _fetchUserAddresses();
    });
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

  Future<void> _getaddress() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
  }

  Future<void> _fetchUserAddresses() async {
    setState(() {
      _isLoadingAddresses = true;
    });

    final _addressService = AddressService();
    final data = await _addressService.getUserAddresses();

    if (mounted) {
      setState(() {
        _addresses = data?['addresses'] ?? [];
        if (_addresses.isNotEmpty) {
          _selectedAddress = _addresses.first;
        }
        _isLoadingAddresses = false;
      });
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

                    /// 🚀 Show addresses here
                    _isLoadingAddresses
                        ? const Center(child: CircularProgressIndicator())
                        : _addresses.isEmpty
                            ? _buildEmptyAddress()
                            : _buildAddressSelection(),
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

  Widget _buildAddressSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "SELECT DELIVERY ADDRESS",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 18),
        _addresses.isEmpty
            ? const Text('No saved addresses. Please add a new address.')
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _addresses.length,
                itemBuilder: (context, index) {
                  final address = _addresses[index];
                  final isSelected = _selectedAddress == address;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAddress = address;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.green.shade700
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? Colors.green.shade700
                                      : Colors.grey.shade500,
                                  size: 24,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        address['name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${address['address']}, ${address['city']}, ${address['state']} - ${address['pincode']}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                          height: 1.4,
                                        ),
                                      ),
                                      if ((address['landmark'] ?? '')
                                          .isNotEmpty)
                                        Text(
                                          'Landmark: ${address['landmark']}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${address['phoneNumber']}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        ' ${address['email']}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: Colors.grey.shade600,
                                size: 22,
                              ),
                              onPressed: () async {
                                // Open edit address screen
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddAddressScreen(
                                      existingAddress: address, // pass this
                                    ),
                                  ),
                                );
                                _fetchUserAddresses(); // reload after edit
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddAddressScreen(
                    existingAddress: null,
                  ),
                ),
              );
              _fetchUserAddresses();
            },
            icon: const Icon(Icons.add_location_alt, size: 20),
            label: const Text(
              "Add New Address",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            style: ElevatedButton.styleFrom(
              elevation: 3,
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyAddress() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "No saved addresses found.",
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddAddressScreen(
                    existingAddress: null,
                  ),
                ),
              );
              _fetchUserAddresses();
            },
            icon: const Icon(Icons.add_location_alt, size: 20),
            label: const Text(
              "Add New Address",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            style: ElevatedButton.styleFrom(
              elevation: 3,
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
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
