import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SubCategoryService {
  final String baseUrl = 'https://api.sabbafarm.com/api/subcategory';

  Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Fetch all subcategories with optional pagination
  Future<Map<String, dynamic>?> fetchSubCategories({int? page, int? perPage}) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse(
        page != null && perPage != null
            ? '$baseUrl?page=$page&perPage=$perPage'
            : baseUrl,
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching subcategories: $e');
      return null;
    }
  }

  /// Get total subcategory count
  Future<int?> fetchSubCategoryCount() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/get/count'), headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['subCatCount'];
      }
      return null;
    } catch (e) {
      print('Error fetching subcategory count: $e');
      return null;
    }
  }

  /// Get a single subcategory by ID
  Future<Map<String, dynamic>?> fetchSubCategoryById(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/$id'), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching subcategory by ID: $e');
      return null;
    }
  }
}
