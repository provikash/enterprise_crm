// ignore_for_file: deprecated_member_use
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../domain/entities/dispatch_filter_query.dart';
import '../../domain/entities/dispatch_record.dart';
import '../../domain/policies/dispatch_access_policy.dart';
import '../../domain/repositories/dispatch_repository.dart';
import '../services/dispatch_csv_serializer.dart';
import '../services/dispatch_file_saver.dart';
import '../services/dispatch_pdf_serializer.dart';
import '../services/dispatch_xlsx_serializer.dart';

enum DispatchExportFormat {
  pdf,
  xlsx,
  csv,
}

enum DispatchExportScope {
  all,
  filtered,
}

/// Helper to display the dispatch export dialog modal.
Future<bool?> showDispatchExportDialog({
  required BuildContext context,
  required DispatchRepository repository,
  CurrentUser? user,
  DispatchFilterQuery? currentQuery,
  List<DispatchRecord>? currentFilteredRecords,
  DispatchFileSaver? fileSaver,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => DispatchExportDialog(
      repository: repository,
      user: user,
      currentQuery: currentQuery,
      currentFilteredRecords: currentFilteredRecords,
      fileSaver: fileSaver,
    ),
  );
}

/// Modal dialog for configuring and executing Dispatch exports (PDF, Excel, CSV).
class DispatchExportDialog extends StatefulWidget {
  final DispatchRepository repository;
  final CurrentUser? user;
  final DispatchFilterQuery? currentQuery;
  final List<DispatchRecord>? currentFilteredRecords;
  final DispatchFileSaver? fileSaver;

  const DispatchExportDialog({
    super.key,
    required this.repository,
    this.user,
    this.currentQuery,
    this.currentFilteredRecords,
    this.fileSaver,
  });

  @override
  State<DispatchExportDialog> createState() => _DispatchExportDialogState();
}

class _DispatchExportDialogState extends State<DispatchExportDialog> {
  DispatchExportFormat _format = DispatchExportFormat.pdf;
  DispatchExportScope _scope = DispatchExportScope.all;
  bool _isExporting = false;
  String? _errorMessage;

  late final DispatchFileSaver _fileSaver;

  bool _canExport(DispatchExportFormat format) {
    final user = widget.user;
    if (user == null) return true;
    return switch (format) {
      DispatchExportFormat.pdf => DispatchAccessPolicy.canExportPdf(user),
      DispatchExportFormat.xlsx => DispatchAccessPolicy.canExportXlsx(user),
      DispatchExportFormat.csv => DispatchAccessPolicy.canExportCsv(user),
    };
  }

  @override
  void initState() {
    super.initState();
    _fileSaver = widget.fileSaver ?? const DefaultDispatchFileSaver();
    // Default to filtered if active filter is applied
    if (widget.currentQuery?.status != null ||
        (widget.currentQuery?.searchText?.isNotEmpty ?? false)) {
      _scope = DispatchExportScope.filtered;
    }

    if (!_canExport(_format)) {
      if (_canExport(DispatchExportFormat.xlsx)) {
        _format = DispatchExportFormat.xlsx;
      } else if (_canExport(DispatchExportFormat.csv)) {
        _format = DispatchExportFormat.csv;
      }
    }
  }

  Future<void> _handleExport() async {
    if (!_canExport(_format)) {
      setState(() {
        _errorMessage =
            'You do not have permission to export in ${_format.name.toUpperCase()} format.';
      });
      return;
    }

    setState(() {
      _isExporting = true;
      _errorMessage = null;
    });

    try {
      List<DispatchRecord> recordsToExport;

      if (_scope == DispatchExportScope.filtered &&
          widget.currentFilteredRecords != null) {
        recordsToExport = widget.currentFilteredRecords!;
      } else if (_scope == DispatchExportScope.filtered &&
          widget.currentQuery != null) {
        recordsToExport = await widget.repository.getDispatches(
          query: widget.currentQuery!.copyWith(page: 1, pageSize: 500),
        );
      } else {
        // All dispatches
        recordsToExport = await widget.repository.getDispatches(
          query: const DispatchFilterQuery(page: 1, pageSize: 1000),
        );
      }

      final dateStr = DateTime.now().toIso8601String().split('T').first;
      final fileName = switch (_format) {
        DispatchExportFormat.pdf => 'Dispatch_Export_$dateStr.pdf',
        DispatchExportFormat.xlsx => 'Dispatch_Export_$dateStr.xlsx',
        DispatchExportFormat.csv => 'Dispatch_Export_$dateStr.csv',
      };

      final Uint8List bytes;
      final String mimeType;
      final String extension;

      switch (_format) {
        case DispatchExportFormat.pdf:
          bytes = const DispatchPdfSerializer().generateDispatchesReport(
            recordsToExport,
            title: _scope == DispatchExportScope.filtered
                ? 'Filtered Dispatch Register'
                : 'All Dispatches Register',
          );
          mimeType = 'application/pdf';
          extension = 'pdf';
          break;
        case DispatchExportFormat.xlsx:
          bytes = DispatchXlsxSerializer().convertToBytes(recordsToExport);
          mimeType =
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          extension = 'xlsx';
          break;
        case DispatchExportFormat.csv:
          bytes = const DispatchCsvSerializer().convertToBytes(recordsToExport);
          mimeType = 'text/csv';
          extension = 'csv';
          break;
      }

      final result = await _fileSaver.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
        extension: extension,
        dialogTitle: 'Save Dispatch Export ($extension)',
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
    final canPdf = _canExport(DispatchExportFormat.pdf);
    final canXlsx = _canExport(DispatchExportFormat.xlsx);
    final canCsv = _canExport(DispatchExportFormat.csv);

    return AlertDialog(
      key: const Key('dispatch_export_dialog'),
      title: Row(
        children: [
          Icon(Icons.file_download_outlined, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Export Dispatch Data'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select File Format',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            RadioListTile<DispatchExportFormat>(
              key: const Key('dispatch_export_format_pdf'),
              dense: true,
              value: DispatchExportFormat.pdf,
              groupValue: _format,
              title: const Text('PDF Document (.pdf)'),
              subtitle: Text(canPdf
                  ? 'Formatted multi-page register report'
                  : 'Permission required (dispatch.export.pdf)'),
              secondary: const Icon(Icons.picture_as_pdf_outlined),
              onChanged: (_isExporting || !canPdf)
                  ? null
                  : (v) => setState(() => _format = v!),
            ),
            RadioListTile<DispatchExportFormat>(
              key: const Key('dispatch_export_format_xlsx'),
              dense: true,
              value: DispatchExportFormat.xlsx,
              groupValue: _format,
              title: const Text('Excel Spreadsheet (.xlsx)'),
              subtitle: Text(canXlsx
                  ? 'Styled spreadsheet with all metadata'
                  : 'Permission required (dispatch.export.xlsx)'),
              secondary: const Icon(Icons.table_chart_outlined),
              onChanged: (_isExporting || !canXlsx)
                  ? null
                  : (v) => setState(() => _format = v!),
            ),
            RadioListTile<DispatchExportFormat>(
              key: const Key('dispatch_export_format_csv'),
              dense: true,
              value: DispatchExportFormat.csv,
              groupValue: _format,
              title: const Text('CSV Document (.csv)'),
              subtitle: Text(canCsv
                  ? 'Plain text comma-separated values'
                  : 'Permission required (dispatch.export.csv)'),
              secondary: const Icon(Icons.text_snippet_outlined),
              onChanged: (_isExporting || !canCsv)
                  ? null
                  : (v) => setState(() => _format = v!),
            ),
            const Divider(height: 24),
            Text(
              'Export Scope',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RadioListTile<DispatchExportScope>(
              key: const Key('dispatch_export_scope_all'),
              dense: true,
              value: DispatchExportScope.all,
              groupValue: _scope,
              title: const Text('All Dispatches'),
              subtitle: const Text('Export entire dispatch registry'),
              onChanged: _isExporting ? null : (v) => setState(() => _scope = v!),
            ),
            RadioListTile<DispatchExportScope>(
              key: const Key('dispatch_export_scope_filtered'),
              dense: true,
              value: DispatchExportScope.filtered,
              groupValue: _scope,
              title: const Text('Current Filtered Results'),
              subtitle: const Text('Only dispatches matching current status/search'),
              onChanged: _isExporting ? null : (v) => setState(() => _scope = v!),
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
                  style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('dispatch_export_cancel_button'),
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const Key('dispatch_confirm_export_button'),
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.download, size: 18),
          label: Text(_isExporting ? 'Exporting...' : 'Download Export'),
          onPressed: _isExporting ? null : _handleExport,
        ),
      ],
    );
  }
}
