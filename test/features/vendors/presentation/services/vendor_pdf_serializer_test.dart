import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_record.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_status.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_record.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_status.dart';
import 'package:enterprise_crm/features/vendors/presentation/services/vendor_pdf_serializer.dart';

void main() {
  group('VendorPdfSerializer Tests', () {
    const serializer = VendorPdfSerializer();

    final testVendor = VendorRecord(
      id: '1',
      vendorCode: 'VND-001',
      companyName: 'Apex Tech Supplies Pvt Ltd',
      contactPerson: 'Vikram Malhotra',
      email: 'sales@apextechsupplies.com',
      phone: '+91 98111 22334',
      alternatePhone: '+91 11 4567 8901',
      address: 'Plot 45, Phase 2, Udyog Vihar',
      city: 'Gurugram',
      state: 'Haryana',
      pincode: '122016',
      gstin: '07AAAAA0000A1Z5',
      pan: 'AAAAA0000A',
      category: 'Electronics',
      status: VendorStatus.active,
      rating: 4.8,
      paymentTerms: 'Net 30 Days',
      creditLimitInr: 1500000.0,
      bankName: 'HDFC Bank',
      accountNumber: '50200012345678',
      ifscCode: 'HDFC0000123',
      branchName: 'Cyber City, Gurugram',
      notes: 'Strategic supplier for electronics components.',
      createdAt: DateTime(2026, 1, 1),
    );

    test('generateVendorDirectoryReport produces valid PDF 1.4 document', () {
      final bytes = serializer.generateVendorDirectoryReport([testVendor]);
      expect(bytes, isNotEmpty);

      final str = ascii.decode(bytes, allowInvalid: true);
      expect(str, startsWith('%PDF-1.4'));
      expect(str, contains('%%EOF'));
      expect(str, contains('VND-001'));
      expect(str, contains('Apex Tech Supplies Pvt Ltd'));
    });

    test('generateVendorProfilePdf produces complete vendor dossier with PO breakdown', () {
      final po = PurchaseOrderRecord(
        id: 'po-1',
        poNumber: 'PO-2026-001',
        vendorName: 'Apex Tech Supplies Pvt Ltd',
        vendorGst: '07AAAAA0000A1Z5',
        orderDate: DateTime(2026, 2, 1),
        expectedDeliveryDate: DateTime(2026, 2, 15),
        items: const [],
        subtotalAmount: 100000.0,
        taxAmount: 18000.0,
        totalAmount: 118000.0,
        status: PurchaseOrderStatus.ordered,
        shippingAddress: 'Main Warehouse',
        paymentTerms: 'Net 30',
        createdAt: DateTime(2026, 2, 1),
      );

      final bytes = serializer.generateVendorProfilePdf(testVendor, relatedOrders: [po]);
      expect(bytes, isNotEmpty);

      final str = ascii.decode(bytes, allowInvalid: true);
      expect(str, startsWith('%PDF-1.4'));
      expect(str, contains('%%EOF'));
      expect(str, contains('VND-001'));
      expect(str, contains('PO-2026-001'));
      expect(str, contains('HDFC Bank'));
    });
  });
}
