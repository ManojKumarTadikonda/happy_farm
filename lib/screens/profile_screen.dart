import 'package:flutter/material.dart';
import 'package:happy_farm/main.dart';
import 'package:happy_farm/models/user_provider.dart';
import 'package:happy_farm/screens/contact_screen.dart';
import 'package:happy_farm/screens/privacypolicyscreen.dart';
import 'package:happy_farm/screens/update_password.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:happy_farm/screens/personal_info.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String profileImage = '';

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Center(child: Text("My Profile")),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(
                user.username ?? 'Unkown', user.email ?? 'Unkown'),
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
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: const CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/images/profile.png'),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                email,
                style: TextStyle(
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
        'function': () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
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
                      color: Colors.green.shade800,
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
