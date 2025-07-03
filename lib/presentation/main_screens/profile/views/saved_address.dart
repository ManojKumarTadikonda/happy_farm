import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/profile/services/address_service.dart';
import 'package:happy_farm/presentation/main_screens/profile/views/addAddressScreen.dart';
import 'package:happy_farm/utils/app_theme.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({Key? key}) : super(key: key);

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final AddressService _addressService = AddressService();

  List<dynamic> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserAddresses();
  }

  Future<void> _fetchUserAddresses() async {
    if (mounted) setState(() => _isLoading = true);

    final data = await _addressService.getUserAddresses();

    if (!mounted) return;
    setState(() {
      _addresses = data?['addresses'] ?? [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Saved Addresses"),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUserAddresses,
        edgeOffset: 100,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _addresses.isEmpty
                ? _buildEmptyAddress()
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                    child: _buildAddressSelection(),
                  ),
      ),
    );
  }

  Widget _buildAddressSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        _addresses.isEmpty
            ? const Text('No saved addresses. Please add a new address.')
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _addresses.length,
                itemBuilder: (context, index) {
                  final address = _addresses[index];

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 2,
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
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    if ((address['landmark'] ?? '').isNotEmpty)
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
              backgroundColor: AppTheme.primaryColor,
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
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 120),
          Icon(Icons.location_off,
              size: 90, color: Colors.grey.shade400.withOpacity(0.7)),
          const SizedBox(height: 24),
          const Text(
            "No saved addresses yet",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Tap the button below to add a new delivery address.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.black54),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddAddressScreen(
                    existingAddress: null,
                  ),
                ),
              );
              _fetchUserAddresses();
            },
            icon: const Icon(Icons.add_location_alt),
            label: const Text("Add New Address"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
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
}
