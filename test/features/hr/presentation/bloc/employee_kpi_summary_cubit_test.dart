import 'package:enterprise_crm/features/hr/data/mock/mock_employee_kpi_store.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_kpi_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee_kpi.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/employee_kpi_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/employee_kpi_summary_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/employee_kpi_summary_state.dart';
import 'package:flutter_test/flutter_test.dart';

class FailingKpiSummaryRepo implements EmployeeKpiRepository {
  final bool isDomainException;

  FailingKpiSummaryRepo({this.isDomainException = true});

  @override
  Future<List<EmployeeKpi>> getKpis({
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (isDomainException) {
      throw const EmployeeKpiException('Simulated summary repository error');
    }
    throw Exception('Crash error');
  }

  @override
  Future<List<EmployeeKpi>> getKpisForEmployee(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async => [];

  @override
  Future<EmployeeKpi?> getKpiById(String id) async => null;

  @override
  Future<EmployeeKpi> createKpi({
    required String employeeId,
    required String metricName,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double targetValue,
    required double actualValue,
    double? score,
    String? remarks,
  }) async => throw UnimplementedError();

  @override
  Future<EmployeeKpi> updateKpi({
    required String id,
    required String metricName,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double targetValue,
    required double actualValue,
    double? score,
    bool clearScore = false,
    String? remarks,
    bool clearRemarks = false,
  }) async => throw UnimplementedError();
}

void main() {
  late MockEmployeeKpiStore store;
  late MockEmployeeKpiRepository repository;
  late EmployeeKpiSummaryCubit cubit;

  setUp(() {
    store = MockEmployeeKpiStore();
    repository = MockEmployeeKpiRepository(store: store);
    cubit = EmployeeKpiSummaryCubit(repository: repository);
  });

  tearDown(() {
    cubit.close();
  });

  group('EmployeeKpiSummaryCubit Tests (HR-5.7)', () {
    test('initial state defaults to initial status and empty values', () {
      expect(cubit.state.status, EmployeeKpiSummaryStatus.initial);
      expect(cubit.state.records, isEmpty);
      expect(cubit.state.totalKpis, 0);
      expect(cubit.state.distinctEmployeesCount, 0);
      expect(cubit.state.recordsWithScoreCount, 0);
      expect(cubit.state.recordsWithoutScoreCount, 0);
      expect(cubit.state.errorMessage, isNull);
    });

    test(
      'loadSummary loads all seeded records when no period is specified',
      () async {
        await cubit.loadSummary();

        expect(cubit.state.status, EmployeeKpiSummaryStatus.loaded);
        expect(cubit.state.totalKpis, 5);
        expect(cubit.state.distinctEmployeesCount, 3); // emp_1, emp_2, emp_3
        expect(cubit.state.recordsWithScoreCount, 5);
        expect(cubit.state.recordsWithoutScoreCount, 0);
        expect(cubit.state.activePeriodLabel, 'All Recorded Periods');

        // Metric distribution
        expect(cubit.state.metricCounts['Employee Retention Rate'], 1);
        expect(cubit.state.metricCounts['Time to Hire (Days)'], 1);
        expect(cubit.state.metricCounts['Inventory Accuracy'], 1);
        expect(cubit.state.metricCounts['Order Dispatch Lead Time (Hours)'], 1);
        expect(cubit.state.metricCounts['Quarterly Sales Revenue (\$k)'], 1);
      },
    );

    test(
      'loadSummary computes correct counts with unrecorded scores',
      () async {
        // Add a record with null score
        await repository.createKpi(
          employeeId: 'emp_1',
          metricName: 'Customer Support SLA',
          periodStart: DateTime.utc(2026, 7, 1),
          periodEnd: DateTime.utc(2026, 9, 30),
          targetValue: 95.0,
          actualValue: 90.0,
          score: null, // Pending evaluation
        );

        await cubit.loadSummary();

        expect(cubit.state.totalKpis, 6);
        expect(cubit.state.recordsWithScoreCount, 5);
        expect(cubit.state.recordsWithoutScoreCount, 1);
      },
    );

    test(
      'loadSummary filters by specified period and derives correct label',
      () async {
        await cubit.loadSummary(
          startDate: DateTime.utc(2026, 7, 1),
          endDate: DateTime.utc(2026, 9, 30),
        );

        expect(cubit.state.status, EmployeeKpiSummaryStatus.loaded);
        expect(cubit.state.totalKpis, 5);
        expect(cubit.state.activePeriodLabel, 'Q3 2026 (Jul–Sep)');

        // Outside period
        await cubit.loadSummary(
          startDate: DateTime.utc(2027, 1, 1),
          endDate: DateTime.utc(2027, 3, 31),
        );

        expect(cubit.state.status, EmployeeKpiSummaryStatus.loaded);
        expect(cubit.state.totalKpis, 0);
        expect(cubit.state.isEmpty, isTrue);
      },
    );

    test('setPeriod updates period and triggers summary query', () async {
      cubit.setPeriod(DateTime.utc(2026, 7, 1), DateTime.utc(2026, 9, 30));
      await pumpEventQueue();

      expect(cubit.state.status, EmployeeKpiSummaryStatus.loaded);
      expect(cubit.state.totalKpis, 5);
      expect(cubit.state.periodStart, DateTime.utc(2026, 7, 1));
      expect(cubit.state.periodEnd, DateTime.utc(2026, 9, 30));
    });

    test('reload re-fetches records preserving active period', () async {
      await cubit.loadSummary(
        startDate: DateTime.utc(2026, 7, 1),
        endDate: DateTime.utc(2026, 9, 30),
      );
      expect(cubit.state.totalKpis, 5);

      // Mutate repository
      await repository.createKpi(
        employeeId: 'emp_2',
        metricName: 'Warehouse Safety Audits',
        periodStart: DateTime.utc(2026, 7, 1),
        periodEnd: DateTime.utc(2026, 9, 30),
        targetValue: 12.0,
        actualValue: 12.0,
      );

      await cubit.reload();

      expect(cubit.state.totalKpis, 6);
      expect(cubit.state.periodStart, DateTime.utc(2026, 7, 1));
      expect(cubit.state.periodEnd, DateTime.utc(2026, 9, 30));
    });

    test('handles EmployeeKpiException with clear error message', () async {
      final failingRepo = FailingKpiSummaryRepo(isDomainException: true);
      final failCubit = EmployeeKpiSummaryCubit(repository: failingRepo);

      await failCubit.loadSummary();

      expect(failCubit.state.status, EmployeeKpiSummaryStatus.failure);
      expect(
        failCubit.state.errorMessage,
        'Simulated summary repository error',
      );

      await failCubit.close();
    });

    test('handles generic Exception with safe fallback message', () async {
      final crashingRepo = FailingKpiSummaryRepo(isDomainException: false);
      final crashCubit = EmployeeKpiSummaryCubit(repository: crashingRepo);

      await crashCubit.loadSummary();

      expect(crashCubit.state.status, EmployeeKpiSummaryStatus.failure);
      expect(
        crashCubit.state.errorMessage,
        'Failed to load KPI summary. Please try again.',
      );

      await crashCubit.close();
    });

    test('does not emit updates if cubit is closed', () async {
      final future = cubit.loadSummary();
      await cubit.close();
      await future;

      expect(cubit.isClosed, isTrue);
    });
  });
}
