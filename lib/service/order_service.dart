import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrderService {
  static const String baseUrl = 'https://happyfarm-server.onrender.com/api';
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Authorization': '$token',
    };
  }

  Future<Map<String, dynamic>?> createOrder({
    required String name,
    required String phoneNumber,
    required String email,
    required String address,
    required String pincode,
  }) async {
    final headers = await _getAuthHeaders();
    final body = jsonEncode({
      'shippingDetails': {
        'name': name,
        'phoneNumber': phoneNumber,
        'address': address,
        'pincode': pincode,
        'email': email,
      }
    });

    final response = await http.post(
      Uri.parse('$baseUrl/payment/create-order'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      print('Failed to create order: ${response.body}');
      return null;
    }
  }

  Future<bool> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String orderId,
  }) async {
    final headers = await _getAuthHeaders();
    final body = jsonEncode({
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
      'paymentHistoryId': orderId,
    });
    final response = await http.post(
      Uri.parse('$baseUrl/payment/verify-order'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['success'] == true;
    } else {
      return false;
    }
  }

  // Fetch all orders for the authenticated user
  Future<List<dynamic>?> fetchAllOrders() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['orders']; // List of orders
      } else {
        print('Failed to fetch orders: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching all orders: $e');
      return null;
    }
  }

  // Fetch a specific order by ID
  Future<Map<String, dynamic>?> fetchOrderById(String orderId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']; // Single order object
      } else {
        print('Failed to fetch order by ID: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching order by ID: $e');
      return null;
    }
  }

  // Add this inside the OrderService class
  Future<Map<String, dynamic>?> cancelOrder(String orderId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/orders/user/cancel/$orderId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('data$data');
        return {
          'success': true,
          'message': data['message'],
          'order': data['data']['order'],
          'refund': data['data']['refund'],
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'],
        };
      }
    } catch (e) {
      print('Error cancelling order: $e');
      return {
        'success': false,
        'message': 'Something went wrong. Please try again later.',
      };
    }
  }

  Future<Map<String, dynamic>?> getRefundDetails({
    String? status,
    String? orderId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
        if (orderId != null) 'orderId': orderId,
      };

      final uri = Uri.parse('$baseUrl/orders/refunds')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to fetch refund details: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching refund details: $e');
      return null;
    }
  }
}