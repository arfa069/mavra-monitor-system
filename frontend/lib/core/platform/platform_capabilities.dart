import 'package:flutter/foundation.dart';

enum SecureStorageMode { webCookie, nativeSecureStorage, windowsSecureStorage }

enum CallbackMode { browserUrl, appLink, windowsProtocol }

enum RealtimeMode { serverSentEvents, polling }

class PlatformCapabilities {
  const PlatformCapabilities({
    required this.isWeb,
    required this.isDesktop,
    required this.isMobile,
    required this.canPickFiles,
    required this.canDownloadFiles,
    required this.supportsSaveDialog,
    required this.secureStorageMode,
    required this.callbackMode,
    required this.realtimeMode,
  });

  factory PlatformCapabilities.current() {
    return PlatformCapabilities.forEnvironment(
      isWeb: kIsWeb,
      platform: defaultTargetPlatform,
    );
  }

  factory PlatformCapabilities.forEnvironment({
    required bool isWeb,
    required TargetPlatform platform,
    RealtimeMode realtimeMode = RealtimeMode.serverSentEvents,
  }) {
    final isDesktop =
        !isWeb &&
        (platform == TargetPlatform.windows ||
            platform == TargetPlatform.macOS ||
            platform == TargetPlatform.linux);
    final isMobile =
        !isWeb &&
        (platform == TargetPlatform.android || platform == TargetPlatform.iOS);

    final secureStorageMode = isWeb
        ? SecureStorageMode.webCookie
        : platform == TargetPlatform.windows
        ? SecureStorageMode.windowsSecureStorage
        : SecureStorageMode.nativeSecureStorage;

    final callbackMode = isWeb
        ? CallbackMode.browserUrl
        : platform == TargetPlatform.windows
        ? CallbackMode.windowsProtocol
        : CallbackMode.appLink;

    return PlatformCapabilities(
      isWeb: isWeb,
      isDesktop: isDesktop,
      isMobile: isMobile,
      canPickFiles: true,
      canDownloadFiles: true,
      supportsSaveDialog: isDesktop,
      secureStorageMode: secureStorageMode,
      callbackMode: callbackMode,
      realtimeMode: realtimeMode,
    );
  }

  final bool isWeb;
  final bool isDesktop;
  final bool isMobile;
  final bool canPickFiles;
  final bool canDownloadFiles;
  final bool supportsSaveDialog;
  final SecureStorageMode secureStorageMode;
  final CallbackMode callbackMode;
  final RealtimeMode realtimeMode;
}
