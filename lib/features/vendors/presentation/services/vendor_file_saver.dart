import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

/// Abstract platform file saver interface for vendor exports.
abstract interface class VendorFileSaver {
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    required String extension,
    String? dialogTitle,
  });
}

/// Default implementation delegating to [FilePicker.saveFile].
class DefaultVendorFileSaver implements VendorFileSaver {
  const DefaultVendorFileSaver();

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    required String extension,
    String? dialogTitle = 'Save Vendor Directory Export',
  }) {
    return FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
      dialogTitle: dialogTitle,
      type: FileType.custom,
      allowedExtensions: [extension],
    );
  }
}
