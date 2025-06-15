import 'package:flutter/material.dart';
import 'user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel _user = UserModel();

  UserModel get user => _user;

  void setUser({
    String? username,
    String? email,
    String? phoneNumber,
  }) {
    _user = UserModel(
      username: username ?? _user.username,
      email: email ?? _user.email,
      phoneNumber: phoneNumber ?? _user.phoneNumber,
    );
    notifyListeners();
  }

  void updateUserDetails(UserModel updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  void clearUser() {
    _user = UserModel();
    notifyListeners();
  }
}
