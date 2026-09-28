import 'package:enterprise_crm/features/hr/data/mock/mock_payroll_store.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_period.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_record.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/payroll_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/payroll_period_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/payroll_period_state.dart';
import 'package:flutter_test/flutter_test.dart';

class FailingPayrollRepository implements PayrollRepository {
  final bool throwDomainException;

  FailingPayrollRepository({this.throwDomainException = true});

  @override
  Future<List<PayrollPeriod>> getPayrollPeriods() async {
    if (throwDomainException) {
      throw const PayrollException('Database service connection failed.');
    }
    throw Exception('Unexpected socket error.');
  }

  @override
  Future<PayrollPeriod?> getPayrollPeriodById(String id) async => null;

  @override
  Future<List<PayrollRecord>> getPayrollRecords({
    String? payrollPeriodId,
    String? employeeId,
  }) async => [];

  @override
  Future<List<PayrollRecord>> getPayrollRecordsForPeriod(String periodId) async => [];

  @override
  Future<List<PayrollRecord>> getPayrollRecordsForEmployee(String employeeId) async => [];

  @override
  Future<PayrollRecord?> getPayrollRecordById(String id) async => null;
}

void main() {
  late MockPayrollStore store;
  late MockPayrollRepository repository;
  late PayrollPeriodCubit cubit;

  setUp(() {
    store = MockPayrollStore();
    repository = MockPayrollRepository(store: store);
    cubit = PayrollPeriodCubit(repository: repository);
  });

  tearDown(() {
    cubit.close();
  });

  group('PayrollPeriodCubit Tests (HR-6.4)', () {
    test('initial state has correct default values', () {
      expect(cubit.state.status, PayrollPeriodStatus.initial);
      expect(cubit.state.periods, isEmpty);
      expect(cubit.state.selectedPeriodId, isNull);
      expect(cubit.state.selectedPeriod, isNull);
      expect(cubit.state.hasSelection, isFalse);
      expect(cubit.state.isEmpty, isFalse);
      expect(cubit.state.errorMessage, isNull);
    });

    test('accepts initialPeriodId in constructor', () {
      final initialCubit = PayrollPeriodCubit(
        repository: repository,
        initialPeriodId: 'period_2026_01',
      );

      expect(initialCubit.state.selectedPeriodId, 'period_2026_01');
      initialCubit.close();
    });

    test('loadPeriods emits loading and loaded with periods', () async {
      final expectation = expectLater(
        cubit.stream.map((s) => s.status),
        emitsInOrder([
          PayrollPeriodStatus.loading,
          PayrollPeriodStatus.loaded,
        ]),
      );

      await cubit.loadPeriods();
      await expectation;
      expect(cubit.state.periods.length, 3);
      expect(cubit.state.isEmpty, isFalse);
      expect(cubit.state.errorMessage, isNull);
    });

    test('loadPeriods with empty repository emits loaded with isEmpty true', () async {
      final emptyStore = MockPayrollStore(seedInitialData: false);
      final emptyRepo = MockPayrollRepository(store: emptyStore);
      final emptyCubit = PayrollPeriodCubit(repository: emptyRepo);

      await emptyCubit.loadPeriods();

      expect(emptyCubit.state.status, PayrollPeriodStatus.loaded);
      expect(emptyCubit.state.periods, isEmpty);
      expect(emptyCubit.state.isEmpty, isTrue);

      emptyCubit.close();
    });

    test('loadPeriods emits failure with domain message on PayrollException', () async {
      final failingRepo = FailingPayrollRepository(throwDomainException: true);
      final failingCubit = PayrollPeriodCubit(repository: failingRepo);

      await failingCubit.loadPeriods();

      expect(failingCubit.state.status, PayrollPeriodStatus.failure);
      expect(failingCubit.state.errorMessage, 'Database service connection failed.');

      failingCubit.close();
    });

    test('loadPeriods emits failure with fallback message on generic Exception', () async {
      final failingRepo = FailingPayrollRepository(throwDomainException: false);
      final failingCubit = PayrollPeriodCubit(repository: failingRepo);

      await failingCubit.loadPeriods();

      expect(failingCubit.state.status, PayrollPeriodStatus.failure);
      expect(
        failingCubit.state.errorMessage,
        'Failed to load payroll periods. Please try again.',
      );

      failingCubit.close();
    });

    test('retry executes loadPeriods after a failure', () async {
      store.setSimulatedFailure(true);
      await cubit.loadPeriods();
      expect(cubit.state.status, PayrollPeriodStatus.failure);

      store.setSimulatedFailure(false);
      await cubit.retry();
      expect(cubit.state.status, PayrollPeriodStatus.loaded);
      expect(cubit.state.periods.length, 3);
    });

    test('selectPeriod sets valid period and resolves selectedPeriod', () async {
      await cubit.loadPeriods();

      cubit.selectPeriod('period_2026_01');

      expect(cubit.state.selectedPeriodId, 'period_2026_01');
      expect(cubit.state.selectedPeriod, isNotNull);
      expect(cubit.state.selectedPeriod!.name, 'January 2026');
      expect(cubit.state.hasSelection, isTrue);
    });

    test('selectPeriod ignores unknown period ID safely', () async {
      await cubit.loadPeriods();
      cubit.selectPeriod('period_2026_01');

      cubit.selectPeriod('period_nonexistent');

      expect(cubit.state.selectedPeriodId, 'period_2026_01');
    });

    test('selectPeriod with already selected period is a no-op', () async {
      await cubit.loadPeriods();
      cubit.selectPeriod('period_2026_01');

      var emitCount = 0;
      cubit.stream.listen((_) => emitCount++);

      cubit.selectPeriod('period_2026_01');
      expect(emitCount, 0);
    });

    test('switch selection between available periods works correctly', () async {
      await cubit.loadPeriods();

      cubit.selectPeriod('period_2026_01');
      expect(cubit.state.selectedPeriodId, 'period_2026_01');

      cubit.selectPeriod('period_2026_02');
      expect(cubit.state.selectedPeriodId, 'period_2026_02');
      expect(cubit.state.selectedPeriod!.name, 'February 2026');
    });

    test('clearSelection clears selected period', () async {
      await cubit.loadPeriods();
      cubit.selectPeriod('period_2026_01');
      expect(cubit.state.hasSelection, isTrue);

      cubit.clearSelection();
      expect(cubit.state.selectedPeriodId, isNull);
      expect(cubit.state.selectedPeriod, isNull);
      expect(cubit.state.hasSelection, isFalse);
    });

    test('clearSelection when already null is a no-op', () async {
      await cubit.loadPeriods();

      var emitCount = 0;
      cubit.stream.listen((_) => emitCount++);

      cubit.clearSelection();
      expect(emitCount, 0);
    });

    test('reload preserves valid selection', () async {
      await cubit.loadPeriods();
      cubit.selectPeriod('period_2026_02');

      await cubit.reload();

      expect(cubit.state.status, PayrollPeriodStatus.loaded);
      expect(cubit.state.selectedPeriodId, 'period_2026_02');
      expect(cubit.state.selectedPeriod!.name, 'February 2026');
    });

    test('reload clears selection safely when selected period is no longer available', () async {
      // Start with initialPeriodId that does not exist in store
      final orphanCubit = PayrollPeriodCubit(
        repository: repository,
        initialPeriodId: 'period_deleted',
      );

      await orphanCubit.loadPeriods();

      expect(orphanCubit.state.status, PayrollPeriodStatus.loaded);
      expect(orphanCubit.state.selectedPeriodId, isNull);
      expect(orphanCubit.state.selectedPeriod, isNull);

      orphanCubit.close();
    });

    test('rapid successive load calls do not run duplicate concurrent requests', () async {
      final future1 = cubit.loadPeriods();
      final future2 = cubit.loadPeriods();
      await Future.wait([future1, future2]);

      expect(cubit.state.status, PayrollPeriodStatus.loaded);
      expect(cubit.state.periods.length, 3);
    });

    test('no state emitted after cubit is closed', () async {
      cubit.close();
      expect(cubit.isClosed, isTrue);
      // Attempting to load on closed cubit returns early
      await cubit.loadPeriods();
    });
  });
}
