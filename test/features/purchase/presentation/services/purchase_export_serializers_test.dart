import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_item.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_record.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_status.dart';
import 'package:enterprise_crm/features/purchase/presentation/services/purchase_csv_serializer.dart';
import 'package:enterprise_crm/features/purchase/presentation/services/purchase_pdf_serializer.dart';

void main() {
  final sampleItems = [
    const PurchaseOrderItem(
      id: 'poi_1',
      itemName: 'Steel Rod 12mm',
      sku: 'STL-ROD-012',
      category: 'Raw Materials',
      orderedQuantity: 100,
      receivedQuantity: 50,
      unit: 'Kg',
      unitPriceInr: 65.0,
    ),
    const PurchaseOrderItem(
      id: 'poi_2',
      itemName: 'Hydraulic Cylinder 50T',
      sku: 'HYD-CYL-050',
      category: 'Machinery',
      orderedQuantity: 2,
      receivedQuantity: 2,
      unit: 'Pcs',
      unitPriceInr: 12500.0,
    ),
  ];

  final sampleOrder = PurchaseOrderRecord(
    id: 'po_test_001',
    poNumber: 'PO-2026-9001',
    vendorName: 'Apex Steel & Heavy Forge Ltd',
    vendorGst: '07AAACA1234A1Z5',
    vendorContact: 'Rajesh Mehta (+91 98765 43210)',
    orderDate: DateTime(2026, 10, 10),
    expectedDeliveryDate: DateTime(2026, 10, 20),
    status: PurchaseOrderStatus.ordered,
    items: sampleItems,
    subtotalAmount: 31500.0,
    taxAmount: 5670.0,
    totalAmount: 37170.0,
    paymentTerms: 'Net 30 Days',
    shippingAddress: 'Plant 4, Industrial Area Phase II, Manesar',
    notes: 'Urgent order for project expansion',
    approvedBy: 'Admin Supervisor',
    approvedAt: DateTime(2026, 10, 11),
    createdAt: DateTime(2026, 10, 10, 9, 30),
  );

  group('PurchaseCsvSerializer Tests', () {
    const serializer = PurchaseCsvSerializer();

    test('generates valid RFC-4180 CSV with header row and escaped fields', () {
      final csv = serializer.convertToString([sampleOrder]);
      expect(csv, contains('PO Number,Vendor Name,Vendor GST,Contact,Order Date'));
      expect(csv, contains('PO-2026-9001'));
      expect(csv, contains('Apex Steel & Heavy Forge Ltd'));
      expect(csv, contains('07AAACA1234A1Z5'));
      expect(csv, contains('Ordered'));
      expect(csv, contains('31500.00'));
      expect(csv, contains('5670.00'));
      expect(csv, contains('37170.00'));
      expect(csv, contains('Net 30 Days'));
    });

    test('escapes quotes and commas properly', () {
      final poWithSpecialChars = sampleOrder.copyWith(
        vendorName: 'Acme, "Forging" Division',
        notes: 'Line 1\nLine 2',
      );
      final csv = serializer.convertToString([poWithSpecialChars]);
      expect(csv, contains('"Acme, ""Forging"" Division"'));
      expect(csv, contains('"Line 1\nLine 2"'));
    });

    test('convertToBytes outputs valid UTF-8 byte array', () {
      final bytes = serializer.convertToBytes([sampleOrder]);
      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
      final decoded = utf8.decode(bytes);
      expect(decoded, contains('PO-2026-9001'));
    });
  });

  group('PurchasePdfSerializer Tests', () {
    const serializer = PurchasePdfSerializer();

    test('generatePurchaseOrdersReport produces valid PDF 1.4 stream', () {
      final bytes = serializer.generatePurchaseOrdersReport(
        [sampleOrder],
        title: 'Quarterly Procurement Register',
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(150));

      final head = ascii.decode(bytes.sublist(0, 15));
      expect(head.startsWith('%PDF-1.4'), isTrue);

      final tail = ascii.decode(bytes.sublist(bytes.length - 20));
      expect(tail.contains('%%EOF'), isTrue);

      final fullContent = String.fromCharCodes(bytes);
      expect(fullContent, contains('PO-2026-9001'));
      expect(fullContent, contains('Apex Steel'));
    });

    test('generatePurchaseOrdersReport handles empty order list cleanly', () {
      final bytes = serializer.generatePurchaseOrdersReport(
        [],
        title: 'Empty PO Register',
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(100));

      final head = ascii.decode(bytes.sublist(0, 15));
      expect(head.startsWith('%PDF-1.4'), isTrue);

      final tail = ascii.decode(bytes.sublist(bytes.length - 20));
      expect(tail.contains('%%EOF'), isTrue);
    });

    test('generatePurchaseOrderBillPdf produces valid official PO document', () {
      final bytes = serializer.generatePurchaseOrderBillPdf(sampleOrder);

      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(250));

      final head = ascii.decode(bytes.sublist(0, 15));
      expect(head.startsWith('%PDF-1.4'), isTrue);

      final tail = ascii.decode(bytes.sublist(bytes.length - 20));
      expect(tail.contains('%%EOF'), isTrue);

      final fullContent = String.fromCharCodes(bytes);
      expect(fullContent, contains('ENTERPRISE CRM - OFFICIAL PURCHASE ORDER'));
      expect(fullContent, contains('PO-2026-9001'));
      expect(fullContent, contains('Apex Steel & Heavy Forge Ltd'));
      expect(fullContent, contains('Steel Rod 12mm'));
      expect(fullContent, contains('Hydraulic Cylinder 50T'));
    });
  });
}
