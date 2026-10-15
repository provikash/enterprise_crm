import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_document_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_documents_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/hr_documents_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const admin = CurrentUser(
    id: 'admin',
    displayName: 'Administrator',
    accountType: AccountType.admin,
  );

  Widget app() => MaterialApp(
    home: HrDocumentsDashboardScreen(
      user: admin,
      employeeRepository: MockEmployeeRepository(),
      documentRepository: MockEmployeeDocumentRepository(),
    ),
  );

  testWidgets('shows enterprise document summary and employee compliance', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Workforce document control'), findsOneWidget);
    expect(find.text('Employees'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Expiring in 60 days'), findsOneWidget);
    expect(find.text('Missing documents'), findsOneWidget);
    expect(find.byKey(const Key('hr_documents_search')), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
  });

  testWidgets('opens the selected employee document workspace', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alice Johnson'));
    await tester.pumpAndSettle();
    expect(find.byType(EmployeeDocumentsScreen), findsOneWidget);
    expect(find.textContaining('Alice Johnson'), findsWidgets);
  });
}
