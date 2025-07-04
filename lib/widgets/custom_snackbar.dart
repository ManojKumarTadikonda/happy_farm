import 'package:flutter/material.dart';

void showCustomToast({
  required BuildContext context,
  required String title,
  required String message,
  required bool isError,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.of(context);
  final icon = isError ? Icons.error_outline : Icons.check_circle_outline;
  final bgColor = isError ? const Color(0xFFFFE6E6) : const Color(0xFFE6FFF0);
  final textColor = isError ? Colors.red.shade800 : Colors.green.shade800;
  final iconBg = isError ? Colors.red : Colors.green;
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: 80,
      left: 20,
      right: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Circular Icon
                Container(
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Icon(icon, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                // Title + Message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => overlayEntry.remove(),
                child: const Icon(Icons.close, size: 20, color: Colors.grey),
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);
  Future.delayed(duration, () => overlayEntry.remove());
}
