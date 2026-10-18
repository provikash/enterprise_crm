import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

/// Abstract platform file saver interface for purchase exports and bills.
abstract interface class PurchaseFileSaver {
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    required String extension,
    String? dialogTitle,
  });
}

/// Default implementation delegating to [FilePicker.saveFile].
class DefaultPurchaseFileSaver implements PurchaseFileSaver {
  const DefaultPurchaseFileSaver();

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    required String extension,
    String? dialogTitle = 'Save Purchase File',
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
