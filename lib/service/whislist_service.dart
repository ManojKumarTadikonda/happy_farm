import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WishlistService {
  static const String baseUrl =
      'https://happyfarm-server.onrender.com/api/my-list';

  static Future<List<Map<String, dynamic>>> fetchWishlist() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId');
    final String? token = prefs.getString('token');

    if (userId == null || token == null) {
      throw Exception('User not logged in');
    }

    final response = await http.get(
      Uri.parse('$baseUrl?userId=$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final result = json.decode(response.body);
    if (response.statusCode == 200) {
      if (result['success'] == true && result['data'] != null) {
        return List<Map<String, dynamic>>.from(result['data']);
      } else {
        throw Exception(result['message'] ?? 'No data found');
      }
    } else {
      throw Exception(result['message'] ?? 'Failed to load wishlist');
    }
  }

  static Future<bool> removeFromWishlist(String ProductId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/$ProductId');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response.statusCode == 200;
  }

  static Future<String> addToMyList(String productId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/add'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'productId': productId}),
    );

    final result = json.decode(response.body);
    if (response.statusCode == 201 && result['success'] == true) {
      return result['data']['id']; // return wishlist entry ID
    } else {
      throw Exception(result['message'] ?? 'Failed to add to wishlist');
    }
  }

  static Future<Map<String, dynamic>> getItemById(String itemId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/$itemId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final result = json.decode(response.body);
    if (response.statusCode == 200 && result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message'] ?? 'Failed to fetch item');
    }
  }
}