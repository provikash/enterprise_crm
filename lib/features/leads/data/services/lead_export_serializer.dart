import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_export.dart';

/// Strongly typed result of serializing leads into export bytes.
class LeadExportContent {
  const LeadExportContent({
    required this.bytes,
    required this.extension,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String extension;
  final String mimeType;
}

/// Abstract interface for in-memory lead export serialization.
abstract interface class LeadExportSerializer {
  LeadExportContent serialize({
    required List<Lead> leads,
    required LeadExportFormat format,
  });
}

/// Default implementation of [LeadExportSerializer] converting [Lead] objects
/// into CSV (UTF-8) or XLSX (Excel) bytes following the frozen L7A column policy.
class DefaultLeadExportSerializer implements LeadExportSerializer {
  const DefaultLeadExportSerializer();

  /// Authoritative export column headers including all manual add fields.
  static const List<String> exportHeaders = [
    'Name',
    'Phone',
    'Email',
    'Business Name',
    'Status',
    'Source',
    'Priority',
    'Country',
    'State',
    'City',
    'Requirement',
    'Estimated Value',
    'Notes',
    'Assigned To',
    'Created At',
    'Updated At',
  ];

  static const String csvMimeType = 'text/csv';
  static const String excelMimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  static const String excelSheetName = 'Leads';
  static const String pdfMimeType = 'application/pdf';
  static const List<int> _utf8Bom = [0xEF, 0xBB, 0xBF];

  @override
  LeadExportContent serialize({
    required List<Lead> leads,
    required LeadExportFormat format,
  }) {
    switch (format) {
      case LeadExportFormat.csv:
        return _serializeCsv(leads);
      case LeadExportFormat.excel:
        return _serializeExcel(leads);
      case LeadExportFormat.pdf:
        return _serializePdf(leads);
    }
  }

  LeadExportContent _serializePdf(List<Lead> leads) {
    final bytes = _buildPdfDocument(leads);
    return LeadExportContent(
      bytes: bytes,
      extension: 'pdf',
      mimeType: pdfMimeType,
    );
  }

  Uint8List _buildPdfDocument(List<Lead> leads) {
    final columns = <_PdfColumn>[
      _PdfColumn('Name', 95.0, (l) => l.name ?? ''),
      _PdfColumn('Phone', 70.0, (l) => l.phone ?? ''),
      _PdfColumn('Email', 105.0, (l) => l.email ?? ''),
      _PdfColumn('Business', 85.0, (l) => l.businessName ?? ''),
      _PdfColumn('Status', 55.0, (l) => l.status?.value ?? ''),
      _PdfColumn(
        'Source',
        60.0,
        (l) => (l.metadata?['source_detail'] != null &&
                l.metadata!['source_detail']!.trim().isNotEmpty)
            ? l.metadata!['source_detail']!.trim()
            : l.source.displayName,
      ),
      _PdfColumn('Priority', 45.0, (l) => l.metadata?['priority'] ?? ''),
      _PdfColumn(
        'Location',
        65.0,
        (l) => [
          l.city ?? l.metadata?['city'] ?? '',
          l.state ?? l.metadata?['state'] ?? '',
        ].where((s) => s.isNotEmpty).join(', '),
      ),
      _PdfColumn('Requirement', 85.0, (l) => l.metadata?['requirement'] ?? ''),
      _PdfColumn('Assigned', 65.0, (l) => l.assignedUserName ?? 'Unassigned'),
      _PdfColumn(
        'Created',
        52.0,
        (l) => l.createdAt != null
            ? '${l.createdAt!.year}-${l.createdAt!.month.toString().padLeft(2, '0')}-${l.createdAt!.day.toString().padLeft(2, '0')}'
            : '',
      ),
    ];

    const rowsPerPage = 24;
    final totalPages = leads.isEmpty ? 1 : ((leads.length + rowsPerPage - 1) ~/ rowsPerPage);

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final pageStreams = <String>[];
    for (var p = 0; p < totalPages; p++) {
      final pageLeads = leads.isEmpty
          ? <Lead>[]
          : leads.skip(p * rowsPerPage).take(rowsPerPage).toList();

      final sb = StringBuffer();
      // Header banner
      sb.writeln('0.08 0.18 0.36 rg');
      sb.writeln('BT');
      sb.writeln('/F2 14 Tf');
      sb.writeln('1 0 0 1 30 565 Tm');
      sb.writeln('(${_escapePdf('ENTERPRISE CRM - LEADS DIRECTORY')}) Tj');
      sb.writeln('ET');

      sb.writeln('0.40 0.45 0.50 rg');
      sb.writeln('BT');
      sb.writeln('/F1 8.5 Tf');
      sb.writeln('1 0 0 1 30 550 Tm');
      sb.writeln('(${_escapePdf('Export Date: $dateStr   |   Total Records: ${leads.length}')}) Tj');
      sb.writeln('ET');

      // Table Header Background (dark slate: 0.12 0.23 0.38)
      sb.writeln('0.12 0.23 0.38 rg');
      sb.writeln('30 524 782 18 re f');

      // Header labels
      sb.writeln('1 1 1 rg');
      var curX = 30.0;
      for (final col in columns) {
        sb.writeln('BT');
        sb.writeln('/F2 7.5 Tf');
        sb.writeln('1 0 0 1 ${curX + 3} 529 Tm');
        sb.writeln('(${_escapePdf(_truncateToWidth(col.title, col.width, 4.4))}) Tj');
        sb.writeln('ET');
        curX += col.width;
      }

      if (pageLeads.isEmpty) {
        sb.writeln('0.98 0.98 0.99 rg');
        sb.writeln('30 488 782 18 re f');
        sb.writeln('0.50 0.50 0.50 rg');
        sb.writeln('BT');
        sb.writeln('/F1 8 Tf');
        sb.writeln('1 0 0 1 360 493 Tm');
        sb.writeln('(No leads to display.) Tj');
        sb.writeln('ET');
      } else {
        for (var r = 0; r < pageLeads.length; r++) {
          final lead = pageLeads[r];
          final rowY = 506.0 - (r * 18.0);

          if (r % 2 == 0) {
            sb.writeln('1 1 1 rg');
          } else {
            sb.writeln('0.96 0.97 0.98 rg');
          }
          sb.writeln('30 $rowY 782 18 re f');

          sb.writeln('0.88 0.90 0.92 RG');
          sb.writeln('0.5 w');
          sb.writeln('30 $rowY m 812 $rowY l S');

          sb.writeln('0.15 0.18 0.22 rg');
          curX = 30.0;
          for (final col in columns) {
            final rawVal = col.getValue(lead);
            final safeVal = _escapePdf(_truncateToWidth(rawVal, col.width - 6, 4.1));
            sb.writeln('BT');
            sb.writeln('/F1 7.2 Tf');
            sb.writeln('1 0 0 1 ${curX + 3} ${rowY + 5} Tm');
            sb.writeln('($safeVal) Tj');
            sb.writeln('ET');
            curX += col.width;
          }
        }
      }

      // Footer
      sb.writeln('0.55 0.60 0.65 rg');
      sb.writeln('BT');
      sb.writeln('/F1 7.5 Tf');
      sb.writeln('1 0 0 1 30 22 Tm');
      sb.writeln('(${_escapePdf('Enterprise CRM  |  Confidential')}) Tj');
      sb.writeln('ET');

      sb.writeln('BT');
      sb.writeln('/F1 7.5 Tf');
      sb.writeln('1 0 0 1 735 22 Tm');
      sb.writeln('(${_escapePdf('Page ${p + 1} of $totalPages')}) Tj');
      sb.writeln('ET');

      pageStreams.add(sb.toString());
    }

    final totalObjects = 4 + 2 * totalPages;
    final offsets = List<int>.filled(totalObjects + 1, 0);
    final bb = BytesBuilder();

    void write(String s) {
      bb.add(utf8.encode(s));
    }

    write('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n');

    // Obj 1: Catalog
    offsets[1] = bb.length;
    write('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');

    // Obj 2: Pages
    offsets[2] = bb.length;
    final kids = List.generate(totalPages, (i) => '${5 + 2 * i} 0 R').join(' ');
    write('2 0 obj\n<< /Type /Pages /Kids [ $kids ] /Count $totalPages >>\nendobj\n');

    // Obj 3: Font Regular
    offsets[3] = bb.length;
    write('3 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>\nendobj\n');

    // Obj 4: Font Bold
    offsets[4] = bb.length;
    write('4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>\nendobj\n');

    // Page and Stream objects
    for (var p = 0; p < totalPages; p++) {
      final pageObjId = 5 + 2 * p;
      final streamObjId = 6 + 2 * p;
      final streamBytes = utf8.encode(pageStreams[p]);

      offsets[pageObjId] = bb.length;
      write('$pageObjId 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 842 595] /Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents $streamObjId 0 R >>\nendobj\n');

      offsets[streamObjId] = bb.length;
      write('$streamObjId 0 obj\n<< /Length ${streamBytes.length} >>\nstream\n');
      bb.add(streamBytes);
      write('\nendstream\nendobj\n');
    }

    final xrefOffset = bb.length;
    write('xref\n0 ${totalObjects + 1}\n0000000000 65535 f \n');
    for (var i = 1; i <= totalObjects; i++) {
      final offStr = offsets[i].toString().padLeft(10, '0');
      write('$offStr 00000 n \n');
    }

    write('trailer\n<< /Size ${totalObjects + 1} /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF\n');

    return bb.toBytes();
  }

  static String _escapePdf(String text) {
    final sb = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      final char = text[i];
      if (char == '\\' || char == '(' || char == ')') {
        sb.write('\\$char');
      } else if (code >= 32 && code <= 126) {
        sb.write(char);
      } else {
        sb.write(' ');
      }
    }
    return sb.toString();
  }

  static String _truncateToWidth(String text, double colWidth, [double charWidth = 4.1]) {
    final maxChars = (colWidth / charWidth).floor() - 1;
    if (text.length <= maxChars) return text;
    if (maxChars <= 3) return text.substring(0, maxChars);
    return '${text.substring(0, maxChars - 2)}..';
  }

  LeadExportContent _serializeCsv(List<Lead> leads) {
    final rows = <List<dynamic>>[];
    rows.add(exportHeaders);

    for (final lead in leads) {
      rows.add(_leadToRow(lead));
    }

    final csvString = const CsvEncoder().convert(rows);
    final bytes = Uint8List.fromList([
      ..._utf8Bom,
      ...utf8.encode(csvString),
    ]);

    return LeadExportContent(
      bytes: bytes,
      extension: 'csv',
      mimeType: csvMimeType,
    );
  }

  LeadExportContent _serializeExcel(List<Lead> leads) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    final sheet = excel[excelSheetName];

    final headerCells = exportHeaders
        .map<CellValue?>((h) => TextCellValue(h))
        .toList();
    sheet.appendRow(headerCells);

    for (final lead in leads) {
      final row = _leadToRow(lead);
      final cells = row
          .map<CellValue?>((val) => val.isEmpty ? null : TextCellValue(val))
          .toList();
      sheet.appendRow(cells);
    }

    if (defaultSheet != null && defaultSheet != excelSheetName) {
      excel.delete(defaultSheet);
    }

    final encoded = excel.encode();
    final bytes = Uint8List.fromList(encoded ?? []);

    return LeadExportContent(
      bytes: bytes,
      extension: 'xlsx',
      mimeType: excelMimeType,
    );
  }

  List<String> _leadToRow(Lead lead) {
    final sourceVal = (lead.metadata?['source_detail'] != null &&
            lead.metadata!['source_detail']!.trim().isNotEmpty)
        ? lead.metadata!['source_detail']!.trim()
        : lead.source.name;

    return [
      lead.name ?? '',
      lead.phone ?? '',
      lead.email ?? '',
      lead.businessName ?? '',
      lead.status?.value ?? '',
      sourceVal,
      lead.metadata?['priority'] ?? '',
      lead.metadata?['country'] ?? '',
      lead.state ?? lead.metadata?['state'] ?? '',
      lead.city ?? lead.metadata?['city'] ?? '',
      lead.metadata?['requirement'] ?? '',
      lead.metadata?['estimated_value'] ?? '',
      lead.metadata?['notes'] ?? '',
      lead.assignedUserName ?? '',
      lead.createdAt?.toIso8601String() ?? '',
      lead.updatedAt?.toIso8601String() ?? '',
    ];
  }
}

class _PdfColumn {
  const _PdfColumn(this.title, this.width, this.getValue);
  final String title;
  final double width;
  final String Function(Lead) getValue;
}
