import 'package:flutter/material.dart';
import 'package:happy_farm/service/order_service.dart';
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
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                                  Text("Order Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Divider(),
                              buildInfoRow("Order ID", orderData!['_id']),
                              buildInfoRow("Status", orderData!['orderStatus'].toString().toUpperCase()),
                              buildInfoRow("Date", DateFormat('MMM dd, yyyy').format(DateTime.parse(orderData!['date']))),
                              buildInfoRow("Amount", "₹${orderData!['amount']}"),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                                  Text("Customer Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Divider(),
                              buildInfoRow("Name", orderData!['name']),
                              buildInfoRow("Phone", orderData!['phoneNumber']),
                              buildInfoRow("Email", orderData!['email']),
                              buildInfoRow("Address", "${orderData!['address']}, ${orderData!['pincode']}"),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text("Ordered Products", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
                      SizedBox(height: 8),
                      ...orderData!['products'].map<Widget>((product) {
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(12),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(product['image'], width: 60, height: 60, fit: BoxFit.cover),
                            ),
                            title: Text(product['productTitle'], style: TextStyle(fontWeight: FontWeight.w600)),
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
                    ],
                  ),
                ),
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 100,
              child: Text("$label:", style: TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }
}
