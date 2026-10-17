import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/vendors/data/repositories/mock_vendor_repository.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_record.dart';
import 'package:enterprise_crm/features/vendors/presentation/screens/create_edit_vendor_screen.dart';

void main() {
  group('CreateEditVendorScreen Widget Tests', () {
    late MockVendorRepository repository;

    setUp(() {
      repository = MockVendorRepository();
    });

    testWidgets('renders all section fields in create mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CreateEditVendorScreen(repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add New Vendor'), findsOneWidget);
      expect(find.byKey(const Key('vendor_form_name')), findsOneWidget);
      expect(find.byKey(const Key('vendor_form_code')), findsOneWidget);
      expect(find.byKey(const Key('vendor_form_phone')), findsOneWidget);
      expect(find.byKey(const Key('vendor_form_email')), findsOneWidget);
      expect(find.byKey(const Key('vendor_form_gstin')), findsOneWidget);
    });

    testWidgets('pre-populates fields in edit mode', (tester) async {
      final vendor = VendorRecord(
        id: 'vnd_1',
        vendorCode: 'VND-001',
        companyName: 'Apex Tech',
        phone: '+91 98111 22334',
        email: 'sales@apex.com',
        gstin: '07AAAAA0000A1Z5',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CreateEditVendorScreen(
            repository: repository,
            vendor: vendor,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Vendor'), findsOneWidget);
      final nameField = tester.widget<TextFormField>(find.byKey(const Key('vendor_form_name')));
      expect(nameField.controller?.text, 'Apex Tech');
      final codeField = tester.widget<TextFormField>(find.byKey(const Key('vendor_form_code')));
      expect(codeField.controller?.text, 'VND-001');
    });

    testWidgets('submitting valid vendor calls repository and triggers onSaved', (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      VendorRecord? savedRecord;

      await tester.pumpWidget(
        MaterialApp(
          home: CreateEditVendorScreen(
            repository: repository,
            onSaved: (v) => savedRecord = v,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('vendor_form_name')), 'Delta Solutions');
      await tester.enterText(find.byKey(const Key('vendor_form_phone')), '+91 98777 66554');
      await tester.enterText(find.byKey(const Key('vendor_form_email')), 'contact@delta.com');
      await tester.enterText(find.byKey(const Key('vendor_form_gstin')), '07AAAAA0000A1Z5');

      final submitFinder = find.byKey(const Key('vendor_form_submit_button'));
      await tester.ensureVisible(submitFinder);
      await tester.pumpAndSettle();

      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(savedRecord, isNotNull);
      expect(savedRecord!.companyName, 'Delta Solutions');
      expect(savedRecord!.gstin, '07AAAAA0000A1Z5');
    });
  });
}
