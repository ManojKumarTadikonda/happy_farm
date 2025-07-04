class UserModel {
  String? username;
  String? email;
  String? phoneNumber;
  String? image; // Add this field

  UserModel({
    this.username,
    this.email,
    this.phoneNumber,
    this.image, // Add to constructor
  });
}