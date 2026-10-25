// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:xml/xml.dart';

import '../../domain/entities/lead_source.dart';
import '../models/lead_import_parsed_file.dart';
import '../models/lead_import_selected_file.dart';

/// Exception thrown when file parsing fails with a user-safe message.
class LeadImportParseException implements Exception {
  const LeadImportParseException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Abstract interface for parsing selected Lead import files.
abstract interface class LeadImportParser {
  Future<LeadImportParsedFile> parse(LeadImportSelectedFile file);
}

/// Default implementation of [LeadImportParser] supporting CSV and Excel (XLSX/XLS) formats.
class DefaultLeadImportParser implements LeadImportParser {
  const DefaultLeadImportParser();

  @override
  Future<LeadImportParsedFile> parse(LeadImportSelectedFile file) async {
    final ext = file.extension.trim().toLowerCase();
    final isCsv = ext == 'csv';
    final isExcel = ext == 'xlsx' || ext == 'xls';

    // Validate extension and source consistency
    if (isCsv && file.source != LeadSource.csv) {
      throw const LeadImportParseException(
        'Unsupported or inconsistent import file.',
      );
    }
    if (isExcel && file.source != LeadSource.excel) {
      throw const LeadImportParseException(
        'Unsupported or inconsistent import file.',
      );
    }
    if (!isCsv && !isExcel) {
      throw const LeadImportParseException('Unsupported file type.');
    }

    try {
      if (isCsv) {
        return await _parseCsv(file);
      } else {
        return await _parseExcel(file);
      }
    } on LeadImportParseException {
      rethrow;
    } catch (_) {
      if (isCsv) {
        throw const LeadImportParseException('Unable to read this CSV file.');
      } else {
        throw const LeadImportParseException('Unable to read this Excel file.');
      }
    }
  }

  Future<LeadImportParsedFile> _parseCsv(LeadImportSelectedFile file) async {
    final Uint8List bytes;
    try {
      bytes = await file.content.readAsBytes();
    } catch (_) {
      throw const LeadImportParseException('Unable to read this CSV file.');
    }

    String csvText;
    try {
      csvText = utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      throw const LeadImportParseException('Unable to read this CSV file.');
    } catch (_) {
      throw const LeadImportParseException('Unable to read this CSV file.');
    }

    // Strip UTF-8 BOM if present
    if (csvText.startsWith('\uFEFF')) {
      csvText = csvText.substring(1);
    }

    const decoder = CsvDecoder(
      dynamicTyping: false,
      parseHeaders: false,
      skipEmptyLines: false,
    );

    final List<List<dynamic>> rawRows;
    try {
      rawRows = decoder.convert(csvText);
    } catch (_) {
      throw const LeadImportParseException('Unable to read this CSV file.');
    }

    final parsedRows = rawRows
        .map(
          (row) => List<String>.unmodifiable(
            row.map((cell) => cell?.toString() ?? ''),
          ),
        )
        .toList(growable: false);

    return LeadImportParsedFile(
      fileName: file.name,
      source: LeadSource.csv,
      sheets: List.unmodifiable([
        LeadImportParsedSheet(name: 'CSV', rows: List.unmodifiable(parsedRows)),
      ]),
    );
  }

  Future<LeadImportParsedFile> _parseExcel(LeadImportSelectedFile file) async {
    final Uint8List bytes;
    try {
      bytes = await file.content.readAsBytes();
    } catch (_) {
      throw const LeadImportParseException('Unable to read this Excel file.');
    }

    // 1. Attempt package:excel decode
    try {
      final excel = Excel.decodeBytes(bytes);
      final parsedSheets = <LeadImportParsedSheet>[];

      for (final entry in excel.tables.entries) {
        final sheetName = entry.key;
        final sheet = entry.value;
        final maxCols = sheet.maxColumns;

        final parsedRows = <List<String>>[];
        for (final rawRow in sheet.rows) {
          final rowCells = <String>[];
          final colCount = maxCols > rawRow.length ? maxCols : rawRow.length;

          for (var i = 0; i < colCount; i++) {
            if (i < rawRow.length) {
              final cell = rawRow[i];
              rowCells.add(_convertCellValue(cell?.value));
            } else {
              rowCells.add('');
            }
          }
          parsedRows.add(List<String>.unmodifiable(rowCells));
        }

        parsedSheets.add(
          LeadImportParsedSheet(
            name: sheetName,
            rows: List<List<String>>.unmodifiable(parsedRows),
          ),
        );
      }

      if (parsedSheets.isNotEmpty) {
        return LeadImportParsedFile(
          fileName: file.name,
          source: LeadSource.excel,
          sheets: List.unmodifiable(parsedSheets),
        );
      }
    } catch (_) {
      // Fall through to direct OOXML parse fallback
    }

    // 2. Direct OOXML zip parse fallback (handles complex shared strings / namespaces / custom styling that crash package:excel)
    try {
      final directParsed = _tryDirectOoxmlParse(bytes, file.name);
      if (directParsed != null && directParsed.sheets.isNotEmpty) {
        return directParsed;
      }
    } catch (_) {
      // Fall through to delimited fallback
    }

    // 3. Fallback for legacy web systems that export CSV or TSV with .xls extension
    final isXls = file.extension.trim().toLowerCase() == 'xls';
    if (isXls) {
      try {
        var text = utf8.decode(bytes, allowMalformed: false);
        if (text.startsWith('\uFEFF')) {
          text = text.substring(1);
        }
        final separator = text.contains('\t') ? '\t' : ',';
        final decoder = CsvDecoder(
          fieldDelimiter: separator,
          dynamicTyping: false,
          parseHeaders: false,
          skipEmptyLines: false,
        );
        final rawRows = decoder.convert(text);
        if (rawRows.isNotEmpty && rawRows.first.isNotEmpty) {
          final parsedRows = rawRows
              .map(
                (r) => List<String>.unmodifiable(
                  r.map((c) => c?.toString() ?? ''),
                ),
              )
              .toList(growable: false);
          return LeadImportParsedFile(
            fileName: file.name,
            source: LeadSource.excel,
            sheets: List.unmodifiable([
              LeadImportParsedSheet(
                name: 'Sheet1',
                rows: List.unmodifiable(parsedRows),
              ),
            ]),
          );
        }
      } catch (_) {
        // Ignored
      }
    }

    throw const LeadImportParseException('Unable to read this Excel file.');
  }

  LeadImportParsedFile? _tryDirectOoxmlParse(Uint8List bytes, String fileName) {
    final archive = ZipDecoder().decodeBytes(bytes);

    final sharedStrings = <String>[];
    final ssFile = archive.findFile('xl/sharedStrings.xml');
    if (ssFile != null) {
      ssFile.decompress();
      final ssContent = utf8.decode(ssFile.content, allowMalformed: true);
      final ssDoc = XmlDocument.parse(ssContent);
      for (final si in ssDoc
          .findAllElements('*')
          .where((e) => e.name.local == 'si')) {
        final text = si
            .findAllElements('*')
            .where((e) => e.name.local == 't')
            .map((e) => e.innerText)
            .join();
        sharedStrings.add(text);
      }
    }

    final relsFile = archive.findFile('xl/_rels/workbook.xml.rels');
    final relMap = <String, String>{};
    if (relsFile != null) {
      relsFile.decompress();
      final relsContent = utf8.decode(relsFile.content, allowMalformed: true);
      final relsDoc = XmlDocument.parse(relsContent);
      for (final r in relsDoc
          .findAllElements('*')
          .where((e) => e.name.local == 'Relationship')) {
        final id = r.getAttribute('Id');
        var target = r.getAttribute('Target') ?? '';
        if (target.startsWith('/')) target = target.substring(1);
        if (!target.startsWith('xl/')) target = 'xl/$target';
        if (id != null) relMap[id] = target;
      }
    }

    final wbFile = archive.findFile('xl/workbook.xml');
    if (wbFile == null) return null;
    wbFile.decompress();
    final wbContent = utf8.decode(wbFile.content, allowMalformed: true);
    final wbDoc = XmlDocument.parse(wbContent);

    final parsedSheets = <LeadImportParsedSheet>[];
    for (final s in wbDoc
        .findAllElements('*')
        .where((e) => e.name.local == 'sheet')) {
      final name = s.getAttribute('name');
      final rId = s.getAttribute('r:id') ?? s.getAttribute('id') ?? '';
      if (name == null) continue;
      final target = relMap[rId];
      if (target == null) continue;

      final wsFile = archive.findFile(target);
      if (wsFile == null) continue;
      wsFile.decompress();
      final wsContent = utf8.decode(wsFile.content, allowMalformed: true);
      final wsDoc = XmlDocument.parse(wsContent);

      var sheetMaxCol = 0;
      final rawRowMaps = <Map<int, String>>[];
      for (final r in wsDoc
          .findAllElements('*')
          .where((e) => e.name.local == 'row')) {
        final cellMap = <int, String>{};
        for (final c in r
            .findAllElements('*')
            .where((e) => e.name.local == 'c')) {
          final ref = c.getAttribute('r') ?? '';
          final colIdx = _colRefToIndex(ref);
          final t = c.getAttribute('t');
          final v = c
              .findAllElements('*')
              .where((e) => e.name.local == 'v')
              .firstOrNull
              ?.innerText ??
              '';
          final f = c
              .findAllElements('*')
              .where((e) => e.name.local == 'f')
              .firstOrNull
              ?.innerText;
          final inlineStr = c
              .findAllElements('*')
              .where((e) => e.name.local == 'is')
              .firstOrNull
              ?.findAllElements('*')
              .where((e) => e.name.local == 't')
              .firstOrNull
              ?.innerText;

          final String cellVal;
          if (f != null && f.isNotEmpty) {
            cellVal = f.startsWith('=') ? f : '=$f';
          } else if (t == 'b') {
            cellVal =
                (v == '1' || v.toLowerCase() == 'true') ? 'true' : 'false';
          } else if (t == 's') {
            final idx = int.tryParse(v);
            cellVal = idx != null && idx < sharedStrings.length
                ? sharedStrings[idx]
                : '';
          } else if (inlineStr != null) {
            cellVal = inlineStr;
          } else {
            cellVal = v;
          }

          cellMap[colIdx] = cellVal;
          if (colIdx + 1 > sheetMaxCol) sheetMaxCol = colIdx + 1;
        }

        rawRowMaps.add(cellMap);
      }

      final rows = <List<String>>[];
      for (final cellMap in rawRowMaps) {
        final rowCells = List<String>.generate(
          sheetMaxCol,
          (i) => cellMap[i] ?? '',
          growable: false,
        );
        rows.add(rowCells);
      }

      parsedSheets.add(
        LeadImportParsedSheet(
          name: name,
          rows: List.unmodifiable(rows),
        ),
      );
    }

    if (parsedSheets.isEmpty) return null;

    return LeadImportParsedFile(
      fileName: fileName,
      source: LeadSource.excel,
      sheets: List.unmodifiable(parsedSheets),
    );
  }

  static int _colRefToIndex(String cellRef) {
    var col = 0;
    for (var i = 0; i < cellRef.length; i++) {
      final code = cellRef.codeUnitAt(i);
      if (code >= 65 && code <= 90) {
        col = col * 26 + (code - 64);
      } else if (code >= 97 && code <= 122) {
        col = col * 26 + (code - 96);
      } else {
        break;
      }
    }
    return col > 0 ? col - 1 : 0;
  }

  String _convertCellValue(CellValue? value) {
    if (value == null) return '';
    switch (value) {
      case TextCellValue(:final value):
        return value.toString();
      case IntCellValue(:final value):
        return value.toString();
      case DoubleCellValue(:final value):
        return value.toString();
      case BoolCellValue(:final value):
        return value.toString();
      case DateCellValue(:final year, :final month, :final day):
        final y = year.toString().padLeft(4, '0');
        final m = month.toString().padLeft(2, '0');
        final d = day.toString().padLeft(2, '0');
        return '$y-$m-$d';
      case DateTimeCellValue(
        :final year,
        :final month,
        :final day,
        :final hour,
        :final minute,
        :final second,
      ):
        final y = year.toString().padLeft(4, '0');
        final m = month.toString().padLeft(2, '0');
        final d = day.toString().padLeft(2, '0');
        final hh = hour.toString().padLeft(2, '0');
        final mm = minute.toString().padLeft(2, '0');
        final ss = second.toString().padLeft(2, '0');
        return '$y-$m-${d}T$hh:$mm:$ss';
      case TimeCellValue(:final hour, :final minute, :final second):
        final hh = hour.toString().padLeft(2, '0');
        final mm = minute.toString().padLeft(2, '0');
        final ss = second.toString().padLeft(2, '0');
        return '$hh:$mm:$ss';
      case FormulaCellValue(:final formula):
        return formula;
    }
  }
}
