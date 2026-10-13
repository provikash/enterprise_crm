import 'package:enterprise_crm/features/payroll/shared/domain/money.dart';
import 'package:enterprise_crm/features/payroll/shared/domain/payroll_status.dart';
import 'package:enterprise_crm/features/payroll/shared/presentation/widgets/masked_field.dart';
import 'package:enterprise_crm/features/payroll/shared/presentation/widgets/money_text.dart';
import 'package:enterprise_crm/features/payroll/shared/presentation/widgets/payroll_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MoneyText formats values and styles negatives as errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MoneyText(value: Money(-12345))),
    );
    expect(find.text('-₹123.45'), findsOneWidget);
    final text = tester.widget<Text>(find.text('-₹123.45'));
    expect(text.style?.color, isNotNull);
  });

  testWidgets('MaskedField starts masked and reveals temporarily', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MaskedField(
            label: 'PAN',
            value: 'ABCDE1234F',
            canReveal: true,
            revealDuration: Duration(milliseconds: 10),
          ),
        ),
      ),
    );
    expect(find.text('••••••••'), findsOneWidget);
    await tester.tap(find.byTooltip('Reveal PAN'));
    await tester.pump();
    expect(find.text('ABCDE1234F'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 11));
    expect(find.text('••••••••'), findsOneWidget);
  });

  testWidgets('status chip includes text and icon, not color alone', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PayrollStatusChip(status: PayrollStatus.approved)),
      ),
    );
    expect(find.text('Approved'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });
}
