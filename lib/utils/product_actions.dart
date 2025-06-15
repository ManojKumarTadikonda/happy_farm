// lib/utils/product_actions.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../screens/login_screen.dart';  // adjust the path to your LoginScreen file

Future<bool> checkLoginStatus(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final userId = prefs.getString('userId');

  if (token == null || userId == null) {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please log in to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
    return false;
  }
  return true;
}

Future<bool> toggleWishlist(BuildContext context, String productId, bool isWishlist, Function(bool) updateWishlistState) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final userId = prefs.getString('userId');

  if (token == null || userId == null) {
    // Just in case called without checking login, redirect user to login.
    await checkLoginStatus(context);
    return isWishlist; // No change
  }

  final body = {"productId": productId, "userId": userId};

  final response = await http.post(
    Uri.parse("https://api.sabbafarm.com/api/my-list/add"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "$token",
    },
    body: json.encode(body),
  );

  if (response.statusCode == 201) {
    final result = json.decode(response.body);
    final added = result['status'] == 'added';
    updateWishlistState(added);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(added ? "Added to wishlist" : "Removed from wishlist")),
    );

    return added;
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: ${response.statusCode}")),
    );
    return isWishlist; // No change
  }
}
