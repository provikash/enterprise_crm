import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_record.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_status.dart';
import 'package:enterprise_crm/features/vendors/presentation/services/vendor_file_saver.dart';
import 'package:enterprise_crm/features/vendors/presentation/widgets/vendor_export_dialog.dart';

void main() {
  group('VendorExportDialog Widget Tests', () {
    final sampleVendors = [
      VendorRecord(
        id: '1',
        vendorCode: 'VND-001',
        companyName: 'Apex Tech Supplies',
        category: 'Electronics',
        status: VendorStatus.active,
        createdAt: DateTime(2026, 1, 1),
      ),
    ];

    testWidgets('renders format options and downloads CSV by default', (tester) async {
      String? savedExtension;
      String? savedMime;

      final saver = _TestVendorFileSaver(
        onSave: (ext, mime) {
          savedExtension = ext;
          savedMime = mime;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VendorExportDialog(
              vendors: sampleVendors,
              fileSaver: saver,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Export Vendor Directory'), findsOneWidget);
      expect(find.byKey(const Key('vendor_export_format_csv')), findsOneWidget);
      expect(find.byKey(const Key('vendor_export_format_excel')), findsOneWidget);
      expect(find.byKey(const Key('vendor_export_format_pdf')), findsOneWidget);

      await tester.tap(find.byKey(const Key('vendor_export_confirm_button')));
      await tester.pumpAndSettle();

      expect(savedExtension, 'csv');
      expect(savedMime, 'text/csv');
    });

    testWidgets('selecting Excel format downloads XLSX file', (tester) async {
      String? savedExtension;
      String? savedMime;

      final saver = _TestVendorFileSaver(
        onSave: (ext, mime) {
          savedExtension = ext;
          savedMime = mime;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VendorExportDialog(
              vendors: sampleVendors,
              fileSaver: saver,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('vendor_export_format_excel')));
      await tester.pumpAndSettle();

      expect(find.text('Download XLSX'), findsOneWidget);

      await tester.tap(find.byKey(const Key('vendor_export_confirm_button')));
      await tester.pumpAndSettle();

      expect(savedExtension, 'xlsx');
      expect(savedMime, contains('spreadsheetml.sheet'));
    });

    testWidgets('selecting PDF format downloads PDF file', (tester) async {
      String? savedExtension;
      String? savedMime;

      final saver = _TestVendorFileSaver(
        onSave: (ext, mime) {
          savedExtension = ext;
          savedMime = mime;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VendorExportDialog(
              vendors: sampleVendors,
              fileSaver: saver,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('vendor_export_format_pdf')));
      await tester.pumpAndSettle();

      expect(find.text('Download PDF'), findsOneWidget);

      await tester.tap(find.byKey(const Key('vendor_export_confirm_button')));
      await tester.pumpAndSettle();

      expect(savedExtension, 'pdf');
      expect(savedMime, 'application/pdf');
    });
  });
}

class _TestVendorFileSaver implements VendorFileSaver {
  final void Function(String extension, String mimeType) onSave;

  _TestVendorFileSaver({required this.onSave});

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    required String extension,
    String? dialogTitle,
  }) async {
    onSave(extension, mimeType);
    return Uri.parse('file:///$fileName');
  }
}
