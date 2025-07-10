import 'package:flutter/material.dart';

class CustomDialogWidget extends StatelessWidget {
  final String title;
  final String message;
  final String leftButtonText;
  final String rightButtonText;
  final VoidCallback? onLeftButtonPressed;
  final VoidCallback? onRightButtonPressed;
  final Color? primaryColor;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool showIcon;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const CustomDialogWidget({
    Key? key,
    required this.title,
    required this.message,
    required this.leftButtonText,
    required this.rightButtonText,
    this.onLeftButtonPressed,
    this.onRightButtonPressed,
    this.primaryColor,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.showIcon = true,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePrimaryColor = primaryColor ?? theme.primaryColor;
    final effectiveBackgroundColor = backgroundColor ?? theme.dialogBackgroundColor;
    final effectiveTextColor = textColor ?? theme.textTheme.bodyLarge?.color ?? Colors.black87;
    final effectiveBorderRadius = borderRadius ?? 16.0;
    final effectivePadding = padding ?? const EdgeInsets.all(24.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: effectivePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Section
              if (showIcon)
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: effectivePrimaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon ?? Icons.info_outline,
                    size: 32,
                    color: effectivePrimaryColor,
                  ),
                ),
              
              if (showIcon) const SizedBox(height: 20),
              
              // Title Section
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: effectiveTextColor,
                  fontWeight: FontWeight.bold,
                ) ?? TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: effectiveTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Message Section
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: effectiveTextColor.withOpacity(0.7),
                  height: 1.5,
                ) ?? TextStyle(
                  fontSize: 16,
                  color: effectiveTextColor.withOpacity(0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Buttons Section
              Row(
                children: [
                  Expanded(
                    child: _buildButton(
                      context: context,
                      text: leftButtonText,
                      onPressed: onLeftButtonPressed,
                      isOutlined: true,
                      primaryColor: effectivePrimaryColor,
                      textColor: effectiveTextColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildButton(
                      context: context,
                      text: rightButtonText,
                      onPressed: onRightButtonPressed,
                      isOutlined: false,
                      primaryColor: effectivePrimaryColor,
                      textColor: effectiveTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String text,
    required VoidCallback? onPressed,
    required bool isOutlined,
    required Color primaryColor,
    required Color textColor,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : primaryColor,
        border: isOutlined ? Border.all(color: primaryColor.withOpacity(0.3)) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed ?? () => Navigator.of(context).pop(),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isOutlined ? primaryColor : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper function to show the dialog
Future<void> showCustomDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String leftButtonText,
  required String rightButtonText,
  VoidCallback? onLeftButtonPressed,
  VoidCallback? onRightButtonPressed,
  Color? primaryColor,
  Color? backgroundColor,
  Color? textColor,
  IconData? icon,
  bool showIcon = true,
  EdgeInsetsGeometry? padding,
  double? borderRadius,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => CustomDialogWidget(
      title: title,
      message: message,
      leftButtonText: leftButtonText,
      rightButtonText: rightButtonText,
      onLeftButtonPressed: onLeftButtonPressed,
      onRightButtonPressed: onRightButtonPressed,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      textColor: textColor,
      icon: icon,
      showIcon: showIcon,
      padding: padding,
      borderRadius: borderRadius,
    ),
  );
}