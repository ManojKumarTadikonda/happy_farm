import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';

class UserService {
  final String? _baseUrl = '${dotenv.env['BASE_URL']}/user';

  //user sign in
  Future<Map<String, dynamic>?> signIn({
    required String phone,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/signin');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone.trim(), 'password': password.trim()}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('userId', data['user']['_id']);
        return data;
      } else {
        return {'error': data['msg'] ?? 'Invalid login'};
      }
    } catch (e) {
      return {'error': 'An error occurred: $e'};
    }
  }

  //Sign Up user
  Future<Map<String, dynamic>?> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/signup');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name.trim(),
          'phone': phone.trim(),
          'email': email.trim(),
          'password': password.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true && data['token']!=null){
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('userId', data['user']['_id']);
        return data;
      } else {
        return {'error': data['msg'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'error': 'An error occurred: $e'};
    }
  }

  //upload Profile
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Authorization token not found.');
      }

      final url = Uri.parse('$_baseUrl/upload-image'); // ✅ Correct endpoint
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // ✅ Correct field name
          imageFile.path,
          filename: basename(imageFile.path),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['success'] == true && data['imageUrl'] != null) {
          // ✅ Correct field
          return data['imageUrl'];
        } else {
          throw Exception('Unexpected response format: $data');
        }
      } else {
        print('Upload failed: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to upload profile image');
      }
    } catch (e) {
      print('Error uploading profile image: $e');
      rethrow;
    }
  }

  //delete profile image
  Future<bool> deleteImage() async {
    final url = Uri.parse('$_baseUrl/delete-image');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Failed to delete image: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error deleting image: $e");
      return false;
    }
  }

//edit Image
  Future<String?> editImage({
    required File newImageFile,
  }) async {
    final url = Uri.parse('$_baseUrl/edit-image');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      var request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          newImageFile.path,
          filename: basename(newImageFile.path),
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        return jsonResponse['imageUrl'];
      } else {
        print('Failed to edit image: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error editing image: $e');
      return null;
    }
  }

  //fetch User Details
  Future<Map<String, dynamic>?> fetchUserDetails(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('$_baseUrl/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('Failed to fetch user details');
      return null;
    }
  }

  //update User Info
  Future<Map<String, dynamic>> updatePersonalInfo({
    required String name,
    required String email,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? token = prefs.getString('token');

    final url = Uri.parse('$_baseUrl/$userId');
    final body = {
      "name": name.trim(),
      "email": email.trim(),
      "phone": phone.trim(),
    };

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print(response.body);
        return jsonDecode(response.body);
      } else {
        return {
          'error':
              'Failed to update details. ${jsonDecode(response.body)['message'] ?? ''}'
        };
      }
    } catch (e) {
      return {'error': 'An error occurred: $e'};
    }
  }

  //Forgot Password
  Future<bool> changeForgotPassword(String email, String newPassword) async {
    final url = Uri.parse('$_baseUrl/forgotPassword/changePassword');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'newPass': newPassword}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  //Update Password
  Future<Map<String, dynamic>> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('token');

    if (token == null || userId == null) {
      return {
        'success': false,
        'message': 'Unauthorized. Please log in again.',
      };
    }

    final url = Uri.parse('$_baseUrl/changePassword/$userId');

    final body = {
      'email': email,
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);
      return {
        'success':
            response.statusCode == 200 && responseData['success'] == true,
        'message': responseData['message'] ?? 'Password change failed.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred. Check your internet connection.',
      };
    }
  }
}
