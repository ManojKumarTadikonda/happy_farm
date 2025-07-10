import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/auth/views/welcome_screen.dart';
import 'dart:async';
import 'package:happy_farm/presentation/main_screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:happy_farm/models/user_provider.dart';
import 'package:happy_farm/presentation/auth/services/user_service.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeInController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation =
        CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack);

    _scaleController.forward();

    Future.delayed(const Duration(seconds: 3), () async {
      await _navigateToMainScreen();
    });
  }

  Future<void> _navigateToMainScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');
    final isOpened = prefs.getBool('isopened') ?? false;

    if (isOpened) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen(selectedIndex: 0,)),
        );
      }
      return;
    }

    if (token != null && userId != null) {
      try {
        final userData = await UserService().fetchUserDetails(userId);
        if (userData != null && mounted) {
          Provider.of<UserProvider>(context, listen: false).setUser(
            username: userData['name'] ?? 'No Name',
            email: userData['email'] ?? 'No Email',
            phoneNumber: userData['phone'] ?? 'No Phone',
            image: userData['image'] ?? "",
          );
        }
      } catch (e) {
        debugPrint('Error fetching user data: $e');
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen(selectedIndex: 0,)),
        );
      }
      return;
    }

    // If not logged in and not opened, go to WelcomeScreen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE8F5E9), // very light green
              Color(0xFFB2DFDB), // light teal
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeInController,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 200,
                      width: 200,
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.tealAccent.shade700.withOpacity(0.9)),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.85),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Image.asset(
                          'assets/images/sb.png',
                          height: 100,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                Image.asset(
                  'assets/images/sabba_text.png',
                  height: 50,
                ),
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.teal, Colors.green],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    "Welcome to Sabba Farm",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // masked by gradient
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Loading indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.teal.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Loading...",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.teal.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}