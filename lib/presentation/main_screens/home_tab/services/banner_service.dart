import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/models/banner_model.dart';
import 'package:http/http.dart' as http;

class BannerService {
  final String? baseUrl = dotenv.env['BASE_URL'];

  Future<Map<String, String>> getHeaders() async {
    return {
      'Content-Type': 'application/json',
    };
  }

  // ------------------- Main Banners -------------------
  Future<List<BannerModel>> fetchMainBanners() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/homeBanner'), headers: headers);

        print(response.body);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => BannerModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching main banners: $e');
    }
    return [];
  }

  Future<BannerModel?> fetchMainBannerById(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/banners/$id'), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return BannerModel.fromJson(data);
      }
    } catch (e) {
      print('Error fetching main banner by ID: $e');
    }
    return null;
  }

  // ------------------- Home Side Banners -------------------
  Future<List<BannerModel>> fetchSideBanners() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/homeSideBanners'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => BannerModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching side banners: $e');
    }
    return [];
  }

  Future<BannerModel?> fetchSideBannerById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/homeSideBanners/$id'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return BannerModel.fromJson(data);
      }
    } catch (e) {
      print('Error fetching side banner by ID: $e');
    }
    return null;
  }

  // ------------------- Home Bottom Banners -------------------
  Future<List<BannerModel>> fetchBottomBanners() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/homeBottomBanners'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => BannerModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching bottom banners: $e');
    }
    return [];
  }

  Future<BannerModel?> fetchBottomBannerById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/homeBottomBanners/$id'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return BannerModel.fromJson(data);
      }
    } catch (e) {
      print('Error fetching bottom banner by ID: $e');
    }
    return null;
  }
}
