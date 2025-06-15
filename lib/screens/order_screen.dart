import 'package:flutter/material.dart';
import 'package:happy_farm/main.dart';
import 'package:happy_farm/screens/order_details.dart';
import 'package:happy_farm/service/order_service.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:happy_farm/widgets/order_shimmer.dart';
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
  late TabController _tabController;

  final List<String> statusTabs = ['All', 'pending', 'delivered', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: statusTabs.length, vsync: this);
    fetchOrders();
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Orders"),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: OrderShimmer())
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.green[800],
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.green[800],
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
                          child: Text(
                            'No ${status.toLowerCase()} products',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
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
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        },
        label: Text('Shop More'),
        icon: Icon(Icons.storefront),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final VoidCallback onTap;
  final Map order;

  OrderCard({required this.order, required this.onTap});
  
  void cancelOrderHandler(BuildContext context, String orderId) async {
  final orderService = OrderService();
  final result = await orderService.cancelOrder(orderId);

  if (result?['success'] == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order Cancelled: ${result?['message']}')),
    );
    // Optional: Refresh orders list or navigate back
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cancel Failed: ${result?['message']}')),
    );
  }
}


  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'shipped':
        return Colors.blue;
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
        elevation: 1,
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
                    "ORD${order['_id'].toString().substring(0, 6).toUpperCase()}",
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
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
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
                    color: Colors.green,
                    isBold: true,
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(thickness: 0.8),

              /// Cancel Button
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Cancel Order"),
                        content: const Text("Are you sure you want to cancel this order?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("No"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Yes"),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      cancelOrderHandler(context, order['_id']);
                    }
                  },
                  icon: const Icon(Icons.cancel, color: Colors.white),
                  label: const Text(
                    "Cancel Order",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
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
