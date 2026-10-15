import 'dart:typed_data';

import 'package:flutter/material.dart';

class PayrollPickedFile {
  final String name;
  final int sizeBytes;
  final Uint8List bytes;
  const PayrollPickedFile({
    required this.name,
    required this.sizeBytes,
    required this.bytes,
  });
}

class FileUploadTile extends StatelessWidget {
  final PayrollPickedFile? file;
  final Set<String> allowedExtensions;
  final int maxSizeBytes;
  final double? progress;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback? onRemove;
  final VoidCallback? onPreview;

  const FileUploadTile({
    super.key,
    required this.file,
    required this.allowedExtensions,
    required this.maxSizeBytes,
    required this.onPick,
    this.progress,
    this.enabled = true,
    this.onRemove,
    this.onPreview,
  });

  String? validate(PayrollPickedFile candidate) {
    final extension = candidate.name.contains('.')
        ? candidate.name.split('.').last.toLowerCase()
        : '';
    if (!allowedExtensions.contains(extension)) {
      return 'Allowed file types: ${allowedExtensions.join(', ')}.';
    }
    if (candidate.sizeBytes <= 0) return 'The selected file is empty.';
    if (candidate.sizeBytes > maxSizeBytes) {
      return 'The selected file is too large.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = file;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.upload_file_outlined),
        title: Text(selected?.name ?? 'Choose a file'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Allowed: ${allowedExtensions.join(', ')} • Maximum ${(maxSizeBytes / (1024 * 1024)).toStringAsFixed(0)} MB',
            ),
            if (progress != null) LinearProgressIndicator(value: progress),
          ],
        ),
        onTap: enabled ? (selected == null ? onPick : onPreview) : null,
        trailing: selected == null
            ? IconButton(
                tooltip: 'Choose file',
                onPressed: enabled ? onPick : null,
                icon: const Icon(Icons.add),
              )
            : IconButton(
                tooltip: 'Remove file',
                onPressed: enabled ? onRemove : null,
                icon: const Icon(Icons.close),
              ),
      ),
    );
  }
}
