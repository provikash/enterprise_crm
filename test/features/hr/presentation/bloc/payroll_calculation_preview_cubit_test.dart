import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_calculation_input.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_component.dart';
import 'package:enterprise_crm/features/hr/domain/services/payroll_calculation_engine.dart';
import 'package:enterprise_crm/features/hr/domain/value_objects/money.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/payroll_calculation_preview_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/payroll_calculation_preview_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayrollCalculationPreviewCubit Tests (HR-7.6)', () {
    late MockEmployeeRepository employeeRepo;
    late MockPayrollRepository payrollRepo;

    final testInput = PayrollCalculationInput(
      id: 'calc_test_01',
      employeeId: 'emp_1',
      payrollPeriodId: 'period_2026_01',
      baseSalary: const Money(minorUnits: 5000000), // ₹50,000.00
      unpaidLeaveDays: 2,
      components: [
        PayrollComponent.earning(
          id: 'comp_hra',
          name: 'HRA',
          amount: const Money(minorUnits: 2500000), // ₹25,000.00
        ),
        PayrollComponent.deduction(
          id: 'comp_pt',
          name: 'Professional Tax',
          amount: const Money(minorUnits: 20000), // ₹200.00
        ),
      ],
    );

    setUp(() {
      employeeRepo = MockEmployeeRepository();
      payrollRepo = MockPayrollRepository();
    });

    test('initial state has correct default values', () {
      final cubit = PayrollCalculationPreviewCubit(
        employeeRepository: employeeRepo,
        payrollRepository: payrollRepo,
      );

      expect(cubit.state.status, equals(PayrollCalculationPreviewStatus.initial));
      expect(cubit.state.hasResult, isFalse);
      expect(cubit.state.attendancePolicy, equals(AttendanceProrationPolicy.unresolved));
      expect(cubit.state.errorMessage, isNull);
      cubit.close();
    });

    test('calculatePreview evaluates preview and resolves relational metadata', () async {
      final cubit = PayrollCalculationPreviewCubit(
        employeeRepository: employeeRepo,
        payrollRepository: payrollRepo,
      );

      await cubit.calculatePreview(
        input: testInput,
        calculationTimestamp: DateTime.utc(2026, 1, 31),
      );

      expect(cubit.state.status, equals(PayrollCalculationPreviewStatus.loaded));
      expect(cubit.state.hasResult, isTrue);
      expect(cubit.state.result!.baseSalary.majorUnits, equals(50000.0));
      expect(cubit.state.result!.grossEarnings.majorUnits, equals(75000.0));
      // With unresolved LOP policy, LOP is deferred -> deductions only include PT (₹200)
      expect(cubit.state.result!.totalDeductions.majorUnits, equals(200.0));
      expect(cubit.state.result!.netPayable.majorUnits, equals(74800.0));

      // Check resolved relationships
      expect(cubit.state.employee, isNotNull);
      expect(cubit.state.employee!.id, equals('emp_1'));
      expect(cubit.state.period, isNotNull);
      expect(cubit.state.period!.id, equals('period_2026_01'));

      cubit.close();
    });

    test('setAttendancePolicy updates policy and recalculates with new proration', () async {
      final cubit = PayrollCalculationPreviewCubit(
        employeeRepository: employeeRepo,
        payrollRepository: payrollRepo,
        initialInput: testInput,
      );

      // Wait for initial load
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.status, equals(PayrollCalculationPreviewStatus.loaded));
      expect(cubit.state.attendancePolicy, equals(AttendanceProrationPolicy.unresolved));

      // Switch to fixed 30 days policy
      // Base: ₹50,000. 2 days unpaid: 50,000 * 2 / 30 = 3,333.33 -> 333,333 paise (₹3,333.33)
      // Deductions: PT (₹200) + LOP (₹3,333.33) = ₹3,533.33
      await cubit.setAttendancePolicy(AttendanceProrationPolicy.fixed30Days);

      expect(cubit.state.attendancePolicy, equals(AttendanceProrationPolicy.fixed30Days));
      expect(cubit.state.result!.deductions.any((d) => d.id.startsWith('comp_lop')), isTrue);
      expect(cubit.state.result!.totalDeductions.minorUnits, equals(20000 + 333333)); // ₹3,533.33

      cubit.close();
    });

    test('retry re-evaluates current input cleanly', () async {
      final cubit = PayrollCalculationPreviewCubit(
        employeeRepository: employeeRepo,
        payrollRepository: payrollRepo,
        initialInput: testInput,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.status, equals(PayrollCalculationPreviewStatus.loaded));

      await cubit.retry();
      expect(cubit.state.status, equals(PayrollCalculationPreviewStatus.loaded));
      expect(cubit.state.result, isNotNull);

      cubit.close();
    });
  });
}
