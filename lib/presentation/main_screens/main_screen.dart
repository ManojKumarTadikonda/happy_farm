import 'package:flutter/material.dart';
import 'package:happy_farm/models/user_provider.dart';
import 'package:happy_farm/presentation/auth/views/login_screen.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/home_screen.dart';
import 'package:happy_farm/presentation/main_screens/orders/views/order_screen.dart';
import 'package:happy_farm/presentation/main_screens/profile/views/profile_screen.dart';
import 'package:happy_farm/presentation/main_screens/search/views/search_screen.dart';
import 'package:happy_farm/presentation/main_screens/wishlist/views/wishlist_screen.dart';
import 'package:happy_farm/presentation/auth/services/user_service.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    // Only fetch user data if logged in
    if (_isLoggedIn) {
      await getUser();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const SearchScreen();
      case 2:
        return const WishlistScreen() ;
      case 3:
        return const OrdersScreen() ;
      case 4:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingLogin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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