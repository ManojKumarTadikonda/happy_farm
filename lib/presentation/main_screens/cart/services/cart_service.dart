import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:happy_farm/presentation/main_screens/cart/models/cart_model.dart';

class CartService {
  static String? baseUrl = '${dotenv.env['BASE_URL']}/cart';

  static Future<List<CartItem>> fetchCart() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token == null) {
      throw Exception('Token not found. User might not be logged in.');
    }

    final Uri url = Uri.parse(baseUrl!);

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('daaaa:$data');
      if (data['data'] is List) {
        return (data['data'] as List)
            .map((item) => CartItem.fromJson(item))
            .toList();
      } else {
        throw Exception('Unexpected response format: "data" is not a list');
      }
    } else {
      throw Exception(
          'Failed to load cart: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<String> deleteCartItem(String cartItemId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/$cartItemId');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': token ?? '',
        'Content-Type': 'application/json',
      },
    );
    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body['message'] as String? ?? 'Item deleted.';
    } else {
      final backendMsg = body['message'] ?? body['error'] ?? 'Unknown error';
      throw Exception(backendMsg);
    }
  }

  static Future<Map<String, dynamic>> addToCart({
    required String productId,
    required String priceId,
    required int quantity,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final body = {
      "productId": productId,
      "priceId": priceId,
      "quantity": quantity,
    };

    final response = await http.post(
      Uri.parse("$baseUrl/add"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: json.encode(body),
    );

    print('🛒 addToCart response: ${response.statusCode} - ${response.body}');

    final Map<String, dynamic> data = json.decode(response.body);

    return {
      'success': data['success'] ?? false,
      'message': data['message'] ?? 'Unknown error',
    };
  }

  //Get Cart Item by ID
  static Future<CartItem> getCartItemById(String cartItemId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/$cartItemId');

    final response = await http.get(
      url,
      headers: {
        'Authorization': token ?? '',
        'Content-Type': 'application/json',
      },
    );

    final result = json.decode(response.body);

    if (response.statusCode == 200 && result['success'] == true) {
      return CartItem.fromJson(result['data']);
    } else {
      throw Exception(result['message'] ?? 'Failed to fetch cart item');
    }
  }

  //Update Cart Item (Quantity or PriceId)
  static Future<CartItem> updateCartItem({
    required String cartItemId,
    int? quantity,
    String? priceId,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (quantity == null && priceId == null) {
      throw Exception('Either quantity or priceId must be provided');
    }

    final Map<String, dynamic> body = {};
    if (quantity != null) body['quantity'] = quantity;
    if (priceId != null) body['priceId'] = priceId;

    final response = await http.put(
      Uri.parse('$baseUrl/$cartItemId'),
      headers: {
        'Authorization': token ?? '',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    final result = json.decode(response.body);

    if (response.statusCode == 200 && result['success'] == true) {
      return CartItem.fromJson(result['data']);
    } else {
      throw Exception(result['message'] ?? 'Failed to update cart item');
    }
  }

  /// Clears the user's cart
  static Future<bool> clearCart() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token == null) {
      return false;
    }

    final response = await http.delete(
      Uri.parse("$baseUrl/clear"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    return response.statusCode == 200;
  }
}
