import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/cart/models/cart_model.dart';
import 'package:happy_farm/presentation/main_screens/cart/views/checkout_screen.dart';
// import 'package:happy_farm/screens/productdetails_screen.dart';
import 'package:happy_farm/presentation/main_screens/cart/services/cart_service.dart';
import 'package:lottie/lottie.dart';

class CartScreen extends StatefulWidget {
  final String userId;

  const CartScreen({super.key, required this.userId});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<CartItem> _cartItems = [];
  bool _isLoading = true;
  @override
  @override
  void initState() {
    _fetchCart();
    super.initState();
    // Simulate loading for 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
      _isLoading = false;
    });
  }

  void _fetchCart() {
    CartService.fetchCart().then((items) {
      setState(() {
        _cartItems = items;
      });
    });
  }

  void _showLimitDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("OK"),
            )
          ],
        );
      },
    );
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
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
      ),
      body: _isLoading
          ? Center(child: Lottie.asset('assets/lottie/cartloading.json'))
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
                          _buildCouponField(),
                          const SizedBox(height: 12),
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
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      bool success = await CartService.deleteCartItem(item.id);
                      if (success) {
                        setState(() {
                          _cartItems.removeAt(itemIndex);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: item.quantity == 1
                            ? Colors.grey
                            : Colors.deepOrange,
                        onPressed: () {
                          if (item.quantity == 1) {
                            
                          } else {
                            int newQty = item.quantity - 1;
                            setState(() {
                              _cartItems[itemIndex] = CartItem(
                                id: item.id,
                                priceId: item.priceId,
                                userId: item.userId,
                                product: item.product,
                                quantity: newQty,
                                subTotal: actualPrice * newQty,
                              );
                            });
                          }
                        },
                      ),
                      Text(item.quantity.toString()),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: item.quantity == countInStock
                            ? Colors.grey
                            : Colors.green,
                        onPressed: () {
                          if (item.quantity == countInStock) {
                            _showLimitDialog(context, "Stock limit reached",
                                "Cannot add more than available stock.");
                          } else {
                            int newQty = item.quantity + 1;
                            setState(() {
                              _cartItems[itemIndex] = CartItem(
                                id: item.id,
                                priceId: item.priceId,
                                userId: item.userId,
                                product: item.product,
                                quantity: newQty,
                                subTotal: actualPrice * newQty,
                              );
                            });
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

  Widget _buildCouponField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text("Avail Offer (Coupon Code)", style: TextStyle(fontSize: 15)),
          Icon(Icons.arrow_forward_ios, size: 16),
        ],
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
              style: TextStyle(color: Colors.green)),
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
                backgroundColor: Colors.green.shade800,
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
