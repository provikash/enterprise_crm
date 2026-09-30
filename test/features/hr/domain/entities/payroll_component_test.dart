import 'package:enterprise_crm/features/hr/domain/entities/payroll_component.dart';
import 'package:enterprise_crm/features/hr/domain/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayrollComponent Domain Entity Tests (HR-7.4)', () {
    final amount10k = const Money(minorUnits: 1000000); // ₹10,000.00
    final amountZero = const Money(minorUnits: 0);

    test('constructs valid earning component with default stored source', () {
      final comp = PayrollComponent(
        id: 'comp_hra_01',
        name: 'House Rent Allowance',
        kind: PayrollComponentKind.earning,
        amount: amount10k,
      );

      expect(comp.id, equals('comp_hra_01'));
      expect(comp.name, equals('House Rent Allowance'));
      expect(comp.kind, equals(PayrollComponentKind.earning));
      expect(comp.isEarning, isTrue);
      expect(comp.isDeduction, isFalse);
      expect(comp.amount, equals(amount10k));
      expect(comp.currency, equals('INR'));
      expect(comp.source, equals(PayrollComponentSource.stored));
      expect(comp.isStored, isTrue);
      expect(comp.isCalculated, isFalse);
      expect(comp.isBackendAuthoritative, isFalse);
      expect(comp.isUserAdjustment, isFalse);
      expect(comp.effectiveDate, isNull);
      expect(comp.calculationRuleId, isNull);
      expect(comp.remarks, isNull);
    });

    test('constructs valid deduction component using deduction factory', () {
      final comp = PayrollComponent.deduction(
        id: 'comp_lop_01',
        name: 'Loss of Pay',
        amount: const Money(minorUnits: 150000), // ₹1,500.00
        source: PayrollComponentSource.calculated,
        calculationRuleId: 'FORM-04-LOP',
        remarks: '1 day unpaid leave',
      );

      expect(comp.id, equals('comp_lop_01'));
      expect(comp.name, equals('Loss of Pay'));
      expect(comp.kind, equals(PayrollComponentKind.deduction));
      expect(comp.isEarning, isFalse);
      expect(comp.isDeduction, isTrue);
      expect(comp.amount.majorUnits, equals(1500.0));
      expect(comp.isCalculated, isTrue);
      expect(comp.calculationRuleId, equals('FORM-04-LOP'));
      expect(comp.remarks, equals('1 day unpaid leave'));
    });

    test('constructs valid earning using earning factory', () {
      final comp = PayrollComponent.earning(
        id: 'comp_bonus_01',
        name: 'Discretionary Bonus',
        amount: const Money(minorUnits: 500000), // ₹5,000.00
        source: PayrollComponentSource.userAdjustment,
        remarks: 'Approved Q3 festival bonus',
      );

      expect(comp.isEarning, isTrue);
      expect(comp.isUserAdjustment, isTrue);
      expect(comp.amount.majorUnits, equals(5000.0));
      expect(comp.remarks, equals('Approved Q3 festival bonus'));
    });

    test('supports explicit zero amount (valid and non-negative)', () {
      final comp = PayrollComponent(
        id: 'comp_zero_01',
        name: 'Conveyance Allowance',
        kind: PayrollComponentKind.earning,
        amount: amountZero,
      );

      expect(comp.amount.isZero, isTrue);
      expect(comp.amount.minorUnits, equals(0));
    });

    test('throws ArgumentError on empty or whitespace id', () {
      expect(
        () => PayrollComponent(
          id: '   ',
          name: 'Basic',
          kind: PayrollComponentKind.earning,
          amount: amount10k,
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError on empty or whitespace name', () {
      expect(
        () => PayrollComponent(
          id: 'comp_1',
          name: '',
          kind: PayrollComponentKind.earning,
          amount: amount10k,
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError on negative component amount', () {
      final negativeMoney = const Money(minorUnits: -50000);
      expect(
        () => PayrollComponent(
          id: 'comp_1',
          name: 'Invalid Component',
          kind: PayrollComponentKind.earning,
          amount: negativeMoney,
        ),
        throwsArgumentError,
      );
    });

    test('enforces calculationRuleId when source is calculated', () {
      // Missing calculationRuleId throws
      expect(
        () => PayrollComponent(
          id: 'comp_calc_1',
          name: 'Calculated PF',
          kind: PayrollComponentKind.deduction,
          amount: const Money(minorUnits: 180000),
          source: PayrollComponentSource.calculated,
          calculationRuleId: null,
        ),
        throwsArgumentError,
      );

      // Empty calculationRuleId throws
      expect(
        () => PayrollComponent(
          id: 'comp_calc_1',
          name: 'Calculated PF',
          kind: PayrollComponentKind.deduction,
          amount: const Money(minorUnits: 180000),
          source: PayrollComponentSource.calculated,
          calculationRuleId: '   ',
        ),
        throwsArgumentError,
      );

      // Non-empty calculationRuleId succeeds
      final valid = PayrollComponent(
        id: 'comp_calc_1',
        name: 'Calculated PF',
        kind: PayrollComponentKind.deduction,
        amount: const Money(minorUnits: 180000),
        source: PayrollComponentSource.calculated,
        calculationRuleId: 'RULE-PF-STATUTORY-V1',
      );
      expect(valid.calculationRuleId, equals('RULE-PF-STATUTORY-V1'));
    });

    test('normalizes effectiveDate to UTC midnight', () {
      final localDate = DateTime(2026, 3, 15, 14, 30, 45);
      final comp = PayrollComponent(
        id: 'comp_1',
        name: 'Basic',
        kind: PayrollComponentKind.earning,
        amount: amount10k,
        effectiveDate: localDate,
      );

      expect(comp.effectiveDate, equals(DateTime.utc(2026, 3, 15)));
      expect(comp.effectiveDate!.isUtc, isTrue);
    });

    test('isApplicableForPeriod evaluates effective date boundaries correctly', () {
      final periodStart = DateTime.utc(2026, 1, 1);
      final periodEnd = DateTime.utc(2026, 1, 31);

      // No effective date -> always applicable
      final universalComp = PayrollComponent(
        id: 'comp_1',
        name: 'Basic',
        kind: PayrollComponentKind.earning,
        amount: amount10k,
      );
      expect(universalComp.isApplicableForPeriod(periodStart, periodEnd), isTrue);

      // Effective on or before periodEnd -> applicable
      final beforeComp = PayrollComponent(
        id: 'comp_2',
        name: 'HRA',
        kind: PayrollComponentKind.earning,
        amount: amount10k,
        effectiveDate: DateTime.utc(2026, 1, 15),
      );
      expect(beforeComp.isApplicableForPeriod(periodStart, periodEnd), isTrue);

      // Effective exactly on periodEnd -> applicable
      final exactlyOnEndComp = PayrollComponent(
        id: 'comp_3',
        name: 'Special',
        kind: PayrollComponentKind.earning,
        amount: amount10k,
        effectiveDate: DateTime.utc(2026, 1, 31),
      );
      expect(exactlyOnEndComp.isApplicableForPeriod(periodStart, periodEnd), isTrue);

      // Effective strictly after periodEnd -> NOT applicable
      final futureComp = PayrollComponent(
        id: 'comp_4',
        name: 'Future Allowance',
        kind: PayrollComponentKind.earning,
        amount: amount10k,
        effectiveDate: DateTime.utc(2026, 2, 1),
      );
      expect(futureComp.isApplicableForPeriod(periodStart, periodEnd), isFalse);
    });

    test('copyWith creates faithful copy and supports clearing nullable fields', () {
      final original = PayrollComponent(
        id: 'comp_orig',
        name: 'Special Allowance',
        kind: PayrollComponentKind.earning,
        amount: amount10k,
        source: PayrollComponentSource.backendAuthoritative,
        effectiveDate: DateTime.utc(2026, 1, 1),
        calculationRuleId: 'RULE_BACKEND',
        remarks: 'Initial notes',
      );

      final updated = original.copyWith(
        amount: const Money(minorUnits: 1200000),
        clearEffectiveDate: true,
        clearRemarks: true,
      );

      expect(updated.id, equals('comp_orig'));
      expect(updated.name, equals('Special Allowance'));
      expect(updated.amount.majorUnits, equals(12000.0));
      expect(updated.effectiveDate, isNull);
      expect(updated.remarks, isNull);
      expect(original.effectiveDate, isNotNull);
      expect(original.remarks, equals('Initial notes'));
    });

    test('value equality and hashCode behavior', () {
      final c1 = PayrollComponent(
        id: 'comp_1',
        name: 'Basic Salary',
        kind: PayrollComponentKind.earning,
        amount: amount10k,
      );
      final c2 = PayrollComponent(
        id: 'comp_1',
        name: 'Basic Salary',
        kind: PayrollComponentKind.earning,
        amount: amount10k,
      );
      final c3 = PayrollComponent(
        id: 'comp_2',
        name: 'Basic Salary',
        kind: PayrollComponentKind.earning,
        amount: amount10k,
      );

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1, isNot(equals(c3)));
    });

    test('preserves backendAuthoritative source without forced calculation', () {
      final backendComp = PayrollComponent(
        id: 'comp_backend_tds',
        name: 'Tax Deducted at Source',
        kind: PayrollComponentKind.deduction,
        amount: const Money(minorUnits: 250000), // ₹2,500.00
        source: PayrollComponentSource.backendAuthoritative,
        remarks: 'Supplied directly by backend IT slab service',
      );

      expect(backendComp.isBackendAuthoritative, isTrue);
      expect(backendComp.isCalculated, isFalse);
      expect(backendComp.calculationRuleId, isNull);
    });

    test('toString maintains privacy and does not expose sensitive dump', () {
      final comp = PayrollComponent(
        id: 'comp_priv',
        name: 'Confidential Allowance',
        kind: PayrollComponentKind.earning,
        amount: amount10k,
      );
      expect(comp.toString(), contains('comp_priv'));
      expect(comp.toString(), contains('Confidential Allowance'));
      expect(comp.toString(), contains('earning'));
    });
  });
}
