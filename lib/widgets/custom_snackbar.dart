import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class CustomSnackbar {
  static void showSuccess(BuildContext context, String title, String message) {
    _showCustomSnackbar(context, title, message, ContentType.success);
  }

  static void showError(BuildContext context, String title, String message) {
    _showCustomSnackbar(context, title, message, ContentType.failure);
  }

  static void _showCustomSnackbar(BuildContext context, String title, String message, ContentType contentType) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewPadding.top + 20,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: AwesomeSnackbarContent(
            title: title,
            message: message,
            contentType: contentType,
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}
