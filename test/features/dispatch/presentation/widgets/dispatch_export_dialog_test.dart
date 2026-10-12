import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enterprise_crm/features/dispatch/data/repositories/mock_dispatch_repository.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_filter_query.dart';
import 'package:enterprise_crm/features/dispatch/presentation/services/dispatch_file_saver.dart';
import 'package:enterprise_crm/features/dispatch/presentation/widgets/dispatch_export_dialog.dart';

class MockTestDispatchFileSaver implements DispatchFileSaver {
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
  late MockDispatchRepository repository;
  late MockTestDispatchFileSaver fileSaver;

  setUp(() {
    repository = MockDispatchRepository();
    fileSaver = MockTestDispatchFileSaver();
  });

  testWidgets('renders format options and downloads PDF export', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DispatchExportDialog(
            repository: repository,
            fileSaver: fileSaver,
            currentQuery: const DispatchFilterQuery(),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('dispatch_export_dialog')), findsOneWidget);
    expect(find.byKey(const Key('dispatch_export_format_pdf')), findsOneWidget);
    expect(find.byKey(const Key('dispatch_export_format_xlsx')), findsOneWidget);
    expect(find.byKey(const Key('dispatch_export_format_csv')), findsOneWidget);

    // Tap Download
    await tester.tap(find.byKey(const Key('dispatch_confirm_export_button')));
    await tester.pumpAndSettle();

    expect(fileSaver.lastExtension, equals('pdf'));
    expect(fileSaver.lastMimeType, equals('application/pdf'));
    expect(fileSaver.lastBytes, isNotNull);
    expect(fileSaver.lastBytes!.isNotEmpty, isTrue);
  });

  testWidgets('downloads Excel export when xlsx format selected', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DispatchExportDialog(
            repository: repository,
            fileSaver: fileSaver,
          ),
        ),
      ),
    );

    // Select XLSX
    await tester.tap(find.byKey(const Key('dispatch_export_format_xlsx')));
    await tester.pumpAndSettle();

    // Tap Download
    await tester.tap(find.byKey(const Key('dispatch_confirm_export_button')));
    await tester.pumpAndSettle();

    expect(fileSaver.lastExtension, equals('xlsx'));
    expect(fileSaver.lastBytes, isNotNull);
  });

  testWidgets('downloads CSV export when csv format selected', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DispatchExportDialog(
            repository: repository,
            fileSaver: fileSaver,
          ),
        ),
      ),
    );

    // Select CSV
    await tester.tap(find.byKey(const Key('dispatch_export_format_csv')));
    await tester.pumpAndSettle();

    // Tap Download
    await tester.tap(find.byKey(const Key('dispatch_confirm_export_button')));
    await tester.pumpAndSettle();

    expect(fileSaver.lastExtension, equals('csv'));
    expect(fileSaver.lastMimeType, equals('text/csv'));
    expect(fileSaver.lastBytes, isNotNull);
  });

  testWidgets('cancel button pops dialog without triggering fileSaver', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDispatchExportDialog(
                context: context,
                repository: repository,
                fileSaver: fileSaver,
              ),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dispatch_export_dialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('dispatch_export_cancel_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dispatch_export_dialog')), findsNothing);
    expect(fileSaver.lastBytes, isNull);
  });
}
