import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/main_screen.dart';
import 'package:happy_farm/presentation/main_screens/orders/services/order_service.dart';
import 'package:happy_farm/presentation/main_screens/orders/views/refund_details.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:intl/intl.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Map<String, dynamic>? orderData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrderDetails();
  }

  void _checkRefundStatus(BuildContext context, String orderId) async {
    final refundResponse =
        await OrderService().getRefundDetails(orderId: orderId);

    if (refundResponse != null && refundResponse['success'] == true) {
      final refunds = refundResponse['data']['refunds'] as List<dynamic>;

      final refund = refunds.firstWhere(
        (r) => r['orderId']['_id'] == orderId,
        orElse: () => null,
      );

      if (refund != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RefundDetailsScreen(refundData: refund),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No refund found for this order.')),
        );
      }
    }
  }

  void showLoaderDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents dismiss by tapping outside
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void cancelOrderHandler(BuildContext context, String orderId) async {
    final orderService = OrderService();
    final result = await orderService.cancelOrder(orderId);

    if (result?['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order Cancelled: ${result?['message']}')),
      );
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MainScreen(
                    selectedIndex: 3,
                  )));
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Cancel Failed'),
            content: Text(result?['message'] ?? 'Something went wrong'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  final List<String> cancelReasons = [
    'Ordered by mistake',
    'Found a better price elsewhere',
    'Item is no longer needed',
    'Expected delivery time is too long',
    'Other'
  ];
  String? selectedReason;
  void showCancelReasonSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setStateBottomSheet) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.cancel_outlined,
                            color: Colors.red[600], size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          "Cancel Order",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Please select a reason for cancellation:",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...cancelReasons.map((reason) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedReason == reason
                                  ? Colors.red[400]!
                                  : Colors.grey[300]!,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: selectedReason == reason
                                ? Colors.red[50]
                                : Colors.white,
                          ),
                          child: RadioListTile<String>(
                            value: reason,
                            groupValue: selectedReason,
                            onChanged: (value) {
                              setStateBottomSheet(() {
                                selectedReason = value;
                              });
                            },
                            title: Text(
                              reason,
                              style: TextStyle(
                                fontSize: 15,
                                color: selectedReason == reason
                                    ? Colors.red[700]
                                    : Colors.black87,
                              ),
                            ),
                            activeColor: Colors.red[600],
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 0),
                          ),
                        )),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedReason == null
                                ? null
                                : () async {
                                    Navigator.pop(
                                        context); // Close the bottom sheet
                                    showLoaderDialog(
                                        context); // Show loading spinner
                                    cancelOrderHandler(
                                        context, orderData!['_id']);
                                    Navigator.pop(
                                        context); // Close the loader dialog after API completes
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Confirm Cancel",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> fetchOrderDetails() async {
    try {
      final data = await OrderService().fetchOrderById(widget.orderId);

      setState(() {
        orderData = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading order details: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = AppTheme.primaryColor;
    final String orderStatus =
        orderData?['orderStatus']?.toString().toLowerCase() ?? '';

    final bool isCancelled = orderStatus == 'cancelled';

    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : orderData == null
              ? Center(child: Text('Order not found'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🚀 Order Summary Card
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.receipt_long, color: primaryColor),
                                  SizedBox(width: 8),
                                  Text("Order Summary",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Divider(),
                              buildInfoRow(
                                  "Product Name",
                                  (orderData!['products'] as List)
                                      .map((product) =>
                                          product['productDetails']['name'])
                                      .join(', ')),
                              // 👉 Status with color
                              buildInfoRow(
                                "Status",
                                orderData!['orderStatus'].toString(),
                                fontWeight: FontWeight.bold,
                                valueColor: isCancelled
                                    ? Colors.deepOrange
                                    : Colors.black,
                              ),

                              buildInfoRow(
                                  "Date",
                                  DateFormat('MMM dd, yyyy').format(
                                      DateTime.parse(orderData!['date']))),
                              buildInfoRow(
                                  "Amount", "₹${orderData!['amount']}"),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // 🚀 Customer Info Card
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person, color: primaryColor),
                                  SizedBox(width: 8),
                                  Text("Customer Info",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Divider(),
                              buildInfoRow("Name", orderData!['name']),
                              buildInfoRow("Phone", orderData!['phoneNumber']),
                              buildInfoRow("Email", orderData!['email']),
                              buildInfoRow("Address",
                                  "${orderData!['address']}, ${orderData!['pincode']}"),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // 🚀 Ordered Products List
                      Text("Ordered Products",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor)),
                      SizedBox(height: 8),
                      ...orderData!['products'].map<Widget>((product) {
                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(12),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(product['image'],
                                  width: 60, height: 60, fit: BoxFit.cover),
                            ),
                            title: Text(product['productTitle'],
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text("Quantity: ${product['quantity']}"),
                                Text("Price: ₹${product['orderedPrice']}"),
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 12),

                      // 🚀 If not cancelled, show "Cancel Order" button
                      if (!isCancelled)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: ElevatedButton.icon(
                            onPressed: showCancelReasonSheet,
                            icon: const Icon(Icons.cancel, color: Colors.white),
                            label: const Text(
                              "Cancel Order",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),

                      // 🚀 If cancelled, show "Check Refund Status" button
                      if (isCancelled) ...[
                        Align(
                          alignment: Alignment.bottomRight,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: implement refund status check
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Checking refund status...')),
                              );
                              _checkRefundStatus(context, orderData!['_id']);
                            },
                            icon: const Icon(Icons.money, color: Colors.white),
                            label: const Text(
                              "Check Refund Status",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
    );
  }

  Widget buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    FontWeight fontWeight = FontWeight.normal, // optional with default
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.grey[800],
                fontWeight: fontWeight, // ✅ Apply it here
              ),
            ),
          ),
        ],
      ),
    );
  }
}
