import 'package:enterprise_crm/features/hr/domain/value_objects/calculation_validation_issue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalculationValidationIssue Tests (HR-7.3)', () {
    test('constructs default error issue', () {
      const issue = CalculationValidationIssue(
        code: 'MISSING_BASE_SALARY',
        message: 'Contracted base salary is not defined.',
      );

      expect(issue.code, equals('MISSING_BASE_SALARY'));
      expect(issue.message, equals('Contracted base salary is not defined.'));
      expect(issue.severity, equals(CalculationIssueSeverity.error));
      expect(issue.isError, isTrue);
      expect(issue.isWarning, isFalse);
    });

    test('constructs warning issue', () {
      const issue = CalculationValidationIssue(
        code: 'NEGATIVE_NET_PAYABLE',
        message: 'Total deductions exceed gross earnings.',
        severity: CalculationIssueSeverity.warning,
      );

      expect(issue.severity, equals(CalculationIssueSeverity.warning));
      expect(issue.isWarning, isTrue);
      expect(issue.isError, isFalse);
    });

    test('value equality and hashCode behavior', () {
      const i1 = CalculationValidationIssue(
        code: 'TEST_CODE',
        message: 'Test message',
      );
      const i2 = CalculationValidationIssue(
        code: 'TEST_CODE',
        message: 'Test message',
      );
      const i3 = CalculationValidationIssue(
        code: 'TEST_CODE',
        message: 'Different message',
      );

      expect(i1, equals(i2));
      expect(i1.hashCode, equals(i2.hashCode));
      expect(i1, isNot(equals(i3)));
    });

    test('toString representation contains code and severity', () {
      const issue = CalculationValidationIssue(
        code: 'CODE_1',
        message: 'Message 1',
        severity: CalculationIssueSeverity.warning,
      );
      expect(issue.toString(), contains('CODE_1'));
      expect(issue.toString(), contains('warning'));
    });
  });
}
