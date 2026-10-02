import 'package:enterprise_crm/features/hr/data/dto/payroll_period_dto.dart';
import 'package:enterprise_crm/features/hr/data/dto/payroll_record_dto.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_period.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayrollPeriodDto - Serialization & Validation', () {
    test('parses valid JSON with all fields and normalizes dates to UTC midnight', () {
      final json = {
        'id': 'period_2026_01',
        'name': 'January 2026',
        'start_date': '2026-01-01',
        'end_date': '2026-01-31',
        'payment_date': '2026-02-05',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-02-05T12:00:00Z',
      };

      final dto = PayrollPeriodDto.fromJson(json);

      expect(dto.id, equals('period_2026_01'));
      expect(dto.name, equals('January 2026'));
      expect(dto.startDate, equals(DateTime.utc(2026, 1, 1)));
      expect(dto.endDate, equals(DateTime.utc(2026, 1, 31)));
      expect(dto.paymentDate, equals(DateTime.utc(2026, 2, 5)));

      final domain = dto.toDomain();
      expect(domain, isA<PayrollPeriod>());
      expect(domain.id, equals('period_2026_01'));
      expect(domain.name, equals('January 2026'));
      expect(domain.startDate, equals(DateTime.utc(2026, 1, 1)));
      expect(domain.endDate, equals(DateTime.utc(2026, 1, 31)));
    });

    test('throws FormatException if id or name is missing', () {
      expect(
        () => PayrollPeriodDto.fromJson({
          'id': '  ',
          'name': 'Period',
          'start_date': '2026-01-01',
          'end_date': '2026-01-31',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => PayrollPeriodDto.fromJson({
          'id': 'period_1',
          'name': '',
          'start_date': '2026-01-01',
          'end_date': '2026-01-31',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException if end_date precedes start_date', () {
      expect(
        () => PayrollPeriodDto.fromJson({
          'id': 'period_1',
          'name': 'Period',
          'start_date': '2026-01-31',
          'end_date': '2026-01-01',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('serializes to JSON with snake_case keys', () {
      final dto = PayrollPeriodDto(
        id: 'period_2026_02',
        name: 'February 2026',
        startDate: DateTime.utc(2026, 2, 1),
        endDate: DateTime.utc(2026, 2, 28),
        paymentDate: DateTime.utc(2026, 3, 5),
      );

      final json = dto.toJson();
      expect(json['id'], equals('period_2026_02'));
      expect(json['name'], equals('February 2026'));
      expect(json['start_date'], equals('2026-02-01'));
      expect(json['end_date'], equals('2026-02-28'));
      expect(json['payment_date'], equals('2026-03-05'));
    });
  });

  group('PayrollRecordDto - Serialization & Monetary Integrity', () {
    test('parses valid JSON with compensation figures and ISO currency', () {
      final json = {
        'id': 'pay_101',
        'employee_id': 'emp_1',
        'payroll_period_id': 'period_2026_01',
        'gross_salary': 8500.0,
        'net_salary': 7200.0,
        'total_allowances': 500.0,
        'total_deductions': 1800.0,
        'currency': 'INR',
        'payment_status': 'Paid',
        'payment_date': '2026-02-05',
        'remarks': 'Processed on time',
      };

      final dto = PayrollRecordDto.fromJson(json);

      expect(dto.id, equals('pay_101'));
      expect(dto.employeeId, equals('emp_1'));
      expect(dto.payrollPeriodId, equals('period_2026_01'));
      expect(dto.grossSalary, equals(8500.0));
      expect(dto.netSalary, equals(7200.0));
      expect(dto.totalAllowances, equals(500.0));
      expect(dto.totalDeductions, equals(1800.0));
      expect(dto.currency, equals('INR'));
      expect(dto.paymentStatus, equals('Paid'));
      expect(dto.paymentDate, equals(DateTime.utc(2026, 2, 5)));

      final domain = dto.toDomain();
      expect(domain, isA<PayrollRecord>());
      expect(domain.grossSalary, equals(8500.0));
      expect(domain.netSalary, equals(7200.0));
      expect(domain.currency, equals('INR'));
    });

    test('preserves null monetary values without fabricating zero', () {
      final json = {
        'id': 'pay_102',
        'employee_id': 'emp_2',
        'period_id': 'period_2026_01',
      };

      final dto = PayrollRecordDto.fromJson(json);

      expect(dto.grossSalary, isNull);
      expect(dto.netSalary, isNull);
      expect(dto.totalAllowances, isNull);
      expect(dto.totalDeductions, isNull);

      final domain = dto.toDomain();
      expect(domain.grossSalary, isNull);
      expect(domain.netSalary, isNull);
    });

    test('throws FormatException if id, employee_id, or payroll_period_id is missing', () {
      expect(
        () => PayrollRecordDto.fromJson({
          'id': '',
          'employee_id': 'emp_1',
          'payroll_period_id': 'period_1',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => PayrollRecordDto.fromJson({
          'id': 'pay_1',
          'employee_id': '   ',
          'payroll_period_id': 'period_1',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => PayrollRecordDto.fromJson({
          'id': 'pay_1',
          'employee_id': 'emp_1',
          'payroll_period_id': '   ',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('roundtrips domain entity via fromDomain accurately', () {
      final domain = PayrollRecord(
        id: 'pay_domain_1',
        employeeId: 'emp_5',
        payrollPeriodId: 'period_2026_03',
        grossSalary: 12000.50,
        netSalary: 10500.25,
        totalAllowances: 1000.0,
        totalDeductions: 2500.25,
        currency: 'USD',
        paymentStatus: 'Pending',
      );

      final dto = PayrollRecordDto.fromDomain(domain);
      final reconstructed = dto.toDomain();

      expect(reconstructed.id, equals(domain.id));
      expect(reconstructed.employeeId, equals(domain.employeeId));
      expect(reconstructed.payrollPeriodId, equals(domain.payrollPeriodId));
      expect(reconstructed.grossSalary, equals(domain.grossSalary));
      expect(reconstructed.netSalary, equals(domain.netSalary));
      expect(reconstructed.totalAllowances, equals(domain.totalAllowances));
      expect(reconstructed.totalDeductions, equals(domain.totalDeductions));
      expect(reconstructed.currency, equals(domain.currency));
      expect(reconstructed.paymentStatus, equals(domain.paymentStatus));
    });
  });
}
