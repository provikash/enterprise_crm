import 'package:enterprise_crm/features/hr/data/mock/mock_payroll_store.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_record.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/payroll_overview_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/payroll_overview_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayrollOverviewCubit Tests (HR-6.5)', () {
    late MockPayrollStore store;
    late MockPayrollRepository repository;
    late MockEmployeeRepository employeeRepository;

    setUp(() {
      store = MockPayrollStore(seedInitialData: true);
      repository = MockPayrollRepository(store: store);
      employeeRepository = MockEmployeeRepository();
    });

    test('initial state has correct default values', () {
      final cubit = PayrollOverviewCubit(repository: repository);
      expect(cubit.state.status, PayrollOverviewStatus.initial);
      expect(cubit.state.records, isEmpty);
      expect(cubit.state.selectedPeriodId, isNull);
      expect(cubit.state.searchQuery, isEmpty);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.isEmpty, isFalse);
      expect(cubit.state.isSearchEmpty, isFalse);
      cubit.close();
    });

    test('loads initial period records if initialPeriodId is provided', () async {
      final cubit = PayrollOverviewCubit(
        repository: repository,
        employeeRepository: employeeRepository,
        initialPeriodId: 'period_2026_01',
      );

      // Wait for initial load
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(cubit.state.status, PayrollOverviewStatus.loaded);
      expect(cubit.state.selectedPeriodId, 'period_2026_01');
      expect(cubit.state.records.length, 3);
      expect(cubit.state.employeeNames.isNotEmpty, isTrue);
      await cubit.close();
    });

    test('loadRecordsForPeriod emits loading then loaded with records', () async {
      final cubit = PayrollOverviewCubit(
        repository: repository,
        employeeRepository: employeeRepository,
      );

      final expectation = expectLater(
        cubit.stream.map((s) => s.status),
        emitsInOrder([
          PayrollOverviewStatus.loading,
          PayrollOverviewStatus.loaded,
        ]),
      );

      await cubit.loadRecordsForPeriod('period_2026_01');
      await expectation;

      expect(cubit.state.records.length, 3);
      expect(cubit.state.isEmpty, isFalse);
      expect(cubit.state.recordCount, 3);

      await cubit.close();
    });

    test('loadRecordsForPeriod for empty period emits loaded with isEmpty true', () async {
      final cubit = PayrollOverviewCubit(
        repository: repository,
        employeeRepository: employeeRepository,
      );

      await cubit.loadRecordsForPeriod('period_2026_03');

      expect(cubit.state.status, PayrollOverviewStatus.loaded);
      expect(cubit.state.records, isEmpty);
      expect(cubit.state.isEmpty, isTrue);
      expect(cubit.state.recordCount, 0);

      await cubit.close();
    });

    test('loadRecordsForPeriod ignores empty or whitespace period IDs', () async {
      final cubit = PayrollOverviewCubit(repository: repository);

      await cubit.loadRecordsForPeriod('   ');

      expect(cubit.state.status, PayrollOverviewStatus.initial);
      await cubit.close();
    });

    test('repository failure emits failure with safe user-facing message', () async {
      store.setSimulatedFailure(true);
      final cubit = PayrollOverviewCubit(
        repository: repository,
        employeeRepository: employeeRepository,
      );

      await cubit.loadRecordsForPeriod('period_2026_01');

      expect(cubit.state.status, PayrollOverviewStatus.failure);
      expect(
        cubit.state.errorMessage,
        'Failed to load payroll records for this period.',
      );
      // Ensure raw exception class or internal traces are NOT leaked
      expect(cubit.state.errorMessage?.contains('Exception'), isFalse);
      expect(cubit.state.errorMessage?.contains('Stack'), isFalse);

      await cubit.close();
    });

    test('retry reloads the current selected period', () async {
      store.setSimulatedFailure(true);
      final cubit = PayrollOverviewCubit(
        repository: repository,
        employeeRepository: employeeRepository,
      );

      await cubit.loadRecordsForPeriod('period_2026_01');
      expect(cubit.state.status, PayrollOverviewStatus.failure);

      // Resolve failure
      store.setSimulatedFailure(false);
      await cubit.retry();

      expect(cubit.state.status, PayrollOverviewStatus.loaded);
      expect(cubit.state.records.length, 3);

      await cubit.close();
    });

    test('concurrency guard prevents stale responses on rapid period switching', () async {
      final cubit = PayrollOverviewCubit(
        repository: repository,
        employeeRepository: employeeRepository,
      );

      // Trigger two quick consecutive loads
      final future1 = cubit.loadRecordsForPeriod('period_2026_01');
      final future2 = cubit.loadRecordsForPeriod('period_2026_02');

      await Future.wait([future1, future2]);

      // Latest requested period was period_2026_02
      expect(cubit.state.selectedPeriodId, 'period_2026_02');
      expect(cubit.state.records.length, 2);
      expect(
        cubit.state.records.every((r) => r.payrollPeriodId == 'period_2026_02'),
        isTrue,
      );

      await cubit.close();
    });

    test('search query filters records by employee name, employee ID, and record ID', () async {
      final cubit = PayrollOverviewCubit(
        repository: repository,
        employeeRepository: employeeRepository,
      );

      await cubit.loadRecordsForPeriod('period_2026_01');
      expect(cubit.state.records.length, 3);

      // Search by employee ID
      cubit.setSearchQuery('emp_1');
      expect(cubit.state.filteredRecords.length, 1);
      expect(cubit.state.filteredRecords.first.employeeId, 'emp_1');
      expect(cubit.state.filteredCount, 1);
      expect(cubit.state.recordCount, 3);

      // Search by record ID
      cubit.setSearchQuery('pay_rec_102');
      expect(cubit.state.filteredRecords.length, 1);
      expect(cubit.state.filteredRecords.first.id, 'pay_rec_102');

      // Search by non-existent query
      cubit.setSearchQuery('non_existent_xyz');
      expect(cubit.state.filteredRecords, isEmpty);
      expect(cubit.state.isSearchEmpty, isTrue);

      // Clear search restores all records
      cubit.clearSearch();
      expect(cubit.state.filteredRecords.length, 3);
      expect(cubit.state.isSearchEmpty, isFalse);

      await cubit.close();
    });

    test('updateEmployeeNameMap allows custom employee name mappings', () async {
      final cubit = PayrollOverviewCubit(
        repository: repository,
      );

      await cubit.loadRecordsForPeriod('period_2026_01');
      cubit.updateEmployeeNameMap({'emp_1': 'Alice Wonderland'});

      cubit.setSearchQuery('wonderland');
      expect(cubit.state.filteredRecords.length, 1);
      expect(cubit.state.filteredRecords.first.employeeId, 'emp_1');

      await cubit.close();
    });

    test('PayrollOverviewState copyWith preserves or clears fields correctly', () {
      const state = PayrollOverviewState(
        status: PayrollOverviewStatus.loaded,
        selectedPeriodId: 'period_1',
        records: [],
        searchQuery: 'test',
        errorMessage: 'error',
      );

      final cleared = state.copyWith(
        clearSelectedPeriodId: true,
        clearErrorMessage: true,
      );

      expect(cleared.selectedPeriodId, isNull);
      expect(cleared.errorMessage, isNull);
      expect(cleared.searchQuery, 'test');
    });

    test('PayrollOverviewState equality and hashCode work correctly', () {
      final r1 = PayrollRecord(
        id: 'rec_1',
        employeeId: 'emp_1',
        payrollPeriodId: 'p_1',
      );
      final state1 = PayrollOverviewState(
        status: PayrollOverviewStatus.loaded,
        selectedPeriodId: 'p_1',
        records: [r1],
        searchQuery: 'a',
      );
      final state2 = PayrollOverviewState(
        status: PayrollOverviewStatus.loaded,
        selectedPeriodId: 'p_1',
        records: [r1],
        searchQuery: 'a',
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });
  });
}
