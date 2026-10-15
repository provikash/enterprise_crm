enum ImportRowSeverity { valid, warning, error }

class ImportValidationRow {
  final int rowNumber;
  final ImportRowSeverity severity;
  final Map<String, String> values;
  final List<String> messages;

  const ImportValidationRow({
    required this.rowNumber,
    required this.severity,
    required this.values,
    this.messages = const [],
  });
}

class ImportValidationResult {
  final String validationToken;
  final List<String> columns;
  final List<ImportValidationRow> rows;

  const ImportValidationResult({
    required this.validationToken,
    required this.columns,
    required this.rows,
  });

  int get validCount =>
      rows.where((row) => row.severity == ImportRowSeverity.valid).length;
  int get warningCount =>
      rows.where((row) => row.severity == ImportRowSeverity.warning).length;
  int get errorCount =>
      rows.where((row) => row.severity == ImportRowSeverity.error).length;
  bool get canImport => rows.isNotEmpty && errorCount == 0;
}
