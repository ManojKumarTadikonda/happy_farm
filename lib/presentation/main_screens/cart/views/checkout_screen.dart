import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:happy_farm/models/user_provider.dart';
import 'package:happy_farm/presentation/auth/widgets/custom_snackba_msg.dart';
import 'package:happy_farm/presentation/main_screens/cart/models/cart_model.dart';
import 'package:happy_farm/presentation/main_screens/cart/views/cart_screen.dart';
import 'package:happy_farm/presentation/main_screens/profile/views/addAddressScreen.dart';
import 'package:happy_farm/presentation/main_screens/cart/views/ordersuccesspage.dart';
import 'package:happy_farm/presentation/main_screens/cart/services/cart_service.dart';
import 'package:happy_farm/presentation/main_screens/profile/services/address_service.dart';
import 'package:happy_farm/presentation/main_screens/orders/services/order_service.dart';
import 'package:happy_farm/presentation/main_screens/profile/widgets/custom_dialog.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:happy_farm/widgets/custom_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final int totalAmount;

  const CheckoutScreen({
    Key? key,
    required this.cartItems,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _orderService = OrderService();
  final _addressService = AddressService();
  bool _isLoading = false;
  late Razorpay _razorpay;
  String? _selectedAddressId;
  String? _defaultAddressLoadingId;
  List<dynamic> _addresses = [];
  dynamic _selectedAddress;
  bool _isLoadingAddresses = false;

  String? userId;
  String? token;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _loadUserData();
    _fetchUserAddresses();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
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

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
  }

  Future<void> _fetchUserAddresses() async {
    setState(() {
      _isLoadingAddresses = true;
    });

    final data = await _addressService.getUserAddresses();

    if (mounted) {
      setState(() {
        _addresses = data?['addresses'] ?? [];
        if (_addresses.isNotEmpty) {
          // Find the default address
          final defaultAddr = _addresses.firstWhere(
            (a) => a['isDefault'] == true,
            orElse: () => _addresses.first,
          );

          _selectedAddress = defaultAddr;
          _selectedAddressId = defaultAddr['_id'];
        }

        _isLoadingAddresses = false;
      });
    }
  }

  void _setLoading(bool value) {
    if (!mounted) return;
    setState(() => _isLoading = value);
  }

  void _showLoader() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54, // dim backdrop
      builder: (_) => const Center(
        child: SizedBox(
          width: 80,
          height: 80,
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12))),
            elevation: 6,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );
  }

  void _hideLoader() {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    _showLoader();
    final verified = await _orderService.verifyPayment(
      razorpayOrderId: response.orderId!,
      razorpayPaymentId: response.paymentId!,
      razorpaySignature: response.signature!,
      orderId: _orderIdFromBackend!,
    );

    if (!mounted) return;
    _hideLoader();
    if (verified) {
      await CartService.clearCart();
      CustomSnackbar.showSuccess(
          context, "Success", "Order placed successfully!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OrderSuccessPage()),
      );
    } else {
      CustomSnackbar.showError(context, "Error", 'Payment verification failed');
      _loadUserData();
      _fetchUserAddresses();
      _isLoading = false;
    }
  }

  Future<void> _handlePaymentError(PaymentFailureResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    final userId=prefs.getString('userId');
    CustomSnackbar.showError(
        context, "Error", 'Payment failed:Please try again later');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => CartScreen()),
    );    
    _loadUserData();
    _fetchUserAddresses();
    _isLoading = false;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  String? _orderIdFromBackend;

  Future<void> _submitOrder() async {
    _setLoading(true);
    if (_selectedAddress == null) {
      CustomSnackbar.showError(
          context, "Error", 'Please select a delivery address');
      return;
    }
    final orderResponse = await _orderService.createOrder(
      name: _selectedAddress['name'],
      phoneNumber: _selectedAddress['phoneNumber'],
      email: _selectedAddress['email'],
      address: _selectedAddress['address'],
      pincode: _selectedAddress['pincode'],
    );

    if (orderResponse != null) {
      final orderData = orderResponse['data'];
      print('manoj$orderResponse');
      _orderIdFromBackend = orderData['paymentHistoryId'];

      var options = {
        'key': dotenv.env['RAZORPAY_KEY'],
        'amount': orderData['razorpayAmount'],
        'currency': orderData['currency'] ?? 'INR',
        'name': 'E-Bharat',
        'description': 'Payment for your order',
        'order_id': orderData['razorpayOrderId'],
        'prefill': {
          'name': _selectedAddress['name'],
          'email': _selectedAddress['email'],
          'contact': _selectedAddress['phoneNumber'],
        },
        'theme': {'color': '#007B4F'}
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        debugPrint('Error opening Razorpay: $e');
      }
    } else {
      CustomSnackbar.showError(
          context, "Error", 'Failed to create order! Please try again later');
    }
    _loadUserData();
    _fetchUserAddresses();
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Checkout"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingAddresses
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? _buildEmptyAddress()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    bool isWide = constraints.maxWidth > 700;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildAddressSelection()),
                                const SizedBox(width: 24),
                                SizedBox(
                                    width: 350, child: _buildOrderSummary()),
                              ],
                            )
                          : Column(
                              children: [
                                _buildAddressSelection(),
                                const SizedBox(height: 24),
                                _buildOrderSummary(),
                              ],
                            ),
                    );
                  },
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
                  final bool isSelected = _selectedAddressId == id;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.shade300,
                        width: isSelected ? 2.0 : 1.2,
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
                      onTap: () {
                        setState(() {
                          _selectedAddress = address;
                          _selectedAddressId = id;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                          showSuccessSnackbar(
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
                        )),
              );
              _fetchUserAddresses();
            },
            icon: const Icon(Icons.add),
            label: const Text("Add New Address"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final cartItems = widget.cartItems;
    final totalAmount = widget.totalAmount;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "YOUR ORDER",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            ...cartItems.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(item.product.name)),
                    Text(
                        '₹${item.product.prices[0].actualPrice} x ${item.quantity}'),
                  ],
                ),
              );
            }).toList(),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹$totalAmount',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const Text(
                          'Loading ...',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        )
                      : const Text(
                          'Place Order',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                )),
          ],
        ),
      ),
    );
  }
}
