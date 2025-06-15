import 'package:flutter/material.dart';
import 'package:happy_farm/utils/app_theme.dart';

class CustomAppBar extends StatelessWidget {
  final VoidCallback onMenuTap;
  final bool showCloseButton;

  const CustomAppBar({
    Key? key,
    required this.onMenuTap,
    this.showCloseButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final appBarHeight = screenHeight * 0.17;

    return Container(
      height: appBarHeight,
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: mediaQuery.padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Close or Menu Button
          IconButton(
            icon: Icon(
              showCloseButton ? Icons.close : Icons.menu,
              color: Colors.white,
            ),
            onPressed: onMenuTap,
          ),

          // Center: Logo + Text
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/sb.png',
                  height: 36,
                  width: 36,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'SabbaFarm',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Right: Cart Icon
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () {
              // Handle cart navigation here
            },
          ),
        ],
      ),
    );
  }
}
