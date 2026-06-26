import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

enum AppFeedbackType { success, error, info }

class AppFeedbackDialog {
  const AppFeedbackDialog._();

  static Future<void> showSuccess(
    BuildContext context, {
    required String message,
    String title = 'Berhasil',
  }) {
    return show(
      context,
      title: title,
      message: message,
      type: AppFeedbackType.success,
    );
  }

  static Future<void> showError(
    BuildContext context, {
    required String message,
    String title = 'Gagal',
  }) {
    return show(
      context,
      title: title,
      message: message,
      type: AppFeedbackType.error,
    );
  }

  static Future<void> showInfo(
    BuildContext context, {
    required String message,
    String title = 'Info',
  }) {
    return show(
      context,
      title: title,
      message: message,
      type: AppFeedbackType.info,
    );
  }

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    required AppFeedbackType type,
  }) {
    final config = _FeedbackConfig.fromType(type);

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: config.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(config.icon, color: config.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class _FeedbackConfig {
  const _FeedbackConfig({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  factory _FeedbackConfig.fromType(AppFeedbackType type) {
    return switch (type) {
      AppFeedbackType.success => const _FeedbackConfig(
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.income,
      ),
      AppFeedbackType.error => const _FeedbackConfig(
        icon: Icons.error_outline_rounded,
        color: AppColors.expense,
      ),
      AppFeedbackType.info => const _FeedbackConfig(
        icon: Icons.info_outline_rounded,
        color: AppColors.primary,
      ),
    };
  }
}
