import 'package:enterprise_crm/features/approvals/domain/entities/approval_step.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_step_status.dart';
import 'package:enterprise_crm/features/approvals/presentation/widgets/approval_step_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sampleSteps = [
    ApprovalStep(
      id: 'step-1',
      stepOrder: 1,
      title: 'Department Manager Review',
      assignedUserName: 'Sarah Connor',
      assignedRole: 'Department Head',
      status: ApprovalStepStatus.approved,
      decidedAt: DateTime(2026, 3, 11, 10, 0),
      comments: 'All budget allocations verified.',
    ),
    ApprovalStep(
      id: 'step-2',
      stepOrder: 2,
      title: 'Finance Director Sign-off',
      assignedUserName: 'Michael Scott',
      assignedRole: 'Finance Director',
      status: ApprovalStepStatus.pending,
    ),
  ];

  Widget buildWidget(List<ApprovalStep> steps, {int currentStepIndex = 1}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ApprovalStepStepper(
            steps: steps,
            currentStepIndex: currentStepIndex,
          ),
        ),
      ),
    );
  }

  testWidgets('ApprovalStepStepper renders steps, roles, statuses and comments',
      (tester) async {
    await tester.pumpWidget(buildWidget(sampleSteps));

    expect(find.text('Step 1: Department Manager Review'), findsOneWidget);
    expect(find.text('Sarah Connor (Department Head)'), findsOneWidget);
    expect(find.text('APPROVED'), findsOneWidget);
    expect(find.text('"All budget allocations verified."'), findsOneWidget);

    expect(find.text('Step 2: Finance Director Sign-off'), findsOneWidget);
    expect(find.text('Michael Scott (Finance Director)'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);
  });

  testWidgets('ApprovalStepStepper renders message when steps list is empty',
      (tester) async {
    await tester.pumpWidget(buildWidget([]));

    expect(
      find.text('Single-stage approval workflow (no multi-tier steps).'),
      findsOneWidget,
    );
  });
}
