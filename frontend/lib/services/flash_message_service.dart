import 'package:flash_message/flash_message.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

// Custom flash message with app styling
class AppFlashMessage {
  static void show({
    required BuildContext context,
    required String message,
    String? description,
    FlashMessageType type = FlashMessageType.info,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
    VoidCallback? onTap,
  }) {
    Color backgroundColor;
    Color textColor = Colors.white;
    IconData defaultIcon;

    switch (type) {
      case FlashMessageType.success:
        backgroundColor = AppColors.success;
        defaultIcon = Icons.check_circle;
        break;
      case FlashMessageType.error:
        backgroundColor = AppColors.error;
        defaultIcon = Icons.error;
        break;
      case FlashMessageType.warning:
        backgroundColor = AppColors.warning;
        defaultIcon = Icons.warning;
        break;
      case FlashMessageType.info:
        backgroundColor = AppColors.info;
        defaultIcon = Icons.info;
        break;
    }

    // Use FlashMessageService directly
    FlashMessageService().showMessage(
      message: message,
      description: description,
      type: type,
      duration: duration,
      backgroundColor: backgroundColor,
      textColor: textColor,
      icon: icon ?? defaultIcon,
      onTap: onTap,
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    String? description,
  }) {
    show(
      context: context,
      message: message,
      description: description,
      type: FlashMessageType.success,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    String? description,
  }) {
    show(
      context: context,
      message: message,
      description: description,
      type: FlashMessageType.error,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    String? description,
  }) {
    show(
      context: context,
      message: message,
      description: description,
      type: FlashMessageType.warning,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String? description,
  }) {
    show(
      context: context,
      message: message,
      description: description,
      type: FlashMessageType.info,
    );
  }
}
