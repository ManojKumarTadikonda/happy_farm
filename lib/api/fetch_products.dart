// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ApiService {
  static const String baseUrl = 'https://api.sabbafarm.com/api';

  // Get all categories
  static Future<List<CategoryModel>> fetchCategories() async {
    final url = '$baseUrl/category';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List data = decoded['categoryList'];
      return data.map((e) => CategoryModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  // Get featured products
  static Future<List<FeaturedProduct>> fetchFeaturedProducts() async {
    final url = '$baseUrl/products/featured';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((product) => FeaturedProduct.fromJson(product)).toList();
    } else {
      throw Exception('Failed to load featured products');
    }
  }

  // Get all products
  static Future<List<AllProduct>> fetchAllProducts() async {
    final url = '$baseUrl/products';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List data = decoded['products'];
      return data.map((e) => AllProduct.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load all products');
    }
  }

  // Filter by category name
  static Future<List<FilterProducts>> fetchProductsByCategory(String catName) async {
    final url = '$baseUrl/products/catName?catName=$catName';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List data = decoded['products'];
      return data.map((e) => FilterProducts.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load products for category: $catName');
    }
  }

  // Filter by price range
  static Future<List<FilterProducts>> filterProductsByPrice({
    required String catId,
    required int minPrice,
    required int maxPrice,
  }) async {
    final url = '$baseUrl/products/filterByPrice?minPrice=$minPrice&maxPrice=$maxPrice&catId=$catId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List data = decoded['products'];
      return data.map((e) => FilterProducts.fromJson(e)).toList();
    } else {
      throw Exception('Failed to filter products by price');
    }
  }

  // Filter by rating
  static Future<List<FilterProducts>> filterProductsByRating({
    required String catId,
    required int rating,
  }) async {
    final url = '$baseUrl/products/rating?catId=$catId&rating=$rating';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List data = decoded['products'];
      return data.map((e) => FilterProducts.fromJson(e)).toList();
    } else {
      throw Exception('Failed to filter products by rating');
    }
  }
}
