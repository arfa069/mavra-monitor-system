import 'package:flutter/material.dart';

enum MavraNoticeType { info, success, warning, error }

class MavraNotifier {
  MavraNotifier._();

  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static void info(String message, {Duration? duration}) {
    show(message, duration: duration);
  }

  static void success(String message, {Duration? duration}) {
    show(message, type: MavraNoticeType.success, duration: duration);
  }

  static void warning(String message, {Duration? duration}) {
    show(message, type: MavraNoticeType.warning, duration: duration);
  }

  static void error(String message, {Duration? duration}) {
    show(message, type: MavraNoticeType.error, duration: duration);
  }

  static void show(
    String message, {
    MavraNoticeType type = MavraNoticeType.info,
    Duration? duration,
  }) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) {
      return;
    }

    final style = _noticeStyle(messenger.context, type);
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: duration ?? _defaultDuration(type),
          backgroundColor: style.backgroundColor,
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(style.icon, color: style.foregroundColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: style.foregroundColor == null
                      ? null
                      : TextStyle(color: style.foregroundColor),
                ),
              ),
            ],
          ),
        ),
      );
  }

  static void clear() {
    scaffoldMessengerKey.currentState?.removeCurrentSnackBar();
  }

  static Duration _defaultDuration(MavraNoticeType type) {
    return type == MavraNoticeType.error
        ? const Duration(seconds: 5)
        : const Duration(seconds: 3);
  }

  static _NoticeStyle _noticeStyle(BuildContext context, MavraNoticeType type) {
    final scheme = Theme.of(context).colorScheme;
    return switch (type) {
      MavraNoticeType.info => const _NoticeStyle(icon: Icons.info),
      MavraNoticeType.success => _NoticeStyle(
        icon: Icons.check_circle,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
      ),
      MavraNoticeType.warning => _NoticeStyle(
        icon: Icons.warning,
        backgroundColor: scheme.tertiaryContainer,
        foregroundColor: scheme.onTertiaryContainer,
      ),
      MavraNoticeType.error => _NoticeStyle(
        icon: Icons.error_outline,
        backgroundColor: scheme.errorContainer,
        foregroundColor: scheme.onErrorContainer,
      ),
    };
  }
}

class _NoticeStyle {
  const _NoticeStyle({
    required this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
}
