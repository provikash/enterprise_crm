import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/purchase/data/repositories/mock_purchase_repository.dart';
import 'package:enterprise_crm/features/vendors/data/repositories/mock_vendor_repository.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_record.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_status.dart';
import 'package:enterprise_crm/features/vendors/presentation/screens/vendor_details_screen.dart';
import 'package:enterprise_crm/features/vendors/presentation/services/vendor_file_saver.dart';

void main() {
  group('VendorDetailsScreen Widget Tests', () {
    late MockVendorRepository repository;
    late MockPurchaseRepository purchaseRepository;

    final sampleVendor = VendorRecord(
      id: 'vnd_1',
      vendorCode: 'VND-001',
      companyName: 'Apex Tech Supplies Pvt Ltd',
      contactPerson: 'Vikram Malhotra',
      email: 'sales@apextechsupplies.com',
      phone: '+91 98111 22334',
      gstin: '07AAAAA0000A1Z5',
      bankName: 'HDFC Bank',
      accountNumber: '50200012345678',
      ifscCode: 'HDFC0000123',
      category: 'Electronics',
      paymentTerms: 'Net 30 Days',
      status: VendorStatus.active,
      rating: 4.8,
      createdAt: DateTime(2026, 1, 1),
    );

    setUp(() {
      repository = MockVendorRepository();
      purchaseRepository = MockPurchaseRepository();
    });

    testWidgets('renders complete vendor details, banking, and tax info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VendorDetailsScreen(
            initialVendor: sampleVendor,
            repository: repository,
            purchaseRepository: purchaseRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apex Tech Supplies Pvt Ltd'), findsWidgets);
      expect(find.text('VND-001'), findsOneWidget);
      expect(find.text('Vikram Malhotra'), findsOneWidget);
      expect(find.text('+91 98111 22334'), findsOneWidget);
      expect(find.text('07AAAAA0000A1Z5'), findsOneWidget);
      expect(find.text('HDFC Bank'), findsOneWidget);
      expect(find.text('Net 30 Days'), findsOneWidget);
      expect(find.byKey(const Key('vendor_details_edit_button')), findsOneWidget);
      expect(find.byKey(const Key('vendor_details_delete_button')), findsOneWidget);
    });

    testWidgets('loads and renders associated purchase orders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VendorDetailsScreen(
            initialVendor: sampleVendor,
            repository: repository,
            purchaseRepository: purchaseRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Associated Purchase Orders'), findsOneWidget);
      expect(find.text('PO-2026-001'), findsOneWidget);
    });

    testWidgets('tapping download PDF button invokes file saver with PDF bytes', (tester) async {
      String? savedFileName;
      String? savedMimeType;

      final testFileSaver = _FakeVendorFileSaver(
        onSave: (fileName, mimeType) {
          savedFileName = fileName;
          savedMimeType = mimeType;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: VendorDetailsScreen(
            initialVendor: sampleVendor,
            repository: repository,
            purchaseRepository: purchaseRepository,
            fileSaver: testFileSaver,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('vendor_details_download_pdf_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('vendor_details_download_pdf_button')));
      await tester.pumpAndSettle();

      expect(savedFileName, 'Vendor_Profile_VND-001.pdf');
      expect(savedMimeType, 'application/pdf');
    });
  });
}

class _FakeVendorFileSaver implements VendorFileSaver {
  final void Function(String fileName, String mimeType) onSave;

  _FakeVendorFileSaver({required this.onSave});

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    required String extension,
    String? dialogTitle,
  }) async {
    onSave(fileName, mimeType);
    return Uri.parse('file:///$fileName');
  }
}
