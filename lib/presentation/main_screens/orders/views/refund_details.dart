import 'package:flutter/material.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:intl/intl.dart';

class RefundDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> refundData;

  const RefundDetailsScreen({super.key, required this.refundData});

  String formatDate(String isoDate) {
    final dateTime = DateTime.parse(isoDate);
    return DateFormat('MMM d, yyyy, h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final order = refundData['order'];
    final products = order['products'] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Refund Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: 'Refund Details',
              icon: Icons.receipt_long,
              children: [
                _buildDetailRow('Amount', '₹${refundData['amount']}'),
                _buildDetailRow('Status', refundData['status'],
                    highlight: true),
                _buildDetailRow('Reason', refundData['refundReason']),
                _buildDetailRow(
                    'Refund Date', formatDate(refundData['refundDate'])),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Order Details',
              icon: Icons.shopping_cart_checkout,
              children: [
                _buildDetailRow('Order Amount', '₹${order['amount']}'),
                _buildDetailRow('Order Date', formatDate(order['date'])),
                _buildDetailRow(
                    'Cancelled Date', formatDate(refundData['refundDate'])),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Ordered Products',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product['image'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      product['productTitle'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Quantity: ${product['quantity']}'),
                        Text('Price: ₹${product['price']}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? Colors.deepOrange : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
