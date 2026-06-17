import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/files/file_service.dart';
import 'package:mavra_frontend/core/platform/platform_capabilities.dart';

void main() {
  group('FileService', () {
    test('delegates file picking to the configured platform handler', () async {
      final service = FileService(
        canPickFiles: true,
        canSaveFiles: true,
        canDownloadFiles: true,
        pickFileHandler: () async => const PickedFileReference(
          name: 'products.csv',
          path: r'C:\tmp\products.csv',
          bytes: [1, 2, 3],
        ),
      );

      final file = await service.pickFile();

      expect(file?.name, 'products.csv');
      expect(file?.path, r'C:\tmp\products.csv');
      expect(file?.bytes, [1, 2, 3]);
    });

    test('delegates byte saving to the configured platform handler', () async {
      final calls = <_SaveCall>[];
      final service = FileService(
        canPickFiles: true,
        canSaveFiles: true,
        canDownloadFiles: true,
        saveBytesHandler: ({required suggestedName, required bytes}) async {
          calls.add(_SaveCall(suggestedName, bytes));
        },
      );

      await service.saveBytes(suggestedName: 'profile.zip', bytes: [4, 5, 6]);

      expect(calls, hasLength(1));
      expect(calls.single.suggestedName, 'profile.zip');
      expect(calls.single.bytes, [4, 5, 6]);
    });

    test('keeps unsupported direct services explicit', () {
      const service = FileService(
        canPickFiles: false,
        canSaveFiles: false,
        canDownloadFiles: false,
      );

      expect(service.pickFile, throwsUnsupportedError);
      expect(
        () => service.saveBytes(suggestedName: 'unused.txt', bytes: const []),
        throwsUnsupportedError,
      );
    });

    test('creates desktop service with save dialog capability', () {
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

class _SaveCall {
  const _SaveCall(this.suggestedName, this.bytes);

  final String suggestedName;
  final List<int> bytes;
}
