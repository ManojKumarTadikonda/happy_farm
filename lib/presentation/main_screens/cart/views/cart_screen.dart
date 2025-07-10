import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/cart/models/cart_model.dart';
import 'package:happy_farm/presentation/main_screens/cart/views/checkout_screen.dart';
// import 'package:happy_farm/screens/productdetails_screen.dart';
import 'package:happy_farm/presentation/main_screens/cart/services/cart_service.dart';
import 'package:happy_farm/presentation/main_screens/main_screen.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:happy_farm/widgets/custom_snackbar.dart';
import 'package:happy_farm/widgets/without_login_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartScreen extends StatefulWidget {

  const CartScreen({super.key,});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<CartItem> _cartItems = [];
  bool _isLoading = true;
  bool _isLoggedIn = false;
  Set<String> _updatingItemIds = {};
  Set<String> _deletingItemIds = {};
  Set<String> _updatingAdd = {};
  Set<String> _updatingRemove = {};

  @override
  void initState() {
    super.initState();
    _checkLoginAndFetchCart();
  }

  Future<void> _checkLoginAndFetchCart() async {
    // Check if user is logged in
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');

    setState(() {
      _isLoggedIn = token != null && userId != null;
    });

    if (_isLoggedIn) {
      _fetchCart();
    } else {
      // If not logged in, just stop loading
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _fetchCart() {
    CartService.fetchCart().then((items) {
      setState(() {
        _cartItems = items;
        _isLoading = false;
      });
    }).catchError((error) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _handleUpdateCartItem({
    required String cartItemId,
    int? newQuantity,
    String? newPriceId,
  }) async {
    setState(() => _updatingItemIds.add(cartItemId));

    try {
      final updated = await CartService.updateCartItem(
        cartItemId: cartItemId,
        quantity: newQuantity,
        priceId: newPriceId,
      );

      final index = _cartItems.indexWhere((e) => e.id == cartItemId);
      if (index != -1) {
        setState(() => _cartItems[index] = updated);
      }
      showSuccessSnackbar(context, "Cart Updated");
    } catch (e) {
      showErrorSnackbar(context, '$e');
    } finally {
      if (mounted) {
        setState(() => _updatingItemIds.remove(cartItemId));
      }
    }
  }

  int _calculateTotal() {
    return _cartItems.fold(0, (sum, item) => sum + item.subTotal.toInt());
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(245, 245, 245, 1),
      appBar: AppBar(
        title: const Text("My Cart"),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (builder) => MainScreen(
                selectedIndex: 0,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: Lottie.asset('assets/lottie/cartloading.json'))
          : !_isLoggedIn
              ? WithoutLoginScreen(
                title: 'cart',
                subText: 'Login to add products to your cart and mange your orders',
                icon: Icons.shopping_cart_outlined,
              )
              : _cartItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Lottie.asset('assets/lottie/emptyCart.json'),
                          SizedBox(
                              height: 16), // spacing between animation and text
                          Text(
                            'Your cart is empty!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(12),
                            children: [
                              ..._cartItems
                                  .map((item) => _buildCartItem(item))
                                  .toList(),
                              const SizedBox(height: 16),
                              _buildPaymentDetails(
                                  _cartItems.length, _calculateTotal()),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                        _buildBottomBar(_calculateTotal()),
                      ],
                    ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    int itemIndex = _cartItems.indexOf(item);
    int countInStock = item.product.prices.first.countInStock;
    double actualPrice = item.product.prices.first.actualPrice;

    return GestureDetector(
      onTap: () {
        // Navigator.of(context).push(MaterialPageRoute(
        //   builder: (_) => ProductDetails(product: item.product),
        // ));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.product.images.first,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₹${actualPrice.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Subtotal: ₹${item.subTotal.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: _deletingItemIds.contains(item.id)
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red,
                            ),
                          )
                        : const Icon(Icons.delete, color: Colors.red),
                    onPressed: _deletingItemIds.contains(item.id)
                        ? null // disable while this item is deleting
                        : () async {
                            setState(() {
                              _deletingItemIds.add(item.id);
                            });

                            try {
                              final msg =
                                  await CartService.deleteCartItem(item.id);

                              if (mounted) {
                                showSuccessSnackbar(context, msg);
                                _fetchCart(); // Optionally reload cart
                              }
                            } catch (e) {
                              if (mounted) {
                                showErrorSnackbar(context, '$e');
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _deletingItemIds.remove(item.id);
                                });
                              }
                            }
                          },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        icon: _updatingRemove.contains(item.id)
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.remove_circle_outline),
                        color: item.quantity == 1
                            ? Colors.grey
                            : AppTheme.primaryColor,
                        onPressed: (item.quantity == 1 ||
                                _updatingRemove.contains(item.id))
                            ? null
                            : () async {
                                final newQty = item.quantity - 1;

                                setState(() => _updatingRemove.add(item.id));

                                try {
                                  final updatedItem =
                                      await CartService.updateCartItem(
                                    cartItemId: item.id,
                                    quantity: newQty,
                                  );
                                  setState(() {
                                    _cartItems[itemIndex] = updatedItem;
                                  });
                                } catch (e) {
                                  showErrorSnackbar(context, '$e');
                                } finally {
                                  if (mounted) {
                                    setState(
                                        () => _updatingRemove.remove(item.id));
                                  }
                                }
                              },
                      ),
                      Text(item.quantity.toString()),
                      IconButton(
                        icon: _updatingAdd.contains(item.id)
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add_circle_outline),
                        color: item.quantity == countInStock
                            ? Colors.grey
                            : Colors.deepOrange,
                        onPressed: (item.quantity == countInStock ||
                                _updatingAdd.contains(item.id))
                            ? null
                            : () async {
                                final newQty = item.quantity + 1;

                                setState(() => _updatingAdd.add(item.id));

                                try {
                                  final updatedItem =
                                      await CartService.updateCartItem(
                                    cartItemId: item.id,
                                    quantity: newQty,
                                  );
                                  setState(() {
                                    _cartItems[itemIndex] = updatedItem;
                                  });
                                } catch (e) {
                                  showErrorSnackbar(context, '$e');
                                } finally {
                                  if (mounted) {
                                    setState(
                                        () => _updatingAdd.remove(item.id));
                                  }
                                }
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentDetails(int itemCount, int total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Payment Details",
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _paymentRow("Price ($itemCount items)", total),
          _paymentRow("Discount", 0),
          _paymentRow("Delivery Charges", "FREE"),
          const Divider(),
          _paymentRow("Total Amount", total, isBold: true),
          const SizedBox(height: 6),
          const Text("You saved ₹120 on this order",
              style: TextStyle(color: AppTheme.primaryColor)),
        ],
      ),
    );
  }

  Widget _paymentRow(String title, dynamic value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value is String ? value : "₹$value",
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(int total) {
    return SafeArea(
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                text: "₹$total\n",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                children: const [
                  TextSpan(
                    text: "View price details",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final totalAmount = _cartItems.fold(
                    0, (sum, item) => sum + item.subTotal.toInt());
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutScreen(
                      cartItems: _cartItems,
                      totalAmount: totalAmount,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Proceed"),
            ),
          ],
        ),
      ),
    );
  }
}