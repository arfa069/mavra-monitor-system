import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/files/file_service.dart';
import 'package:mavra_frontend/core/platform/platform_capabilities.dart';

void main() {
  group('PlatformCapabilities', () {
    test('uses browser callback and cookie-backed refresh on web', () {
      final capabilities = PlatformCapabilities.forEnvironment(
        isWeb: true,
        platform: TargetPlatform.android,
      );

      expect(capabilities.isWeb, isTrue);
      expect(capabilities.isMobile, isFalse);
      expect(capabilities.secureStorageMode, SecureStorageMode.webCookie);
      expect(capabilities.callbackMode, CallbackMode.browserUrl);
      expect(capabilities.realtimeMode, RealtimeMode.serverSentEvents);
      expect(capabilities.canPickFiles, isTrue);
    });

    test('uses native secure storage and app links on mobile', () {
      final capabilities = PlatformCapabilities.forEnvironment(
        isWeb: false,
        platform: TargetPlatform.iOS,
      );

      expect(capabilities.isMobile, isTrue);
      expect(capabilities.isDesktop, isFalse);
      expect(
        capabilities.secureStorageMode,
        SecureStorageMode.nativeSecureStorage,
      );
      expect(capabilities.callbackMode, CallbackMode.appLink);
      expect(capabilities.realtimeMode, RealtimeMode.serverSentEvents);
    });

    test('uses Windows secure storage and save dialog support on Windows', () {
      final capabilities = PlatformCapabilities.forEnvironment(
        isWeb: false,
        platform: TargetPlatform.windows,
      );

      expect(capabilities.isDesktop, isTrue);
      expect(
        capabilities.secureStorageMode,
        SecureStorageMode.windowsSecureStorage,
      );
      expect(capabilities.callbackMode, CallbackMode.windowsProtocol);
      expect(capabilities.supportsSaveDialog, isTrue);
    });

    test('exposes file service capabilities from platform capabilities', () {
      final service = FileService.forCapabilities(
        PlatformCapabilities.forEnvironment(
          isWeb: false,
          platform: TargetPlatform.windows,
        ),
      );

      expect(service.canPickFiles, isTrue);
      expect(service.canSaveFiles, isTrue);
      expect(service.canDownloadFiles, isTrue);
    });
  });
}
