import 'package:flutter/material.dart';
import '../../domain/entities/vendor_record.dart';
import '../services/vendor_csv_serializer.dart';
import '../services/vendor_file_saver.dart';
import '../services/vendor_pdf_serializer.dart';
import '../services/vendor_xlsx_serializer.dart';

enum VendorExportFormat {
  csv,
  excel,
  pdf;

  String get displayName => switch (this) {
        VendorExportFormat.csv => 'CSV Spreadsheet (.csv)',
        VendorExportFormat.excel => 'Microsoft Excel (.xlsx)',
        VendorExportFormat.pdf => 'PDF Document (.pdf)',
      };

  String get extension => switch (this) {
        VendorExportFormat.csv => 'csv',
        VendorExportFormat.excel => 'xlsx',
        VendorExportFormat.pdf => 'pdf',
      };

  String get mimeType => switch (this) {
        VendorExportFormat.csv => 'text/csv',
        VendorExportFormat.excel => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        VendorExportFormat.pdf => 'application/pdf',
      };

  IconData get icon => switch (this) {
        VendorExportFormat.csv => Icons.table_view_outlined,
        VendorExportFormat.excel => Icons.table_chart_outlined,
        VendorExportFormat.pdf => Icons.picture_as_pdf_outlined,
      };
}

/// Modal dialog prompting user confirmation to export vendors to CSV, Excel, or PDF.
class VendorExportDialog extends StatefulWidget {
  final List<VendorRecord> vendors;
  final VendorFileSaver fileSaver;

  const VendorExportDialog({
    super.key,
    required this.vendors,
    this.fileSaver = const DefaultVendorFileSaver(),
  });

  @override
  State<VendorExportDialog> createState() => _VendorExportDialogState();
}

class _VendorExportDialogState extends State<VendorExportDialog> {
  VendorExportFormat _format = VendorExportFormat.csv;
  bool _isExporting = false;

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);

    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final fileName = 'vendors_export_$timestamp.${_format.extension}';

      final bytes = switch (_format) {
        VendorExportFormat.csv => const VendorCsvSerializer().convertToBytes(widget.vendors),
        VendorExportFormat.excel => const VendorXlsxSerializer().convertToBytes(widget.vendors),
        VendorExportFormat.pdf => const VendorPdfSerializer().generateVendorDirectoryReport(widget.vendors),
      };

      final uri = await widget.fileSaver.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: _format.mimeType,
        extension: _format.extension,
        dialogTitle: 'Save Vendor Directory Export (${_format.extension.toUpperCase()})',
      );

      if (mounted) {
        Navigator.of(context).pop(uri != null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.download, color: colorScheme.primary, size: 22),
          const SizedBox(width: 8),
          const Text('Export Vendor Directory'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select preferred file format to export ${widget.vendors.length} vendor record(s):',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            RadioGroup<VendorExportFormat>(
              groupValue: _format,
              onChanged: (v) {
                if (!_isExporting && v != null) {
                  setState(() => _format = v);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: VendorExportFormat.values.map(
                  (fmt) => RadioListTile<VendorExportFormat>(
                    key: Key('vendor_export_format_${fmt.name}'),
                    value: fmt,
                    title: Row(
                      children: [
                        Icon(fmt.icon, size: 18, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(fmt.displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colorScheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Includes full supplier registry with compliance GSTIN/PAN, banking, contacts, and terms.',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          key: const Key('vendor_export_confirm_button'),
          onPressed: _isExporting ? null : _handleExport,
          icon: _isExporting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.download, size: 16),
          label: Text(_isExporting ? 'Exporting...' : 'Download ${_format.extension.toUpperCase()}'),
        ),
      ],
    );
  }
}

Future<bool?> showVendorExportDialog({
  required BuildContext context,
  required List<VendorRecord> vendors,
  VendorFileSaver fileSaver = const DefaultVendorFileSaver(),
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => VendorExportDialog(vendors: vendors, fileSaver: fileSaver),
  );
}
