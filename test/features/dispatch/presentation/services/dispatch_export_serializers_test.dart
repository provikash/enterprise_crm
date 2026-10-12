import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive.dart';

import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_item.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_record.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_status.dart';
import 'package:enterprise_crm/features/dispatch/presentation/services/dispatch_csv_serializer.dart';
import 'package:enterprise_crm/features/dispatch/presentation/services/dispatch_pdf_serializer.dart';
import 'package:enterprise_crm/features/dispatch/presentation/services/dispatch_xlsx_serializer.dart';

void main() {
  final sampleItems = [
    const DispatchItem(
      id: 'item-1',
      name: 'Industrial Valve 2-inch',
      sku: 'VLV-002',
      quantity: 5.0,
      unit: 'Pcs',
      unitPrice: 1200.0,
    ),
    const DispatchItem(
      id: 'item-2',
      name: 'Flange Gasket Set',
      sku: 'GSK-009',
      quantity: 10.0,
      unit: 'Sets',
      unitPrice: 150.0,
    ),
  ];

  final sampleRecord = DispatchRecord(
    id: 'dsp-1',
    dispatchCode: 'DSP-2026-0001',
    orderNumber: 'ORD-9021',
    customerName: 'Acme Heavy Industries',
    customerPhone: '+91 98765 43210',
    deliveryAddress: 'Plot 45, MIDC Industrial Area, Pune, Maharashtra',
    invoiceNumber: 'INV-2026-101',
    invoiceDate: DateTime(2026, 10, 11),
    invoiceAmount: 7500.0,
    transporterName: 'BlueDart Express',
    vehicleNumber: 'MH-12-AB-1234',
    vehicleType: 'Container Truck',
    driverName: 'Ramesh Kumar',
    driverPhone: '+91 98111 22233',
    builtyNumber: 'BLT-998877',
    builtyDate: DateTime(2026, 10, 11),
    notes: 'Handle with care - fragile seals',
    status: DispatchStatus.inTransit,
    items: sampleItems,
    createdAt: DateTime(2026, 10, 11, 10, 30),
    dispatchedAt: DateTime(2026, 10, 11, 14, 00),
  );

  group('DispatchCsvSerializer Tests', () {
    const serializer = DispatchCsvSerializer();

    test('generates valid CSV string with headers and record data', () {
      final csvString = serializer.convertToString([sampleRecord]);
      expect(csvString, contains('Dispatch Code,Order Number,Invoice Number'));
      expect(csvString, contains('DSP-2026-0001'));
      expect(csvString, contains('Acme Heavy Industries'));
      expect(csvString, contains('BlueDart Express'));
      expect(csvString, contains('7500.00'));
      expect(csvString, contains('In Transit'));
    });

    test('sanitizes formula injection prefixes (=, +, -, @)', () {
      final maliciousRecord = sampleRecord.copyWith(
        customerName: '=cmd|\' /C calc\'!A0',
        orderNumber: '+9999999',
        notes: '@malicious',
      );

      final csvString = serializer.convertToString([maliciousRecord]);
      expect(csvString, contains("'=cmd|' /C calc'!A0"));
      expect(csvString, contains("'+9999999"));
      expect(csvString, contains("'@malicious"));
    });

    test('convertToBytes outputs valid UTF-8 bytes', () {
      final bytes = serializer.convertToBytes([sampleRecord]);
      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
      final decoded = utf8.decode(bytes);
      expect(decoded, contains('DSP-2026-0001'));
    });
  });

  group('DispatchXlsxSerializer Tests', () {
    final serializer = DispatchXlsxSerializer();

    test('generates valid XLSX archive with Dispatches worksheet', () {
      final bytes = serializer.convertToBytes([sampleRecord]);
      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);

      // Verify it's a valid ZIP archive containing workbook files
      final archive = ZipDecoder().decodeBytes(bytes);
      expect(archive.isNotEmpty, isTrue);
      final entryNames = archive.files.map((f) => f.name).toList();
      expect(entryNames.any((name) => name.contains('workbook.xml')), isTrue);
    });
  });

  group('DispatchPdfSerializer Tests', () {
    const serializer = DispatchPdfSerializer();

    test('generateDispatchesReport produces valid PDF 1.4 stream', () {
      final bytes = serializer.generateDispatchesReport(
        [sampleRecord],
        title: 'Monthly Dispatch Register',
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(100));

      final str = ascii.decode(bytes.sublist(0, 15));
      expect(str.startsWith('%PDF-1.4'), isTrue);

      final tail = ascii.decode(bytes.sublist(bytes.length - 20));
      expect(tail.contains('%%EOF'), isTrue);
    });

    test('generateBillPdf produces valid single-dispatch delivery challan PDF', () {
      final bytes = serializer.generateBillPdf(sampleRecord);

      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(200));

      final head = ascii.decode(bytes.sublist(0, 15));
      expect(head.startsWith('%PDF-1.4'), isTrue);

      final tail = ascii.decode(bytes.sublist(bytes.length - 20));
      expect(tail.contains('%%EOF'), isTrue);

      // Verify bill contains the document title & items in stream
      final fullText = String.fromCharCodes(bytes);
      expect(fullText, contains('DISPATCH BILL & DELIVERY CHALLAN'));
      expect(fullText, contains('DSP-2026-0001'));
      expect(fullText, contains('Acme Heavy Industries'));
    });
  });
}
