import 'dart:async';

import 'package:enterprise_crm/features/hr/data/mock/mock_payroll_store.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_period.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_record.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/payroll_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/payroll_period_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/widgets/payroll_period_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class CompleterPayrollRepository implements PayrollRepository {
  final completer = Completer<List<PayrollPeriod>>();

  @override
  Future<List<PayrollPeriod>> getPayrollPeriods() => completer.future;

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

Widget _buildTestApp({
  required PayrollPeriodCubit cubit,
  ValueChanged<PayrollPeriod?>? onPeriodChanged,
  Brightness brightness = Brightness.light,
}) {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: brightness,
      ),
    ),
    home: Scaffold(
      body: BlocProvider<PayrollPeriodCubit>.value(
        value: cubit,
        child: SingleChildScrollView(
          child: PayrollPeriodSelector(
            onPeriodChanged: onPeriodChanged,
          ),
        ),
      ),
    ),
  );
}

void main() {
  late MockPayrollStore store;
  late MockPayrollRepository repository;

  setUp(() {
    store = MockPayrollStore();
    repository = MockPayrollRepository(store: store);
  });

  group('PayrollPeriodSelector Widget Tests (HR-6.4)', () {
    testWidgets('renders loading indicator while periods are being fetched', (tester) async {
      final completerRepo = CompleterPayrollRepository();
      final cubit = PayrollPeriodCubit(repository: completerRepo);
      unawaited(cubit.loadPeriods());

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pump();

      expect(find.byKey(const Key('payroll_period_loading_indicator')), findsOneWidget);

      completerRepo.completer.complete([]);
      await tester.pumpAndSettle();
      cubit.close();
    });

    testWidgets('renders empty state when repository has no periods', (tester) async {
      final emptyStore = MockPayrollStore(seedInitialData: false);
      final emptyRepo = MockPayrollRepository(store: emptyStore);
      final cubit = PayrollPeriodCubit(repository: emptyRepo);
      await cubit.loadPeriods();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_period_empty_message')), findsOneWidget);
      expect(find.text('No payroll periods are available.'), findsOneWidget);
      expect(find.byKey(const Key('payroll_period_empty_refresh_button')), findsOneWidget);

      cubit.close();
    });

    testWidgets('renders error message and retry button on failure', (tester) async {
      store.setSimulatedFailure(true);
      final cubit = PayrollPeriodCubit(repository: repository);
      await cubit.loadPeriods();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_period_error_message')), findsOneWidget);
      expect(find.byKey(const Key('payroll_period_retry_button')), findsOneWidget);

      // Disable failure and tap retry
      store.setSimulatedFailure(false);
      await tester.tap(find.byKey(const Key('payroll_period_retry_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_period_dropdown')), findsOneWidget);

      cubit.close();
    });

    testWidgets('displays dropdown and allows selecting a period', (tester) async {
      PayrollPeriod? selectedReported;
      final cubit = PayrollPeriodCubit(repository: repository);
      await cubit.loadPeriods();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          onPeriodChanged: (period) => selectedReported = period,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_period_dropdown')), findsOneWidget);
      expect(find.text('Select a payroll period'), findsOneWidget);

      // Tap dropdown to open menu
      await tester.tap(find.byKey(const Key('payroll_period_dropdown')));
      await tester.pumpAndSettle();

      // Find January 2026 item
      final janItem = find.byKey(const Key('payroll_period_item_period_2026_01')).last;
      expect(janItem, findsOneWidget);
      await tester.tap(janItem);
      await tester.pumpAndSettle();

      // Verify active period details appear
      expect(find.byKey(const Key('payroll_period_selected_details')), findsOneWidget);
      expect(find.byKey(const Key('payroll_period_selected_label')), findsOneWidget);
      expect(find.textContaining('January 2026'), findsWidgets);
      expect(selectedReported, isNotNull);
      expect(selectedReported!.id, 'period_2026_01');

      cubit.close();
    });

    testWidgets('renders correctly in Dark theme', (tester) async {
      final cubit = PayrollPeriodCubit(
        repository: repository,
        initialPeriodId: 'period_2026_01',
      );
      await cubit.loadPeriods();

      await tester.pumpWidget(
        _buildTestApp(cubit: cubit, brightness: Brightness.dark),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_period_selector_card')), findsOneWidget);
      expect(find.byKey(const Key('payroll_period_selected_details')), findsOneWidget);

      cubit.close();
    });

    testWidgets('renders cleanly on narrow mobile viewports without RenderFlex overflow', (tester) async {
      final viewports = [
        const Size(320, 568),
        const Size(360, 640),
        const Size(768, 1024),
        const Size(1200, 800),
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        final cubit = PayrollPeriodCubit(
          repository: repository,
          initialPeriodId: 'period_2026_01',
        );
        await cubit.loadPeriods();

        await tester.pumpWidget(_buildTestApp(cubit: cubit));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('payroll_period_selector_card')), findsOneWidget);
        expect(tester.takeException(), isNull);

        cubit.close();
      }

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
