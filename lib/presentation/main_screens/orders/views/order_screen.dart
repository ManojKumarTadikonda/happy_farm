import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/orders/views/order_details.dart';
import 'package:happy_farm/presentation/main_screens/orders/services/order_service.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:happy_farm/presentation/main_screens/orders/widgets/order_shimmer.dart';
import 'package:happy_farm/widgets/without_login_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  List orders = [];
  bool isLoading = true;
  bool _isLoggedIn = false;
  late TabController _tabController;
  late Future<void> ordersFuture;
  
  // Enhanced color scheme
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color veryLightGreen = Color(0xFFE8F5E8);
  static const Color textDark = Color(0xFF2C3E50);
  static const Color textMedium = Color(0xFF546E7A);
  
  final List<String> statusTabs = [
    'All',
    'pending',
    'confirm',
    'delivered',
    'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: statusTabs.length, vsync: this);
    ordersFuture = _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    // Check login status first
    await _checkLoginStatus();

    // Only load orders if user is logged in
    if (_isLoggedIn) {
      await fetchOrders();
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');

    setState(() {
      _isLoggedIn = token != null && userId != null;
    });
  }

  Future<void> fetchOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        print("User ID not found in SharedPreferences");
        setState(() => isLoading = false);
        return;
      }

      final response = await OrderService().fetchAllOrders();

      if (response == null) {
        print("No order data received");
        setState(() => isLoading = false);
        return;
      }

      final userOrders = response.toList();

      setState(() {
        orders = userOrders;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text("My Orders"),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<void>(
        future: ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: OrderShimmer());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            // Check if user is not logged in
            if (!_isLoggedIn) {
              return WithoutLoginScreen(
                icon: Icons.receipt_long_outlined,
                title: 'My Orders',
                subText: 'Login to view your orders and track your deliveries',
              );
            }

            // User is logged in, show orders content
            return Column(
              children: [
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppTheme.primaryColor,
                    tabs: statusTabs
                        .map((status) => Tab(text: status.capitalize()))
                        .toList(),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: statusTabs.map((status) {
                      final filteredOrders = status == 'All'
                          ? orders
                          : orders
                              .where((o) =>
                                  o['orderStatus'].toString().toLowerCase() ==
                                  status.toLowerCase())
                              .toList();

                      if (filteredOrders.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: veryLightGreen,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 60,
                                  color: accentGreen,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "No ${status.toLowerCase()} orders",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "You haven't placed any orders yet",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textMedium,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.all(10),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return OrderCard(
                            order: order,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderDetailsPage(
                                      orderId: order['_id'].toString()),
                                ),
                              );
                            },
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final VoidCallback onTap;
  final Map order;

  OrderCard({required this.order, required this.onTap});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'delivered':
        return AppTheme.primaryColor;
      case 'cancelled':
        return Colors.red;
      case 'shipped':
        return Colors.blue;
      case 'confirm':
        return AppTheme.primaryColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'shipped':
        return Icons.local_shipping;
      case 'confirm':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderDate = order['date'] != null
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(order['date']))
        : '';
    final totalAmount =
        double.tryParse(order['amount'].toString())?.toStringAsFixed(2) ??
            '0.00';

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Order ID and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order['orderId'].toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order['orderStatus'] ?? '')
                          .withOpacity(0.1),
                      border: Border.all(
                        color: _getStatusColor(order['orderStatus'] ?? ''),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(order['orderStatus'] ?? ''),
                          color: _getStatusColor(order['orderStatus'] ?? ''),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          order['orderStatus'].toString().capitalize(),
                          style: TextStyle(
                            color: _getStatusColor(order['orderStatus'] ?? ''),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Divider(thickness: 0.8),

              /// Order Info
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _orderInfoTile("Order Date", orderDate),
                  _orderInfoTile("Items",
                      "${(order['products'] as List?)?.length ?? 0} items"),
                  _orderInfoTile(
                    "Total",
                    "₹$totalAmount",
                    color: AppTheme.primaryColor,
                    isBold: true,
                  ),
                ],
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _orderInfoTile(String title, String value,
    {Color color = Colors.black87, bool isBold = false}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
    ],
  );
}

extension StringExtension on String {
  String capitalize() =>
      this.isNotEmpty ? '${this[0].toUpperCase()}${this.substring(1)}' : '';
}