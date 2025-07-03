import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(uri)) {
      debugPrint("❌ Could not launch phone call to $phoneNumber");
    }
  }

  Future<void> _launchWhatsApp(String number) async {
    final Uri uri = Uri.parse('https://wa.me/$number');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("❌ Could not launch WhatsApp");
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("❌ Could not launch URL: $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Center(child: Text("Contact Us")),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCardTile(
              context,
              iconWidget: Brand(Brands.phone, size: 24),
              title: "Missed Call To Order",
              subtitle: "Call us directly to place an order",
              actionLabel: "9866113858",
              onTap: () => _launchPhone('9866113858'),
            ),
            _buildCardTile(
              context,
              iconWidget: Brand(Brands.whatsapp, size: 24),
              title: "Whatsapp Number",
              subtitle: "Contact through message in WhatsApp",
              actionLabel: "9171749999",
              onTap: () => _launchWhatsApp("9171749999"),
            ),
            _buildCardTile(
              context,
              iconWidget: Brand(Brands.google_maps, size: 24),
              title: "Company",
              subtitle: "Sri Santhosh Sowjanya Agencies (SabbaFarm)",
              actionLabel: "Since 2006",
              onTap: () {}, // Optional: add Google Maps launch here
            ),
            const SizedBox(height: 20),
            _buildSocialLinks(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTile(
    BuildContext context, {
    required Widget iconWidget,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: iconWidget,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 14, color: AppTheme.primaryColor)),
                ],
              ),
            ),
            Text(
              actionLabel,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Connect With Us",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSocialButton(
              icon: Icons.facebook,
              color: Colors.blue.shade700,
              onTap: () =>
                  _launchUrl("https://www.facebook.com/happyfarmpsp/"),
            ),
            const SizedBox(width: 12),
            _buildSocialButton(
              icon: FontAwesomeIcons.instagram,
              color: Colors.purple,
              onTap: () =>
                  _launchUrl("https://www.instagram.com/happyfarmpsp"),
            ),
            const SizedBox(width: 12),
            _buildSocialButton(
              icon: Brands.whatsapp,
              isBrandIcon: true,
              color: AppTheme.primaryColor,
              onTap: () => _launchWhatsApp("9171749999"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required dynamic icon,
    required Color color,
    required VoidCallback onTap,
    bool isBrandIcon = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: isBrandIcon
            ? Brand(icon, size: 24)
            : Icon(icon as IconData, color: Colors.white, size: 24),
      ),
    );
  }
}
