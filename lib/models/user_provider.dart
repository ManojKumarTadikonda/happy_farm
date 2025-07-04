import 'package:flutter/material.dart';
import 'user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel _user = UserModel();

  UserModel get user => _user;

  void setUser({
    String? username,
    String? email,
    String? phoneNumber,
    String? image,
  }) {
    _user = UserModel(
      username: username ?? _user.username,
      email: email ?? _user.email,
      phoneNumber: phoneNumber ?? _user.phoneNumber,
      image: image ?? _user.image,
    );
    notifyListeners();
  }

  void updateUserDetails(UserModel updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  void updateProfileImage(String imageUrl) {
    _user = UserModel(
      username: _user.username,
      email: _user.email,
      phoneNumber: _user.phoneNumber,
      image: imageUrl,
    );
    notifyListeners();
  }

  void clearUser() {
    _user = UserModel(); // resets to default
    notifyListeners();
  }

  void deleteUserDetails() {
    // Clear all user-related details explicitly
    _user = UserModel(
      username: null,
      email: null,
      phoneNumber: null,
      image: null,
    );
    notifyListeners();
  }
}