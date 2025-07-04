import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/main_screen.dart';
import 'package:happy_farm/presentation/main_screens/orders/services/order_service.dart';
import 'package:happy_farm/presentation/main_screens/orders/views/refund_details.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:happy_farm/widgets/custom_snackbar.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Map<String, dynamic>? orderData;
  bool isLoading = true;
  bool _isCancelling = false;
  bool _isCheckingRefund = false;
  bool _isDownloadingInvoice = false;

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
        setState(() {
          _isCheckingRefund = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RefundDetailsScreen(refundData: refund),
          ),
        );
      } else {
        setState(() {
          _isCheckingRefund = true;
        });
        showErrorSnackbar(context, "No Refund Details Available");
      }
    }
  }

  // Method to download invoice
  Future<void> _downloadInvoice() async {
    final String? invoiceUrl = orderData?['invoice'];

    if (invoiceUrl == null || invoiceUrl.isEmpty) {
      showErrorSnackbar(context, "Invoice not available");
      return;
    }

    setState(() {
      _isDownloadingInvoice = true;
    });

    try {
      final Uri url = Uri.parse(invoiceUrl);

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        showInfoSnackbar(context, "Opening invoice...");
      } else {
        showErrorSnackbar(context, "Could not open invoice");
      }
    } catch (e) {
      showErrorSnackbar(context, "Error downloading invoice: ${e.toString()}");
    } finally {
      setState(() {
        _isDownloadingInvoice = false;
      });
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
            builder: (
              sheetCtx,
              setStateBottomSheet,
            ) {
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
                            onPressed: selectedReason == null || _isCancelling
                                ? null
                                : () async {
                                    setStateBottomSheet(
                                        () => _isCancelling = true);

                                    final result = await OrderService()
                                        .cancelOrder(orderData!['_id']);

                                    if (!mounted) return;
                                    if (result?['success']) {
                                      showSuccessSnackbar(context,
                                          "Order cancelled successfully");
                                    }
                                    setStateBottomSheet(
                                        () => _isCancelling = false);
                                    Navigator.of(sheetCtx).pop();
                                    // If failed, show dialog BEFORE closing the sheet
                                    if (result?['success'] != true) {
                                      showDialog(
                                        context:
                                            context, // use parent page context
                                        builder: (_) => AlertDialog(
                                          title: const Text('Cancel Failed'),
                                          content: Text(result?['message'] ??
                                              'Something went wrong'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      fetchOrderDetails();
                                    }
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
                            child: _isCancelling
                                ? const Text(
                                    "Canceling ...",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : const Text(
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
        print('mmm${widget.orderId}');
        orderData = data;
        print("mvvv$orderData");
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
    final bool hasInvoice = orderData?['invoice'] != null &&
        orderData!['invoice'].toString().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (builder) => MainScreen(
                selectedIndex: 3,
              ),
            ),
          ),
        ),
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
                                Text("Price: ₹${product['price']}"),
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 16),

                      // 🚀 Action Buttons Row
                      Row(
                        children: [
                          // Download Invoice Button
                          if (hasInvoice)
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: ElevatedButton.icon(
                                  onPressed: _isDownloadingInvoice
                                      ? null
                                      : _downloadInvoice,
                                  icon: _isDownloadingInvoice
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.download,
                                          color: Colors.white, size: 20),
                                  label: Text(
                                    _isDownloadingInvoice
                                        ? "Downloading..."
                                        : "Download Invoice",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                            ),

                          // Cancel Order Button
                          if (!isCancelled &&
                              orderData!['orderStatus'].toString() == 'pending')
                            Expanded(
                              child: Container(
                                margin:
                                    EdgeInsets.only(left: hasInvoice ? 8 : 0),
                                child: ElevatedButton.icon(
                                  onPressed: showCancelReasonSheet,
                                  icon: const Icon(Icons.cancel,
                                      color: Colors.white, size: 20),
                                  label: const Text(
                                    "Cancel Order",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[600],
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                            ),

                          // Check Refund Status Button
                          if (isCancelled)
                            Expanded(
                              child: Container(
                                margin:
                                    EdgeInsets.only(left: hasInvoice ? 8 : 0),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isCheckingRefund = true;
                                    });
                                    _checkRefundStatus(
                                        context, orderData!['_id']);
                                    showInfoSnackbar(
                                        context, 'Checking refund status...');
                                  },
                                  icon: const Icon(Icons.money,
                                      color: Colors.white, size: 20),
                                  label: Text(
                                    _isCheckingRefund
                                        ? "Please wait..."
                                        : "Check Refund",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),
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
