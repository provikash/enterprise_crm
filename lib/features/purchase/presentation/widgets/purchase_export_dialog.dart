// ignore_for_file: deprecated_member_use
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../domain/entities/purchase_filter_query.dart';
import '../../domain/entities/purchase_order_record.dart';
import '../../domain/policies/purchase_access_policy.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../services/purchase_csv_serializer.dart';
import '../services/purchase_file_saver.dart';
import '../services/purchase_pdf_serializer.dart';

enum PurchaseExportFormat {
  pdf,
  csv,
}

enum PurchaseExportScope {
  all,
  filtered,
}

/// Helper to display the purchase export dialog modal.
Future<bool?> showPurchaseExportDialog({
  required BuildContext context,
  required PurchaseRepository repository,
  CurrentUser? user,
  PurchaseFilterQuery? currentQuery,
  List<PurchaseOrderRecord>? currentFilteredRecords,
  PurchaseFileSaver? fileSaver,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => PurchaseExportDialog(
      repository: repository,
      user: user,
      currentQuery: currentQuery,
      currentFilteredRecords: currentFilteredRecords,
      fileSaver: fileSaver,
    ),
  );
}

/// Modal dialog for configuring and executing Purchase exports (PDF, CSV).
class PurchaseExportDialog extends StatefulWidget {
  final PurchaseRepository repository;
  final CurrentUser? user;
  final PurchaseFilterQuery? currentQuery;
  final List<PurchaseOrderRecord>? currentFilteredRecords;
  final PurchaseFileSaver? fileSaver;

  const PurchaseExportDialog({
    super.key,
    required this.repository,
    this.user,
    this.currentQuery,
    this.currentFilteredRecords,
    this.fileSaver,
  });

  @override
  State<PurchaseExportDialog> createState() => _PurchaseExportDialogState();
}

class _PurchaseExportDialogState extends State<PurchaseExportDialog> {
  PurchaseExportFormat _format = PurchaseExportFormat.pdf;
  PurchaseExportScope _scope = PurchaseExportScope.all;
  bool _isExporting = false;
  String? _errorMessage;

  late final PurchaseFileSaver _fileSaver;

  @override
  void initState() {
    super.initState();
    _fileSaver = widget.fileSaver ?? const DefaultPurchaseFileSaver();
    if (widget.currentQuery?.status != null ||
        (widget.currentQuery?.searchText?.isNotEmpty ?? false)) {
      _scope = PurchaseExportScope.filtered;
    }
  }

  Future<void> _handleExport() async {
    final user = widget.user;
    if (user != null && !PurchaseAccessPolicy.canExport(user)) {
      setState(() {
        _errorMessage = 'You do not have permission to export purchase orders.';
      });
      return;
    }

    setState(() {
      _isExporting = true;
      _errorMessage = null;
    });

    try {
      List<PurchaseOrderRecord> recordsToExport;

      if (_scope == PurchaseExportScope.filtered &&
          widget.currentFilteredRecords != null) {
        recordsToExport = widget.currentFilteredRecords!;
      } else if (_scope == PurchaseExportScope.filtered &&
          widget.currentQuery != null) {
        recordsToExport = await widget.repository.getPurchaseOrders(
          query: widget.currentQuery!.copyWith(page: 1, pageSize: 500),
        );
      } else {
        recordsToExport = await widget.repository.getPurchaseOrders(
          query: const PurchaseFilterQuery(page: 1, pageSize: 1000),
        );
      }

      final dateStr = DateTime.now().toIso8601String().split('T').first;
      final fileName = switch (_format) {
        PurchaseExportFormat.pdf => 'Purchase_Orders_Export_$dateStr.pdf',
        PurchaseExportFormat.csv => 'Purchase_Orders_Export_$dateStr.csv',
      };

      final Uint8List bytes;
      final String mimeType;
      final String extension;

      switch (_format) {
        case PurchaseExportFormat.pdf:
          bytes = const PurchasePdfSerializer().generatePurchaseOrdersReport(
            recordsToExport,
            title: _scope == PurchaseExportScope.filtered
                ? 'Filtered Purchase Orders Register'
                : 'All Purchase Orders Register',
          );
          mimeType = 'application/pdf';
          extension = 'pdf';
          break;
        case PurchaseExportFormat.csv:
          bytes = const PurchaseCsvSerializer().convertToBytes(recordsToExport);
          mimeType = 'text/csv';
          extension = 'csv';
          break;
      }

      final result = await _fileSaver.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
        extension: extension,
        dialogTitle: 'Save Purchase Export ($extension)',
      );

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully exported $fileName'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      key: const Key('purchase_export_dialog'),
      title: Row(
        children: [
          Icon(Icons.file_download_outlined, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Export Purchase Orders'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select File Format',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RadioListTile<PurchaseExportFormat>(
              key: const Key('purchase_export_format_pdf'),
              dense: true,
              value: PurchaseExportFormat.pdf,
              groupValue: _format,
              title: const Text('PDF Document (.pdf)'),
              subtitle: const Text('Formatted multi-page register report'),
              secondary: const Icon(Icons.picture_as_pdf_outlined),
              onChanged: _isExporting
                  ? null
                  : (v) => setState(() => _format = v!),
            ),
            RadioListTile<PurchaseExportFormat>(
              key: const Key('purchase_export_format_csv'),
              dense: true,
              value: PurchaseExportFormat.csv,
              groupValue: _format,
              title: const Text('CSV Document (.csv)'),
              subtitle: const Text('Plain text comma-separated values'),
              secondary: const Icon(Icons.text_snippet_outlined),
              onChanged: _isExporting
                  ? null
                  : (v) => setState(() => _format = v!),
            ),
            const Divider(height: 24),
            Text(
              'Export Scope',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RadioListTile<PurchaseExportScope>(
              key: const Key('purchase_export_scope_all'),
              dense: true,
              value: PurchaseExportScope.all,
              groupValue: _scope,
              title: const Text('All Purchase Orders'),
              subtitle: const Text('Export entire purchase registry'),
              onChanged: _isExporting
                  ? null
                  : (v) => setState(() => _scope = v!),
            ),
            RadioListTile<PurchaseExportScope>(
              key: const Key('purchase_export_scope_filtered'),
              dense: true,
              value: PurchaseExportScope.filtered,
              groupValue: _scope,
              title: const Text('Current Filtered Results'),
              subtitle:
                  const Text('Only orders matching current status/search'),
              onChanged: _isExporting
                  ? null
                  : (v) => setState(() => _scope = v!),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: colorScheme.onErrorContainer,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('purchase_export_cancel_button'),
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const Key('purchase_confirm_export_button'),
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.download, size: 18),
          label: Text(_isExporting ? 'Exporting...' : 'Download Export'),
          onPressed: _isExporting ? null : _handleExport,
        ),
      ],
    );
  }
}
