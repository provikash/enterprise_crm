import 'package:flutter/material.dart';

import '../../domain/import_validation.dart';

class ImportValidationTable extends StatelessWidget {
  final ImportValidationResult result;
  final VoidCallback? onDownloadErrors;

  const ImportValidationTable({
    super.key,
    required this.result,
    this.onDownloadErrors,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 8,
        children: [
          Chip(label: Text('${result.validCount} valid')),
          Chip(label: Text('${result.warningCount} warnings')),
          Chip(label: Text('${result.errorCount} errors')),
          if (result.errorCount > 0 && onDownloadErrors != null)
            TextButton.icon(
              onPressed: onDownloadErrors,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download error report'),
            ),
        ],
      ),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(label: Text('Row')),
            const DataColumn(label: Text('Status')),
            for (final column in result.columns)
              DataColumn(label: Text(column)),
            const DataColumn(label: Text('Messages')),
          ],
          rows: [
            for (final row in result.rows)
              DataRow(
                cells: [
                  DataCell(Text('${row.rowNumber}')),
                  DataCell(_SeverityLabel(severity: row.severity)),
                  for (final column in result.columns)
                    DataCell(Text(row.values[column] ?? '')),
                  DataCell(Text(row.messages.join('; '))),
                ],
              ),
          ],
        ),
      ),
    ],
  );
}

class _SeverityLabel extends StatelessWidget {
  final ImportRowSeverity severity;
  const _SeverityLabel({required this.severity});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, icon, color) = switch (severity) {
      ImportRowSeverity.valid => (
        'Valid',
        Icons.check_circle_outline,
        scheme.primary,
      ),
      ImportRowSeverity.warning => (
        'Warning',
        Icons.warning_amber_outlined,
        scheme.tertiary,
      ),
      ImportRowSeverity.error => ('Error', Icons.error_outline, scheme.error),
    };
    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
    );
  }
}
