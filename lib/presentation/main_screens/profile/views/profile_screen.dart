import 'package:flutter/material.dart';
import 'package:happy_farm/models/user_provider.dart';
import 'package:happy_farm/presentation/main_screens/main_screen.dart';
import 'package:happy_farm/presentation/main_screens/profile/views/contact_screen.dart';
import 'package:happy_farm/presentation/main_screens/profile/views/privacypolicyscreen.dart';
import 'package:happy_farm/presentation/main_screens/profile/views/saved_address.dart';
import 'package:happy_farm/presentation/main_screens/profile/views/update_password.dart';
import 'package:happy_farm/presentation/main_screens/profile/widgets/custom_dialog.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:happy_farm/widgets/custom_snackbar.dart';
import 'package:happy_farm/widgets/without_login_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:happy_farm/presentation/auth/services/user_service.dart';
import 'package:provider/provider.dart';
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
  bool _isImageLoading = false;
  bool _isLoggedIn = false;
  bool _isCheckingLogin = true;
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getString('userId');

      setState(() {
        _isLoggedIn = token != null && userId != null;
        _isCheckingLogin = false;
      });
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _isCheckingLogin = false;
      });
    }
  }

  Future<void> _pickCropAndUploadImage({
    required bool isEdit,
    String? oldImageUrl,
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
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(16),
              content: SizedBox(
                width: 350,
                height: 420,
                child: Column(
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Crop Image',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          onPressed: isCropping
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Crop Area
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
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
                                    final tempDir =
                                        await getTemporaryDirectory();
                                    final file = await File(
                                            '${tempDir.path}/cropped.jpg')
                                        .writeAsBytes(croppedImage);

                                    // Show loading on avatar
                                    if (mounted) {
                                      setState(() {
                                        _isImageLoading = true;
                                      });
                                    }

                                    try {
                                      final userService = UserService();
                                      String? newUrl;

                                      if (isEdit &&
                                          oldImageUrl != null &&
                                          oldImageUrl.isNotEmpty) {
                                        newUrl = await userService.editImage(
                                          newImageFile: file,
                                        );
                                      } else {
                                        newUrl = await userService
                                            .uploadProfileImage(file);
                                      }

                                      if (newUrl != null) {
                                        // Update UserProvider with new image URL
                                        if (mounted) {
                                          Provider.of<UserProvider>(context,
                                                  listen: false)
                                              .updateProfileImage(newUrl);
                                        }
                                      }

                                      // Hide loading
                                      if (mounted) {
                                        setState(() {
                                          _isImageLoading = false;
                                        });
                                      }

                                      Navigator.of(context)
                                          .pop(); // Close crop dialog

                                      if (mounted) {
                                        _showSuccessDialog(isEdit);
                                      }
                                    } catch (e) {
                                      // Hide loading on error
                                      if (mounted) {
                                        setState(() {
                                          _isImageLoading = false;
                                        });
                                      }

                                      Navigator.of(context).pop();

                                      if (mounted) {
                                        _showErrorDialog();
                                      }
                                    }
                                    break;

                                  case CropFailure(:final cause):
                                    Navigator.of(context).pop();
                                    if (mounted) {
                                      _showErrorDialog(
                                          message: 'Crop failed: $cause');
                                    }
                                    break;
                                }
                              },
                            ),
                            if (isCropping)
                              Container(
                                color: Colors.black.withOpacity(0.7),
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Uploading...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 43,
                      child: ElevatedButton(
                        onPressed: isCropping
                            ? null
                            : () {
                                setState(() => isCropping = true);
                                cropController.crop();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isCropping
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Uploading...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Crop & Upload',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSuccessDialog(bool isEdit) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.green.shade600,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Success!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isEdit
                    ? 'Profile image updated successfully!'
                    : 'Profile image uploaded successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog({String? message}) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red.shade600,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Upload Failed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message ?? 'Failed to process image. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showImageDialog() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentImage = userProvider.user.image ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),

                      // Profile Image Container
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(),
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 76,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: currentImage.isNotEmpty
                                ? NetworkImage(currentImage)
                                : const AssetImage('assets/images/profile.png')
                                    as ImageProvider,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Title
                      Text(
                        currentImage.isNotEmpty
                            ? 'Profile Image'
                            : 'Upload Profile Image',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        currentImage.isNotEmpty
                            ? 'Manage your profile picture'
                            : 'Add a profile picture to personalize your account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Action Buttons
                      if (currentImage.isNotEmpty) ...[
                        // Edit and Delete buttons for existing image
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final userService = UserService();
                                  final success =
                                      await userService.deleteImage();

                                  if (success) {
                                    userProvider.updateProfileImage('');
                                    Navigator.of(context).pop();
                                    showSuccessSnackbar(context, 'Profile image deleted successfully');
                                  } else {
                                    Navigator.of(context).pop();
                                    showErrorSnackbar(context,'Failed to delete profile image');
                                  }
                                },
                                icon:
                                    const Icon(Icons.delete_outline, size: 18, color: Colors.red,),
                                label: const Text("Remove"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade50,
                                  foregroundColor: Colors.red.shade600,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side:
                                        BorderSide(color: Colors.red.shade200),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _pickCropAndUploadImage(
                                    isEdit: true,
                                    oldImageUrl: currentImage,
                                  );
                                },
                                icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white,),
                                label: const Text("Edit"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Upload button for no image
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _pickCropAndUploadImage(isEdit: false);
                            },
                            icon: const Icon(Icons.cloud_upload_outlined,
                                size: 20),
                            label: const Text("Upload Image"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                // Close button
                Positioned(
                  top: 12,
                  right: 12,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (_isCheckingLogin) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!_isLoggedIn) {
            return WithoutLoginScreen(
              icon: Icons.person_outline,
              title: 'My Profile',
              subText: 'Login to view and manage your profile settings',
            );
          }

          return Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final user = userProvider.user;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProfileHeader(
                      user.username ?? "Unknown",
                      user.email ?? "Unknown",
                      user.image ?? "",
                    ),
                    const SizedBox(height: 40),
                    _buildOptions(context),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email, String image) {
    return Container(
      padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _showImageDialog();
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: ClipOval(
                      child: image.isNotEmpty
                          ? Image.network(
                              image,
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/profile.png',
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: Image.asset(
                                'assets/images/profile.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                ),
                // Show loading indicator overlay when uploading
                if (_isImageLoading)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.7),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Uploading...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
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
            ),
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
        'title': 'Saved addresses',
        'subtitle': 'Manage your addresses',
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
            MaterialPageRoute(builder: (builder) => UpdatePassword()),
          );
        }
      },
      {
        'icon': Icons.help_outline,
        'title': 'Contact & Support',
        'subtitle': 'Get assistance and answers',
        'function': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ContactScreen()),
          );
        }
      },
      {
        'icon': Icons.privacy_tip_outlined,
        'title': 'Privacy Policy',
        'subtitle': 'View our privacy practices',
        'function': () {
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
                final userProvider =
                    Provider.of<UserProvider>(context, listen: false);
                userProvider.deleteUserDetails();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                  (route) => false,
                );
              },
              onNo: () {
                Navigator.pop(context);
              },
              msg1: 'Cancel',
              msg2:'Logout',
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
          const Text(
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
                color: Colors.green.shade100,
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
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
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