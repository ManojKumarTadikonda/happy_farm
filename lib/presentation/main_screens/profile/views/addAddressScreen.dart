import 'package:flutter/material.dart';
import 'package:happy_farm/models/user_provider.dart';
import 'package:happy_farm/presentation/main_screens/profile/services/address_service.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart' as l;

class AddAddressScreen extends StatefulWidget {
  final Map<String, dynamic>? existingAddress;
  const AddAddressScreen({super.key, this.existingAddress});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _landmarkController = TextEditingController();

  String _addressType = 'home';
  bool _isDefault = false;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingAddress != null) {
      final addr = widget.existingAddress!;
      _nameController.text = addr['name'] ?? '';
      _phoneController.text = addr['phoneNumber'] ?? '';
      _emailController.text = addr['email'] ?? '';
      _address1Controller.text = addr['address'] ?? '';
      _cityController.text = addr['city'] ?? '';
      _stateController.text = addr['state'] ?? '';
      _pincodeController.text = addr['pincode'] ?? '';
      _landmarkController.text = addr['landmark'] ?? '';
      _addressType = addr['addressType'] ?? 'home';
      _isDefault = addr['isDefault'] == false;
    } else {
      // Use post-frame callback to safely read Provider in initState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final user = Provider.of<UserProvider>(context, listen: false).user;
        setState(() {
          _nameController.text = user.username!;
          _phoneController.text = user.phoneNumber!;
          _emailController.text = user.email!;
        });
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      final addressService = AddressService();

      final result = await addressService.createAddress(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(), // <== added validator
        address:
            "${_address1Controller.text.trim()}, ${_address2Controller.text.trim()}",
        landmark: _landmarkController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        addressType: _addressType,
        isDefault: _isDefault,
      );

      print('result:$result');
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address created successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create address')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
    }
  }

  Future<void> _updateAddress() async {
    if (_formKey.currentState!.validate()) {
      final addressService = AddressService();

      final result = await addressService.updateAddress(
        addressId: widget.existingAddress!['_id'],
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address:
            "${_address1Controller.text.trim()}, ${_address2Controller.text.trim()}",
        landmark: _landmarkController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        addressType: _addressType,
        isDefault: _isDefault,
      );

      print('update result: $result');
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address updated successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update address')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
    }
  }

  Future<void> _requestLocationPermission() async {
    l.Location location = l.Location();

    bool serviceEnabled;
    l.PermissionStatus permissionGranted;

    // Check if service is enabled
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        print('Location service is disabled.');
        return;
      }
    }

    // Request permission
    permissionGranted = await location.hasPermission();
    if (permissionGranted == l.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != l.PermissionStatus.granted) {
        print('Location permission not granted.');
        return;
      }
    }
    print('Location permission granted.');
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      await _requestLocationPermission();
      loc.Location location = loc.Location();
      loc.LocationData locationData = await location.getLocation();

      double? latitude = locationData.latitude;
      double? longitude = locationData.longitude;

      if (latitude != null && longitude != null) {
        await _getAndSetAddressFromLatLng(latitude, longitude);
        print('Latitude: $latitude, Longitude: $longitude');
      } else {
        print('Could not get location');
      }
    } catch (e) {
      print('Location error: $e');
    } finally {
      setState(() {
        _isLocating = false;
      });
    }
  }

  Future<void> _getAndSetAddressFromLatLng(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        setState(() {
          _address1Controller.text = place.street ?? '';
          _address2Controller.text = place.subLocality ?? '';
          _cityController.text = place.locality ?? '';
          _stateController.text = place.administrativeArea ?? '';
          _pincodeController.text = place.postalCode ?? '';
          _landmarkController.text = place.subThoroughfare ?? '';
        });
      }
    } catch (e) {
      print('Error getting address from lat/lng: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Enter a new address"),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Full name (First and Last name)"),
                  _buildFormTextField(
                    controller: _nameController,
                    label: "Full Name *",
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  _buildSectionTitle("Phone number"),
                  _buildFormTextField(
                    controller: _phoneController,
                    label: "Phone Number *",
                    keyboardType: TextInputType.phone,
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  _buildSectionTitle("Email Address"),
                  _buildFormTextField(
                    controller: _emailController,
                    label: "Email *",
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      return emailRegex.hasMatch(val)
                          ? null
                          : 'Enter a valid email';
                    },
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.only(top: 6, bottom: 16),
                    child: Text(
                      "May be used to assist delivery",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  // Use My Location Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLocating ? null : _getCurrentLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      child: _isLocating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black54),
                              ),
                            )
                          : const Text(
                              "Use my location",
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildSectionTitle("Address"),
                  _buildFormTextField(
                    controller: _address1Controller,
                    label: "Street address or P.O. Box *",
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildFormTextField(
                    controller: _address2Controller,
                    label: "Apt, Suite, Unit, Building (optional)",
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle("City"),
                            _buildFormTextField(
                              controller: _cityController,
                              label: "City *",
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle("State"),
                            _buildFormTextField(
                              controller: _stateController,
                              label: "State *",
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle("Pincode / ZIP"),
                            _buildFormTextField(
                              controller: _pincodeController,
                              label: "Pincode *",
                              keyboardType: TextInputType.number,
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle("Landmark"),
                            _buildFormTextField(
                              controller: _landmarkController,
                              label: "Landmark",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildSectionTitle("Address Type"),
                  _buildAddressTypeDropdown(),
                  const SizedBox(height: 20),

                  _buildSectionTitle("Set as default address"),
                  _buildIsDefaultSwitch(),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.existingAddress == null
                          ? _saveAddress
                          : _updateAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.existingAddress == null
                            ? 'SAVE ADDRESS'
                            : 'UPDATE ADDRESS',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildAddressTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Address Type",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade400),
            color: Colors.grey.shade100,
          ),
          child: DropdownButtonFormField<String>(
            value: _addressType, // should match one of the "value" fields below
            isExpanded: true,
            decoration: const InputDecoration(
              hintText: "Choose address type",
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            ),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
            items: const [
              DropdownMenuItem(value: 'home', child: Text('Home')),
              DropdownMenuItem(value: 'work', child: Text('Work')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (value) {
              setState(() {
                _addressType = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIsDefaultSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Use this as my default address",
          style: TextStyle(fontSize: 16),
        ),
        Switch(
          value: _isDefault,
          onChanged: (value) {
            setState(() {
              _isDefault = value;
            });
          },
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }
}
