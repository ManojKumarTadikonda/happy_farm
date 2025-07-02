import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddressService {
  static String? _baseUrl = '${dotenv.env['BASE_URL']}/addresses';

  // COMMON HEADERS
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) throw Exception('Authorization token not found.');

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // CREATE address
  Future<Map<String, dynamic>?> createAddress({
    required String name,
    required String phoneNumber,
    required String email,
    required String address,
    String? landmark,
    required String city,
    required String state,
    required String pincode,
    required String addressType,
    bool? isDefault,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        "name": name,
        "phoneNumber": phoneNumber,
        "email": email,
        "address": address,
        "landmark": landmark ?? "",
        "city": city,
        "state": state,
        "pincode": pincode,
        "addressType": addressType,
        "isDefault": isDefault ?? false
      });

      final response = await http.post(
        Uri.parse(_baseUrl!),
        headers: headers,
        body: body,
      );

      return _handleResponse(response, successStatus: 201);
    } catch (e) {
      print('Error creating address: $e');
      return null;
    }
  }

  // GET user addresses (paginated)
  Future<Map<String, dynamic>?> getUserAddresses({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/user?page=$page&limit=$limit'),
        headers: headers,
      );

      return _handleResponse(response);
    } catch (e) {
      print('Error fetching addresses: $e');
      return null;
    }
  }

  // UPDATE address
  Future<Map<String, dynamic>?> updateAddress({
    required String addressId,
    required String name,
    required String phoneNumber,
    required String email,
    required String address,
    required String landmark,
    required String city,
    required String state,
    required String pincode,
    required String addressType,
    required bool isDefault,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        'name': name,
        'phoneNumber': phoneNumber,
        'email': email,
        'address': address,
        'landmark': landmark,
        'city': city,
        'state': state,
        'pincode': pincode,
        'addressType': addressType,
        'isDefault': isDefault,
      });

      final response = await http.put(
        Uri.parse('$_baseUrl/$addressId'),
        headers: headers,
        body: body,
      );

      return _handleResponse(response);
    } catch (e) {
      print('Error updating address: $e');
      return null;
    }
  }

  // DELETE address
  Future<bool> deleteAddress(String addressId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$_baseUrl/$addressId'),
        headers: headers,
      );

      final data = await _handleResponse(response);
      return data != null;
    } catch (e) {
      print('Error deleting address: $e');
      return false;
    }
  }

  // COMMON response handler
  Map<String, dynamic>? _handleResponse(http.Response response, {int successStatus = 200}) {
    final Map<String, dynamic> responseData = jsonDecode(response.body);

    if (response.statusCode == successStatus && responseData['success'] == true) {
      print('Success response: ${response.body}');
      return responseData['data'];
    } else {
      print('Failed response: ${response.statusCode}, ${response.body}');
      return null;
    }
  }
}
