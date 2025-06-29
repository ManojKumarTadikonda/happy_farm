import 'dart:io';
import 'package:flutter/material.dart';
import 'package:happy_farm/models/user_provider.dart';
import 'package:happy_farm/screens/login_screen.dart';
import 'package:happy_farm/screens/order_screen.dart';
import 'package:happy_farm/screens/profile_screen.dart';
import 'package:happy_farm/screens/search_screen.dart';
import 'package:happy_farm/screens/splash_screen.dart';
import 'package:happy_farm/screens/wishlist_screen.dart';
import 'package:happy_farm/service/user_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:happy_farm/screens/home_screen.dart';
import 'utils/app_theme.dart';
import 'package:location/location.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sabba Farm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(), 
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MainScreen extends StatefulWidget {
  final int selectedIndex;
  const MainScreen({Key? key, this.selectedIndex = 0}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  bool _isCheckingLogin = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _checkLoginStatus();
    getUser();
    _requestLocationPermission(); 
  }

  Future<void> _requestLocationPermission() async {
  Location location = Location();

  bool serviceEnabled;
  PermissionStatus permissionGranted;

  // Check if service is enabled
  serviceEnabled = await location.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) {
      print('Location service is disabled.');
      return;
    }
  }

  // Request permission
  permissionGranted = await location.hasPermission();
  if (permissionGranted == PermissionStatus.denied) {
    permissionGranted = await location.requestPermission();
    if (permissionGranted != PermissionStatus.granted) {
      print('Location permission not granted.');
      return;
    }
  }

  print('Location permission granted.');
}


  Future<void> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId != null) {
      final userData = await UserService().fetchUserDetails(userId);

      if (userData != null) {
        Provider.of<UserProvider>(context, listen: false).setUser(
          username: userData['name'] ?? 'No Name',
          email: userData['email'] ?? 'No Email',
          phoneNumber: userData['phone'] ?? 'No Phone',
        );
      }
    }
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('userId');

    setState(() {
      _isLoggedIn = token != null && userId != null;
      _isCheckingLogin = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingLogin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isLoggedIn) {
      return const LoginScreen(); // Navigate to LoginScreen directly
    }

    Widget _getScreen(int index) {
      switch (index) {
        case 0:
          return const HomeScreen();
        case 1:
          return const SearchScreen();
        case 2:
          return const WishlistScreen();
        case 3:
          return const OrdersScreen();
        case 4:
          return const ProfileScreen();
        default:
          return const HomeScreen();
      }
    }

    return Scaffold(
      body: _getScreen(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 56, 142, 60),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
            ),
          ],
        ),
        child: ClipRRect(
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: Colors.grey,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                activeIcon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border),
                activeIcon: Icon(Icons.favorite),
                label: 'Wishlist',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }
}