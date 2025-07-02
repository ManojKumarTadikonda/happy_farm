import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  static String? baseUrl = '${dotenv.env['BASE_URL']}/productReviews';

  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Fetch all reviews (optionally filter by productId)
  Future<Map<String, dynamic>> getReviews({String? productId}) async {
    final headers = await getHeaders();
    final uri = Uri.parse(productId != null
        ? '$baseUrl?productId=$productId'
        : baseUrl!);

    final response = await http.get(uri, headers: headers);
    return json.decode(response.body);
  }

  /// Fetch total number of reviews (optionally filter by productId)
  Future<Map<String, dynamic>> getReviewCount({String? productId}) async {
    final headers = await getHeaders();
    final uri = Uri.parse(productId != null
        ? '$baseUrl/get/count?productId=$productId'
        : '$baseUrl/get/count');

    final response = await http.get(uri, headers: headers);
    return json.decode(response.body);
  }

  /// Fetch a single review by ID
  Future<Map<String, dynamic>> getReviewById(String reviewId) async {
    final headers = await getHeaders();
    final uri = Uri.parse('$baseUrl/$reviewId');

    final response = await http.get(uri, headers: headers);
    return json.decode(response.body);
  }

  /// Add a new review
  static Future<Map<String, dynamic>> addReview({
    required String productId,
    required String reviewText,
    required int customerRating,
    String? customerName,
  }) async {
    final headers = await getHeaders();  // now valid, both static
    final uri = Uri.parse('$baseUrl/add');

    final body = json.encode({
      'productId': productId,
      'reviewText': reviewText,
      'customerRating': customerRating,
      if (customerName != null) 'customerName': customerName,
    });

    final response = await http.post(uri, headers: headers, body: body);
    return json.decode(response.body);
  }
}
