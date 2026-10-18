import 'dart:typed_data';

import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/dispatch/data/repositories/mock_dispatch_repository.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_status.dart';
import 'package:enterprise_crm/features/dispatch/presentation/screens/dispatch_details_screen.dart';
import 'package:enterprise_crm/features/dispatch/presentation/services/dispatch_file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_auth_test_fixtures.dart';

void main() {
  group('DispatchDetailsScreen Widget Tests', () {
    late MockDispatchRepository repository;

    setUp(() {
      repository = MockDispatchRepository();
    });

    testWidgets('unauthorized user gets AccessRestrictedScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DispatchDetailsScreen(
            dispatchId: 'dsp_001',
            user: MockAuthTestFixtures.standardUser,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsOneWidget);
      expect(find.text('Dispatch Details'), findsNothing);
    });

    testWidgets('authorized user sees all details cards, stepper, and items table', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: DispatchDetailsScreen(
            dispatchId: 'dsp_001',
            user: MockAuthTestFixtures.admin,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // App bar
      expect(find.text('Dispatch Details'), findsOneWidget);
      expect(find.byKey(const Key('open_update_status_dialog_button')), findsOneWidget);

      // Stepper
      expect(find.byKey(const Key('dispatch_lifecycle_stepper_horizontal')), findsOneWidget);

      // Details keys
      expect(find.byKey(const Key('details_dispatch_code')), findsOneWidget);
      expect(find.text('DSP-2026-001'), findsOneWidget);
      expect(find.byKey(const Key('details_customer_name')), findsOneWidget);
      expect(find.text('Acme Electronics Ltd'), findsOneWidget);
      expect(find.byKey(const Key('details_invoice_number')), findsOneWidget);
      expect(find.text('INV-2026-1001'), findsOneWidget);
      expect(find.byKey(const Key('details_builty_number')), findsOneWidget);
      expect(find.text('BL-VRL-44910'), findsOneWidget);

      // Line items table
      expect(find.byKey(const Key('details_items_table')), findsOneWidget);
      expect(find.text('27-inch 4K UHD Monitors'), findsOneWidget);

      // Proofs & Documents
      expect(find.text('Document Proofs & Receipts'), findsOneWidget);
      expect(find.text('builty_BL-VRL-44910.pdf'), findsOneWidget);
    });

    testWidgets('updating status via dialog transitions shipment status', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: DispatchDetailsScreen(
            dispatchId: 'dsp_001',
            user: MockAuthTestFixtures.admin,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Update Status button
      await tester.tap(find.byKey(const Key('open_update_status_dialog_button')));
      await tester.pumpAndSettle();

      // Dialog is open
      expect(find.text('Update Dispatch Status'), findsOneWidget);

      // Enter remarks
      await tester.enterText(
        find.byKey(const Key('dispatch_status_remarks_input')),
        'Reached local hub, out for delivery',
      );

      // Confirm update
      await tester.tap(find.byKey(const Key('confirm_status_update_button')));
      await tester.pumpAndSettle();

      // Dialog dismissed, updated in UI
      expect(find.text('Update Dispatch Status'), findsNothing);
      expect(find.text(DispatchStatus.outForDelivery.displayName), findsWidgets);
    });

    testWidgets('delivered shipment hides Update Status action', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // dsp_006 is delivered in seed data
      await tester.pumpWidget(
        MaterialApp(
          home: DispatchDetailsScreen(
            dispatchId: 'dsp_006',
            user: MockAuthTestFixtures.admin,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DSP-2026-006'), findsOneWidget);
      expect(find.byKey(const Key('open_update_status_dialog_button')), findsNothing);
    });

    testWidgets('tapping download bill button triggers bill PDF saving', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fileSaver = _TestDispatchFileSaver();

      await tester.pumpWidget(
        MaterialApp(
          home: DispatchDetailsScreen(
            dispatchId: 'dsp_001',
            user: MockAuthTestFixtures.admin,
            repository: repository,
            fileSaver: fileSaver,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final downloadButton = find.byKey(const Key('download_dispatch_bill_button'));
      expect(downloadButton, findsOneWidget);

      await tester.tap(downloadButton);
      await tester.pumpAndSettle();

      expect(fileSaver.lastExtension, equals('pdf'));
      expect(fileSaver.lastMimeType, equals('application/pdf'));
      expect(fileSaver.lastFileName, contains('DSP-2026-001'));
      expect(fileSaver.lastBytes, isNotNull);
    });

    testWidgets('User 1 (view only) cannot see download bill or update status buttons', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final user1 = CurrentUser(
        id: 'usr_1',
        displayName: 'User 1',
        accountType: AccountType.user,
        modules: const {CrmModule.dispatch},
        permissions: const {'dispatch.view'},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DispatchDetailsScreen(
            dispatchId: 'dsp_001',
            user: user1,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dispatch Details'), findsOneWidget);
      expect(find.byKey(const Key('open_update_status_dialog_button')), findsNothing);
      expect(find.byKey(const Key('download_dispatch_bill_button')), findsNothing);
    });

    testWidgets('User 2 (view + bill download) sees download bill button but NOT update status button', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final user2 = CurrentUser(
        id: 'usr_2',
        displayName: 'User 2',
        accountType: AccountType.user,
        modules: const {CrmModule.dispatch},
        permissions: const {'dispatch.view', 'dispatch.bill.download'},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DispatchDetailsScreen(
            dispatchId: 'dsp_001',
            user: user2,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dispatch Details'), findsOneWidget);
      expect(find.byKey(const Key('download_dispatch_bill_button')), findsOneWidget);
      expect(find.byKey(const Key('open_update_status_dialog_button')), findsNothing);
    });

    testWidgets('User 3 (view + edit/update) sees update status button but NOT download bill button', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final user3 = CurrentUser(
        id: 'usr_3',
        displayName: 'User 3',
        accountType: AccountType.user,
        modules: const {CrmModule.dispatch},
        permissions: const {'dispatch.view', 'dispatch.update_status'},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DispatchDetailsScreen(
            dispatchId: 'dsp_001',
            user: user3,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dispatch Details'), findsOneWidget);
      expect(find.byKey(const Key('open_update_status_dialog_button')), findsOneWidget);
      expect(find.byKey(const Key('download_dispatch_bill_button')), findsNothing);
    });
  });
}

class _TestDispatchFileSaver implements DispatchFileSaver {
  String? lastFileName;
  Uint8List? lastBytes;
  String? lastMimeType;
  String? lastExtension;

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    required String extension,
    String? dialogTitle,
  }) async {
    lastFileName = fileName;
    lastBytes = bytes;
    lastMimeType = mimeType;
    lastExtension = extension;
    return Uri.parse('file:///mock/$fileName');
  }
}
