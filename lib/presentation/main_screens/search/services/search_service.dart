import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SearchService {
  final String? baseUrl = '${dotenv.env['BASE_URL']}/search/';

  Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Search products (with optional pagination)
  Future<List<Map<String, dynamic>>> searchProducts(
      {required String query}) async {
    final headers = await getHeaders();

    final Map<String, String> queryParams = {
      'q': query,
    };
    final uri = Uri.parse(baseUrl!).replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);
    final decoded = json.decode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      } else {
        throw Exception("Unexpected response format: Expected a List");
      }
    } else {
      final message = decoded['message'] ?? 'Unexpected error occurred';
      throw Exception('Error ${response.statusCode}: $message');
    }
  }
}
