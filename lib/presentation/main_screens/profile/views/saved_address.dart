import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/profile/services/address_service.dart';
import 'package:happy_farm/presentation/main_screens/profile/views/addAddressScreen.dart';
import 'package:happy_farm/presentation/main_screens/profile/widgets/custom_dialog.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:happy_farm/widgets/custom_snackbar.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({Key? key}) : super(key: key);

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final AddressService _addressService = AddressService();

  List<dynamic> _addresses = [];
  bool _isLoading = true;
  String? _selectedAddressId;
  String? _defaultAddressLoadingId;
  @override
  void initState() {
    super.initState();
    _fetchUserAddresses();
  }

  Future<void> _fetchUserAddresses() async {
    setState(() => _isLoading = true);

    final data = await _addressService.getUserAddresses();

    if (!mounted) return;

    setState(() {
      _addresses = data?['addresses'] ?? [];
      _selectedAddressId = _addresses.isNotEmpty
          ? (_addresses.firstWhere((a) => a['isDefault'] == true,
              orElse: () => _addresses[0]))['_id']
          : null;
      _isLoading = false;
    });
  }

  Future<bool> _showDeleteDialog() async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // prevent dismissing by tapping outside
      builder: (ctx) {
        return CustomConfirmDialog(
          title: 'Delete Address?',
          message: 'This action cannot be undone.',
          msg1: 'Cancel',
          msg2: 'Delete',
          onNo: () => Navigator.of(ctx).pop(false),
          onYes: () => Navigator.of(ctx).pop(true),
        );
      },
    );

    return result ?? false;
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
                  final id = address['_id'] as String;
                  final bool isDefault = address['isDefault'] == true;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.04),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _selectedAddressId = id),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /* ─────────── Top row: badge + type + actions ─────────── */
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      address['addressType']?.toLowerCase() ==
                                              'home'
                                          ? Icons.home
                                          : address['addressType']
                                                      ?.toLowerCase() ==
                                                  'work'
                                              ? Icons.work
                                              : Icons.location_on_outlined,
                                      size: 25,
                                      color: Colors.black54,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      (address['addressType'] ?? 'Home')
                                          .toString(),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    isDefault
                                        ? OutlinedButton.icon(
                                            onPressed: null, // disabled
                                            icon: Icon(Icons.check_circle,
                                                color: Colors.blue.shade600,
                                                size: 16),
                                            label: const Text(
                                              "Default",
                                              style: TextStyle(
                                                color: Color(
                                                    0xFF025192), // Same as your custom blue tone
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              disabledForegroundColor:
                                                  Colors.blue.shade600,
                                              side: BorderSide(
                                                  color: Colors.blue.shade300),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 6,
                                                      horizontal: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              backgroundColor:
                                                  Colors.blue.shade50,
                                            ),
                                          )
                                        : OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.blue,
                                              side: const BorderSide(
                                                  color: Colors.blue),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 6,
                                                      horizontal: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                            onPressed:
                                                _defaultAddressLoadingId == id
                                                    ? null
                                                    : () async {
                                                        setState(() =>
                                                            _defaultAddressLoadingId =
                                                                id);
                                                        final res =
                                                            await _addressService
                                                                .setDefaultAddress(
                                                                    id);
                                                        if (!mounted) return;
                                                        setState(() =>
                                                            _defaultAddressLoadingId =
                                                                null);
                                                        if (res['success']) {
                                                          showSuccessSnackbar(
                                                              context,
                                                              res['message']);
                                                          _fetchUserAddresses();
                                                        } else {
                                                          showErrorSnackbar(
                                                              context,
                                                              res['message']);
                                                        }
                                                      },
                                            child: _defaultAddressLoadingId ==
                                                    id
                                                ? Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: const [
                                                      SizedBox(
                                                          width: 14,
                                                          height: 14,
                                                          child:
                                                              CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2)),
                                                      SizedBox(width: 6),
                                                      Text('Setting...',
                                                          style: TextStyle(
                                                              fontSize: 13)),
                                                    ],
                                                  )
                                                : const Text('Set As Default',
                                                    style: TextStyle(
                                                        fontSize: 13)),
                                          ),
                                    const SizedBox(width: 8),
                                    _squareIconButton(
                                      icon: Icons.edit,
                                      bgColor: Colors.green,
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AddAddressScreen(
                                                existingAddress: address),
                                          ),
                                        );
                                        _fetchUserAddresses();
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _squareIconButton(
                                      icon: Icons.delete,
                                      bgColor: Colors.red,
                                      onTap: () async {
                                        final confirm =
                                            await _showDeleteDialog();
                                        if (!confirm) return;
                                        final res = await _addressService
                                            .deleteAddress(id);
                                        if (res['success']) {
                                          _fetchUserAddresses();
                                          showSuccessSnackbar(
                                              context, res['message']);
                                        } else {
                                          showErrorSnackbar(
                                              context, res['message']);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(address['name'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold)),
                                ),
                                Text(address['phoneNumber'] ?? '',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700)),
                              ],
                            ),
                            if ((address['email'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(address['email'],
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black54)),
                            ],
                            const SizedBox(height: 6),
                            Text(address['address'] ?? '',
                                style: const TextStyle(fontSize: 14)),
                            Text(
                              '${address['city']}, ${address['state']} - ${address['pincode']}',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
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

  Widget _squareIconButton({
    required IconData icon,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
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
