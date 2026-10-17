import 'package:enterprise_crm/features/approvals/domain/entities/approval_action_type.dart';
import 'package:enterprise_crm/features/approvals/presentation/widgets/approval_action_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildDialog({
    required ApprovalActionType actionType,
    required Future<void> Function(String? comment) onConfirm,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ApprovalActionDialog(
                      actionType: actionType,
                      requestNumber: 'REQ-2026-0001',
                      onConfirm: onConfirm,
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            );
          },
        ),
      ),
    );
  }

  testWidgets('Reject dialog strictly enforces non-empty comment', (tester) async {
    bool confirmed = false;
    await tester.pumpWidget(
      buildDialog(
        actionType: ApprovalActionType.rejected,
        onConfirm: (c) async {
          confirmed = true;
        },
      ),
    );

    // Open dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Reject Request'), findsOneWidget);

    // Attempt to submit with empty field
    await tester.tap(find.byKey(const Key('approval_dialog_confirm_btn')));
    await tester.pumpAndSettle();

    expect(find.text('Rejection reason is required.'), findsOneWidget);
    expect(confirmed, isFalse);

    // Enter valid reason
    await tester.enterText(
      find.byKey(const Key('approval_dialog_comment_input')),
      'Budget exceeds Q1 allocation threshold.',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('approval_dialog_confirm_btn')));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
  });

  testWidgets('Revision request dialog strictly enforces non-empty notes',
      (tester) async {
    bool confirmed = false;
    await tester.pumpWidget(
      buildDialog(
        actionType: ApprovalActionType.revisionRequested,
        onConfirm: (c) async {
          confirmed = true;
        },
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Request Revisions'), findsOneWidget);

    // Attempt to submit empty
    await tester.tap(find.byKey(const Key('approval_dialog_confirm_btn')));
    await tester.pumpAndSettle();

    expect(find.text('Revision notes are required.'), findsOneWidget);
    expect(confirmed, isFalse);
  });

  testWidgets('Approve dialog allows submitting with optional empty comment',
      (tester) async {
    String? capturedComment;
    await tester.pumpWidget(
      buildDialog(
        actionType: ApprovalActionType.approved,
        onConfirm: (c) async {
          capturedComment = c;
        },
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Approve Request'), findsOneWidget);

    // Confirm without entering comment
    await tester.tap(find.byKey(const Key('approval_dialog_confirm_btn')));
    await tester.pumpAndSettle();

    expect(capturedComment, isNull);
  });

  testWidgets('Cancel button dismisses dialog without calling onConfirm',
      (tester) async {
    bool confirmed = false;
    await tester.pumpWidget(
      buildDialog(
        actionType: ApprovalActionType.rejected,
        onConfirm: (c) async {
          confirmed = true;
        },
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('approval_dialog_cancel_btn')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('approval_action_dialog')), findsNothing);
    expect(confirmed, isFalse);
  });
}
