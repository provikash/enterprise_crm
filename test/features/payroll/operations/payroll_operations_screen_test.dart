import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/payroll/operations/data/mock_payroll_operations_repository.dart';
import 'package:enterprise_crm/features/payroll/operations/presentation/bloc/payroll_operations_cubit.dart';
import 'package:enterprise_crm/features/payroll/operations/presentation/screens/payroll_operations_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const admin = CurrentUser(
    id: 'admin-checker',
    displayName: 'Payroll Administrator',
    accountType: AccountType.admin,
  );

  Widget app(PayrollWorkspace workspace) => MaterialApp(
    home: BlocProvider(
      create: (_) => PayrollOperationsCubit(
        MockPayrollOperationsRepository(latency: Duration.zero),
      )..load(),
      child: PayrollOperationsScreen(user: admin, workspace: workspace),
    ),
  );

  testWidgets('shows employee compensation and opens edit form', (
    tester,
  ) async {
    await tester.pumpWidget(app(PayrollWorkspace.compensation));
    await tester.pumpAndSettle();

    expect(find.textContaining('Aarav Fernando'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit compensation').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Edit Aarav Fernando'), findsOneWidget);
    expect(find.text('Basic salary'), findsOneWidget);
  });

  testWidgets('approves seeded run and exposes lock action', (tester) async {
    await tester.pumpWidget(app(PayrollWorkspace.runs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('September 2026'));
    await tester.pumpAndSettle();
    expect(find.text('Approve'), findsOneWidget);
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    expect(find.text('Pay run approved.'), findsOneWidget);
    expect(find.text('Lock payroll'), findsOneWidget);
  });

  testWidgets('reports clearly labels mock tax limitation', (tester) async {
    await tester.pumpWidget(app(PayrollWorkspace.reports));
    await tester.pumpAndSettle();
    expect(find.text('Payroll register'), findsOneWidget);
    expect(find.textContaining('illustrative'), findsOneWidget);
  });

  testWidgets('keeps full payroll navigation visible on operation pages', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(PayrollWorkspace.runs));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('payroll_nav_overview')), findsOneWidget);
    expect(find.byKey(const Key('payroll_nav_configuration')), findsOneWidget);
    expect(find.byKey(const Key('payroll_nav_compensation')), findsOneWidget);
    expect(find.byKey(const Key('payroll_nav_inputs')), findsOneWidget);
    expect(find.byKey(const Key('payroll_nav_runs')), findsOneWidget);
    expect(find.byKey(const Key('payroll_nav_payslips')), findsOneWidget);
    expect(find.byKey(const Key('payroll_nav_payments')), findsOneWidget);
    expect(find.byKey(const Key('payroll_nav_reports')), findsOneWidget);
  });
}
