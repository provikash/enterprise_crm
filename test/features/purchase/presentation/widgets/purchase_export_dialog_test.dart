import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enterprise_crm/features/purchase/data/repositories/mock_purchase_repository.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_filter_query.dart';
import 'package:enterprise_crm/features/purchase/presentation/services/purchase_file_saver.dart';
import 'package:enterprise_crm/features/purchase/presentation/widgets/purchase_export_dialog.dart';

import '../../../../helpers/mock_auth_test_fixtures.dart';

class MockTestPurchaseFileSaver implements PurchaseFileSaver {
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
    return Uri.parse('file:///mock/downloads/$fileName');
  }
}

void main() {
  late MockPurchaseRepository repository;
  late MockTestPurchaseFileSaver fileSaver;

  final authorizedUser = MockAuthTestFixtures.admin;
  final unauthorizedUser = MockAuthTestFixtures.standardUser;

  setUp(() {
    repository = MockPurchaseRepository();
    fileSaver = MockTestPurchaseFileSaver();
  });

  testWidgets('renders format options, cancel dismisses dialog', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PurchaseExportDialog(
            repository: repository,
            user: authorizedUser,
            fileSaver: fileSaver,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('purchase_export_dialog')), findsOneWidget);
    expect(find.byKey(const Key('purchase_export_format_pdf')), findsOneWidget);
    expect(find.byKey(const Key('purchase_export_format_csv')), findsOneWidget);
    expect(find.byKey(const Key('purchase_export_scope_all')), findsOneWidget);
    expect(find.byKey(const Key('purchase_export_scope_filtered')), findsOneWidget);

    await tester.tap(find.byKey(const Key('purchase_export_cancel_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('purchase_export_dialog')), findsNothing);
    expect(fileSaver.lastBytes, isNull);
  });

  testWidgets('downloads PDF export by default on confirmation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PurchaseExportDialog(
            repository: repository,
            user: authorizedUser,
            fileSaver: fileSaver,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('purchase_confirm_export_button')));
    await tester.pumpAndSettle();

    expect(fileSaver.lastExtension, equals('pdf'));
    expect(fileSaver.lastMimeType, equals('application/pdf'));
    expect(fileSaver.lastBytes, isNotNull);
    expect(fileSaver.lastBytes!.isNotEmpty, isTrue);
  });

  testWidgets('downloads CSV export when CSV format selected', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PurchaseExportDialog(
            repository: repository,
            user: authorizedUser,
            fileSaver: fileSaver,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('purchase_export_format_csv')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('purchase_confirm_export_button')));
    await tester.pumpAndSettle();

    expect(fileSaver.lastExtension, equals('csv'));
    expect(fileSaver.lastMimeType, equals('text/csv'));
    expect(fileSaver.lastBytes, isNotNull);
    expect(fileSaver.lastBytes!.isNotEmpty, isTrue);
  });

  testWidgets('unauthorized user gets permission error message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PurchaseExportDialog(
            repository: repository,
            user: unauthorizedUser,
            fileSaver: fileSaver,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('purchase_confirm_export_button')));
    await tester.pumpAndSettle();

    expect(
      find.text('You do not have permission to export purchase orders.'),
      findsOneWidget,
    );
    expect(fileSaver.lastBytes, isNull);
  });

  testWidgets('showPurchaseExportDialog modal helper opens and runs export', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showPurchaseExportDialog(
                context: ctx,
                repository: repository,
                user: authorizedUser,
                fileSaver: fileSaver,
                currentQuery: const PurchaseFilterQuery(searchText: 'Apex'),
              ),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('purchase_export_dialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('purchase_confirm_export_button')));
    await tester.pumpAndSettle();

    expect(fileSaver.lastBytes, isNotNull);
    expect(find.byKey(const Key('purchase_export_dialog')), findsNothing);
  });
}
