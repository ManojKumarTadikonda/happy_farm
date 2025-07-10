import 'package:flutter/material.dart';

class CustomSnackbar {
  static void showSuccess(BuildContext context, String title, String message) {
    _showCustomSnackbar(
      context,
      icon: Icons.check_circle_outline,
      title: title,
      message: message,
      bgColor: Colors.green.shade50,
      iconColor: Colors.green.shade700,
      textColor: Colors.green.shade900,
    );
  }

  static void showError(BuildContext context, String title, String message) {
    _showCustomSnackbar(
      context,
      icon: Icons.error_outline,
      title: title,
      message: message,
      bgColor: Colors.red.shade50,
      iconColor: Colors.red.shade700,
      textColor: Colors.red.shade900,
    );
  }

  static void _showCustomSnackbar(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required Color bgColor,
    required Color iconColor,
    required Color textColor,
  }) {
    final overlay = Overlay.of(context);

    late final OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewPadding.top + 20,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.up,
            onDismissed: (_) => overlayEntry.remove(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            )),
                        const SizedBox(height: 4),
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
                    onTap: () => overlayEntry.remove(),
                    child: Icon(Icons.close, color: iconColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}
