import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import '../platform/platform_capabilities.dart';

typedef PickFileHandler = Future<PickedFileReference?> Function();
typedef SaveBytesHandler =
    Future<void> Function({
      required String suggestedName,
      required List<int> bytes,
    });

class PickedFileReference {
  const PickedFileReference({required this.name, this.bytes, this.path});

  final String name;
  final List<int>? bytes;
  final String? path;
}

class FileService {
  const FileService({
    required this.canPickFiles,
    required this.canSaveFiles,
    required this.canDownloadFiles,
    this.pickFileHandler,
    this.saveBytesHandler,
  });

  factory FileService.forCapabilities(PlatformCapabilities capabilities) {
    final canSaveFiles = capabilities.supportsSaveDialog || capabilities.isWeb;

    return FileService(
      canPickFiles: capabilities.canPickFiles,
      canSaveFiles: canSaveFiles,
      canDownloadFiles: capabilities.canDownloadFiles,
      pickFileHandler: capabilities.canPickFiles ? _pickPlatformFile : null,
      saveBytesHandler: canSaveFiles
          ? ({required suggestedName, required bytes}) => _savePlatformBytes(
              suggestedName: suggestedName,
              bytes: bytes,
              useSaveDialog: capabilities.supportsSaveDialog,
            )
          : null,
    );
  }

  final bool canPickFiles;
  final bool canSaveFiles;
  final bool canDownloadFiles;
  final PickFileHandler? pickFileHandler;
  final SaveBytesHandler? saveBytesHandler;

  Future<PickedFileReference?> pickFile() {
    final handler = pickFileHandler;
    if (handler == null) {
      throw UnsupportedError('File picking is unavailable on this platform.');
    }
    return handler();
  }

  Future<void> saveBytes({
    required String suggestedName,
    required List<int> bytes,
  }) {
    final handler = saveBytesHandler;
    if (handler == null) {
      throw UnsupportedError('File saving is unavailable on this platform.');
    }
    return handler(suggestedName: suggestedName, bytes: bytes);
  }
}

Future<PickedFileReference?> _pickPlatformFile() async {
  final file = await openFile();
  if (file == null) {
    return null;
  }

  final path = file.path.isEmpty ? null : file.path;
  return PickedFileReference(
    name: file.name,
    path: path,
    bytes: await file.readAsBytes(),
  );
}

Future<void> _savePlatformBytes({
  required String suggestedName,
  required List<int> bytes,
  required bool useSaveDialog,
}) async {
  final file = XFile.fromData(Uint8List.fromList(bytes), name: suggestedName);

  if (!useSaveDialog) {
    await file.saveTo(suggestedName);
    return;
  }

  final location = await getSaveLocation(suggestedName: suggestedName);
  if (location == null) {
    return;
  }

  await file.saveTo(location.path);
}
