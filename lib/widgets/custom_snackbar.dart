import 'package:flutter/material.dart';

void showInfoSnackbar(BuildContext context, String message) {
  _showCustomSnackbar(
    context,
    icon: Icons.info_outline,
    title: 'Info',
    message: message,
    bgColor: Colors.blue.shade50,
    iconColor: Colors.blue.shade700,
    textColor: Colors.blue.shade900,
  );
}

void showSuccessSnackbar(BuildContext context, String message) {
  _showCustomSnackbar(
    context,
    icon: Icons.check_circle_outline,
    title: 'Success',
    message: message,
    bgColor: Colors.green.shade50,
    iconColor: Colors.green.shade700,
    textColor: Colors.green.shade900,
  );
}

void showErrorSnackbar(BuildContext context, String message) {
  _showCustomSnackbar(
    context,
    icon: Icons.error_outline,
    title: 'Error',
    message: message,
    bgColor: Colors.red.shade50,
    iconColor: Colors.red.shade700,
    textColor: Colors.red.shade900,
  );
}

/// Private helper that builds the common UI
void _showCustomSnackbar(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  required Color bgColor,
  required Color iconColor,
  required Color textColor,
}) {
  final messenger = ScaffoldMessenger.of(context);

  messenger.showSnackBar(
    SnackBar(
      backgroundColor: bgColor,
      elevation: 4,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: const Duration(seconds: 5),
      content: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    )),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: messenger.hideCurrentSnackBar,
            child: Icon(Icons.close, color: iconColor),
          ),
        ],
      ),
    ),
  );
}

