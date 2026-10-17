import 'package:enterprise_crm/features/approvals/domain/entities/approval_priority.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_request.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_status.dart';
import 'package:enterprise_crm/features/approvals/presentation/widgets/approval_card.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sampleRequest = ApprovalRequest(
    id: 'req-001',
    requestNumber: 'REQ-2026-0001',
    module: CrmModule.purchase,
    entityType: 'purchase_order',
    entityId: 'po-101',
    entityTitle: 'Purchase Order #PO-101 (Acme Corp)',
    requesterId: 'usr-requester',
    requesterName: 'Jane Submitter',
    departmentName: 'Procurement',
    status: ApprovalStatus.pending,
    priority: ApprovalPriority.high,
    amount: 15400.0,
    currencyCode: 'USD',
    submittedAt: DateTime(2026, 3, 10, 14, 30),
  );

  Widget buildWidget(ApprovalRequest req, {VoidCallback? onTap}) {
    return MaterialApp(
      home: Scaffold(
        body: ApprovalCard(
          request: req,
          onTap: onTap,
        ),
      ),
    );
  }

  testWidgets('ApprovalCard renders request details, priority, status and amount',
      (tester) async {
    await tester.pumpWidget(buildWidget(sampleRequest));

    expect(find.text('REQ-2026-0001'), findsOneWidget);
    expect(find.text('Purchase Order #PO-101 (Acme Corp)'), findsOneWidget);
    expect(find.text('Jane Submitter'), findsOneWidget);
    expect(find.text('Procurement'), findsOneWidget);
    expect(find.text('HIGH'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('USD 15400.00'), findsOneWidget);
    expect(find.text('2026-03-10'), findsOneWidget);
  });

  testWidgets('ApprovalCard triggers onTap when tapped', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(buildWidget(sampleRequest, onTap: () => tapped = true));

    await tester.tap(find.byType(ApprovalCard));
    expect(tapped, isTrue);
  });

  testWidgets('ApprovalCard does not overflow on compact mobile viewport (320px width)',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildWidget(sampleRequest));
    final exception = tester.takeException();
    if (exception != null) {
      if (exception is FlutterError) {
        for (final d in exception.diagnostics) {
          debugPrint('DIAG: ${d.toStringDeep()}');
        }
      }
    }
    expect(exception, isNull);
  });
}
