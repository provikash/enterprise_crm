import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/payroll/configuration/data/mock_payroll_configuration_repository.dart';
import 'package:enterprise_crm/features/payroll/configuration/presentation/bloc/payroll_configuration_cubit.dart';
import 'package:enterprise_crm/features/payroll/configuration/presentation/screens/payroll_configuration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const admin = CurrentUser(
    id: 'admin',
    displayName: 'Payroll Admin',
    accountType: AccountType.admin,
  );

  Widget app(MockPayrollConfigurationRepository repository) => MaterialApp(
    home: BlocProvider(
      create: (_) => PayrollConfigurationCubit(repository)..load(),
      child: const PayrollConfigurationScreen(user: admin),
    ),
  );

  testWidgets('loads mock components and all configuration tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(MockPayrollConfigurationRepository(latency: Duration.zero)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Basic Salary'), findsOneWidget);
    expect(find.text('Structures'), findsOneWidget);
    expect(find.text('Statutory versions'), findsOneWidget);
    expect(find.text('Pay groups'), findsOneWidget);
  });

  testWidgets('creates a salary component in the mock repository', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(MockPayrollConfigurationRepository(latency: Duration.zero)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('New component'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Component code'),
      'BONUS',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Performance Bonus',
    );
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    final componentList = find.descendant(
      of: find.byKey(const Key('payroll_configuration_screen')),
      matching: find.byType(ListView),
    );
    await tester.drag(componentList, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Performance Bonus'), findsOneWidget);
    expect(find.text('Salary component created.'), findsOneWidget);
  });
}
