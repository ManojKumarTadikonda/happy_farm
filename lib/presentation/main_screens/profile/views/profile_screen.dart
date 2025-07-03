import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/main_screen.dart';
import 'package:happy_farm/presentation/main_screens/profile/views/contact_screen.dart';
import 'package:happy_farm/presentation/main_screens/profile/views/privacypolicyscreen.dart';
import 'package:happy_farm/presentation/main_screens/profile/views/saved_address.dart';
import 'package:happy_farm/presentation/main_screens/profile/views/update_password.dart';
import 'package:happy_farm/presentation/main_screens/profile/widgets/custom_dialog.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:happy_farm/presentation/auth/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:happy_farm/presentation/main_screens/profile/views/personal_info.dart';
import 'package:flutter/foundation.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:path_provider/path_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String profileImage = '';
  Map<String, dynamic>? _userDetails;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    UserService userService = UserService();
    Map<String, dynamic>? userData = await userService.fetchUserDetails(userId);
    if (userData != null) {
      setState(() {
        _userDetails = userData;
        // Get first image if available
        profileImage =
            (userData['image'] != null && userData['image'].isNotEmpty)
                ? userData['image']
                : '';
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickCropAndUploadImage({
    required bool isEdit,
    String? oldImageUrl, // Required only if editing
  }) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final imageBytes = await pickedFile.readAsBytes();
    final cropController = CropController();
    bool isCropping = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              contentPadding: EdgeInsets.zero,
              content: SizedBox(
                width: 400,
                height: 400,
                child: Stack(
                  children: [
                    Crop(
                      controller: cropController,
                      image: imageBytes,
                      withCircleUi: false,
                      aspectRatio: 1,
                      onCropped: (result) async {
                        switch (result) {
                          case CropSuccess(:final croppedImage):
                            final tempDir = await getTemporaryDirectory();
                            final file =
                                await File('${tempDir.path}/cropped.jpg')
                                    .writeAsBytes(croppedImage);

                            try {
                              final userService = UserService();

                              if (isEdit &&
                                  oldImageUrl != null &&
                                  oldImageUrl.isNotEmpty) {
                                final newUrl = await userService.editImage(
                                  newImageFile: file,
                                );

                                if (newUrl != null) {
                                  setState(() {
                                    profileImage = newUrl;
                                  });
                                }
                              } else {
                                final newUrl =
                                    await userService.uploadProfileImage(file);

                                if (newUrl != null) {
                                  setState(() {
                                    profileImage = newUrl;
                                  });
                                }
                              }

                              Navigator.of(context).pop(); // Close crop dialog

                              showDialog(
                                context: context,
                                builder: (BuildContext dialogContext) {
                                  return AlertDialog(
                                    title: const Text('Success'),
                                    content: Text(isEdit
                                        ? 'Image updated successfully!'
                                        : 'Profile image uploaded successfully!'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(dialogContext)
                                              .pop(); // Close the dialog first
                                          _loadUserDetails();
                                          // Navigate to MainScreen and refresh the Profile tab (index 4)
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  MainScreen(selectedIndex: 4),
                                            ),
                                          );
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            } catch (e) {
                              Navigator.of(context).pop();

                              showDialog(
                                context: context,
                                builder: (BuildContext dialogContext) {
                                  return AlertDialog(
                                    title: const Text('Upload Failed'),
                                    content:
                                        const Text('Failed to process image'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(dialogContext).pop();
                                          Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      MainScreen(
                                                        selectedIndex: 4,
                                                      )));
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                            break;

                          case CropFailure(:final cause):
                            Navigator.of(context).pop();
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text('Crop Failed'),
                                content: Text('Cause: $cause'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            break;
                        }
                      },
                    ),
                    if (isCropping)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() => isCropping = true);
                    cropController.crop();
                  },
                  child: const Text('Crop & Upload'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showImageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Stack(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),

                    // Enlarged Profile Image
                    CircleAvatar(
                      radius: 80, // Increased size
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: profileImage.isNotEmpty
                          ? NetworkImage(profileImage)
                          : const AssetImage('assets/images/profile.png')
                              as ImageProvider,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      profileImage.isNotEmpty
                          ? 'Profile Image'
                          : 'No Profile Uploaded!',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),

                    const SizedBox(height: 24),

                    profileImage.isNotEmpty
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Delete Button
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final userService = UserService();
                                  final success =
                                      await userService.deleteImage();

                                  if (success) {
                                    setState(() {
                                      profileImage = '';
                                    });
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => MainScreen(
                                                  selectedIndex: 4,
                                                )));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Profile image deleted successfully'),
                                      ),
                                    );
                                  } else {
                                    Navigator.of(context).pop();
                                    _loadUserDetails();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Failed to delete profile image'),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.delete,
                                    color: Colors.white),
                                label: const Text("Remove"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),

                              // Edit Button
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _pickCropAndUploadImage(isEdit: true);
                                },
                                icon:
                                    const Icon(Icons.edit, color: Colors.white),
                                label: const Text("Edit"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _pickCropAndUploadImage(isEdit: false);
                            },
                            icon: const Icon(Icons.upload, color: Colors.white),
                            label: const Text("Upload Profile"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Center(child: Text("My Profile")),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(
                    _userDetails?['name'] ?? 'Unknown',
                    _userDetails?['email'] ?? 'Unknown',
                  ),
                  const SizedBox(height: 40),
                  _buildOptions(context),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(String name, String email) {
    return Container(
      padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _showImageDialog();
            },
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: profileImage.isNotEmpty
                        ? NetworkImage(profileImage)
                        : const AssetImage('assets/images/profile.png')
                            as ImageProvider,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildOptions(BuildContext context) {
    final options = [
      {
        'icon': Icons.person_outlined,
        'title': 'Personal Information',
        'subtitle': 'Manage your personal details',
        'function': () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const PersonalInfoScreen()),
          );
          setState(() {}); // Rebuild UI after coming back
        }
      },
      {
        'icon': Icons.person_outlined,
        'title': 'Saved addressess',
        'subtitle': 'Manage your addressess',
        'function': () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => const SavedAddressesScreen()),
          );
          setState(() {}); // Rebuild UI after coming back
        }
      },
      {
        'icon': Icons.lock_outlined,
        'title': 'Security',
        'subtitle': 'Change password',
        'function': () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (builder) => UpdatePassword(),
            ),
          );
        }
      },
      {
        'icon': Icons.help_outline,
        'title': 'Contact & Support',
        'subtitle': 'Get assistance and answers',
        'function': () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => ContactScreen()));
        }
      },
      {
        'icon': Icons.privacy_tip_outlined,
        'title': 'Privacy Policy',
        'subtitle': 'View our privacy practices',
        'function': () {
          // Navigate to the Privacy Policy screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()),
          );
        },
      },
      {
        'icon': Icons.logout,
        'title': 'Logout',
        'subtitle': 'Sign out of your account',
        'function': () {
          showDialog(
            context: context,
            builder: (context) => CustomConfirmDialog(
              title: "Are you sure?",
              message: "Do you really want to log out of your account?",
              onYes: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                  (route) => false,
                );
              },
              onNo: () {
                Navigator.pop(context);
              },
            ),
          );
        }
      }
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          ...options.map((option) => _buildOptionTile(
                context,
                icon: option['icon'] as IconData,
                title: option['title'] as String,
                subtitle: option['subtitle'] as String,
                onTap: option['function'] as VoidCallback,
              )),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.black),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
