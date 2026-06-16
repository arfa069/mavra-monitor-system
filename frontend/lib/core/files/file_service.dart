import '../platform/platform_capabilities.dart';

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
  });

  factory FileService.forCapabilities(PlatformCapabilities capabilities) {
    return FileService(
      canPickFiles: capabilities.canPickFiles,
      canSaveFiles: capabilities.supportsSaveDialog,
      canDownloadFiles: capabilities.canDownloadFiles,
    );
  }

  final bool canPickFiles;
  final bool canSaveFiles;
  final bool canDownloadFiles;

  Future<PickedFileReference?> pickFile() {
    throw UnsupportedError('File picking is wired by platform adapters.');
  }

  Future<void> saveBytes({
    required String suggestedName,
    required List<int> bytes,
  }) {
    throw UnsupportedError('File saving is wired by platform adapters.');
  }
}
