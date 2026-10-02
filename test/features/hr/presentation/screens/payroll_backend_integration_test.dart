import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/hr/data/network/api_client.dart';
import 'package:enterprise_crm/features/hr/data/network/api_transport.dart';
import 'package:enterprise_crm/features/hr/data/network/backend_config.dart';
import 'package:enterprise_crm/features/hr/data/network/mock_api_transport.dart';
import 'package:enterprise_crm/features/hr/data/repositories/backend_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/payroll_overview_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/payroll_overview_state.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/payroll_period_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/payroll_period_state.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_period_selection_screen.dart';

void main() {
  late MockApiTransport transport;
  late BackendConfig config;
  late ApiClient apiClient;
  late BackendPayrollRepository repository;

  final adminUser = const CurrentUser(
    id: 'usr_admin_01',
    displayName: 'Admin User',
    accountType: AccountType.admin,
    modules: {CrmModule.hrPayroll},
    permissions: {'payroll_view', 'hr_view'},
  );

  setUp(() {
    transport = MockApiTransport();
    config = BackendConfig.staging(
      baseUrl: 'https://api.crm.example.com',
      mode: BackendMode.backend,
    );
    apiClient = ApiClient(
      config: config,
      transport: transport,
      authTokenProvider: () => 'payroll_jwt_admin',
    );
    repository = BackendPayrollRepository(apiClient: apiClient);
  });

  group('HR-10.8 Payroll - Cubit & Screen Integration', () {
    test('PayrollPeriodCubit loads periods via BackendPayrollRepository', () async {
      transport.registerJson(
        path: '/api/v1/hr/payroll/periods',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "period_2026_01",
            "name": "January 2026",
            "start_date": "2026-01-01",
            "end_date": "2026-01-31"
          },
          {
            "id": "period_2026_02",
            "name": "February 2026",
            "start_date": "2026-02-01",
            "end_date": "2026-02-28"
          }
        ]
        ''',
      );

      final cubit = PayrollPeriodCubit(repository: repository);
      expect(cubit.state.periods, isEmpty);

      await cubit.loadPeriods();

      expect(cubit.state.status, equals(PayrollPeriodStatus.loaded));
      expect(cubit.state.periods.length, equals(2));
      expect(cubit.state.periods[0].name, equals('January 2026'));
      expect(cubit.state.periods[1].name, equals('February 2026'));
    });

    test('PayrollOverviewCubit loads records for period via BackendPayrollRepository', () async {
      transport.registerJson(
        path: '/api/v1/hr/payroll/records',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "pay_101",
            "employee_id": "emp_1",
            "payroll_period_id": "period_2026_01",
            "gross_salary": 8500.0,
            "net_salary": 7200.0,
            "currency": "INR",
            "payment_status": "Paid"
          }
        ]
        ''',
      );

      final cubit = PayrollOverviewCubit(
        repository: repository,
        initialPeriodId: 'period_2026_01',
      );

      // Wait for async load initiated in constructor
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.status, equals(PayrollOverviewStatus.loaded));
      expect(cubit.state.records.length, equals(1));
      expect(cubit.state.records.first.id, equals('pay_101'));
      expect(cubit.state.records.first.grossSalary, equals(8500.0));
      expect(cubit.state.records.first.currency, equals('INR'));
    });

    testWidgets('PayrollPeriodSelectionScreen renders loaded periods from backend', (tester) async {
      transport.registerJson(
        path: '/api/v1/hr/payroll/periods',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "period_2026_01",
            "name": "January 2026",
            "start_date": "2026-01-01",
            "end_date": "2026-01-31"
          }
        ]
        ''',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PayrollPeriodSelectionScreen(
            user: adminUser,
            payrollRepository: repository,
            initialPeriodId: 'period_2026_01',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Dropdown / selector should render the period name
      expect(find.byKey(const Key('payroll_period_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('payroll_period_selected_label')), findsOneWidget);
    });
  });
}
