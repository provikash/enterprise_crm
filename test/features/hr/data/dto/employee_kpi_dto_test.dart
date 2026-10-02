import 'package:enterprise_crm/features/hr/data/dto/employee_kpi_dto.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee_kpi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmployeeKpiDto - Serialization & Validation', () {
    test('parses valid JSON with all fields and normalizes dates to UTC midnight', () {
      final json = {
        'id': 'kpi_101',
        'employee_id': 'emp_1',
        'metric_name': 'Employee Retention Rate',
        'period_start': '2026-07-01',
        'period_end': '2026-09-30',
        'target_value': 90.0,
        'actual_value': 92.5,
        'score': 95.0,
        'remarks': 'Exceeded quarterly retention target',
        'created_at': '2026-07-01T10:00:00Z',
        'updated_at': '2026-09-30T18:00:00Z',
      };

      final dto = EmployeeKpiDto.fromJson(json);

      expect(dto.id, equals('kpi_101'));
      expect(dto.employeeId, equals('emp_1'));
      expect(dto.metricName, equals('Employee Retention Rate'));
      expect(dto.periodStart, equals(DateTime.utc(2026, 7, 1)));
      expect(dto.periodEnd, equals(DateTime.utc(2026, 9, 30)));
      expect(dto.targetValue, equals(90.0));
      expect(dto.actualValue, equals(92.5));
      expect(dto.score, equals(95.0));
      expect(dto.remarks, equals('Exceeded quarterly retention target'));
      expect(dto.createdAt, equals(DateTime.utc(2026, 7, 1, 10, 0)));
      expect(dto.updatedAt, equals(DateTime.utc(2026, 9, 30, 18, 0)));

      final domain = dto.toDomain();
      expect(domain, isA<EmployeeKpi>());
      expect(domain.id, equals('kpi_101'));
      expect(domain.targetValue, equals(90.0));
      expect(domain.actualValue, equals(92.5));
      expect(domain.score, equals(95.0));
    });

    test('parses valid JSON with optional fields omitted or null', () {
      final json = {
        'id': 'kpi_102',
        'employee_id': 'emp_2',
        'metric_name': 'Inventory Accuracy',
        'period_start': '2026-07-01',
        'period_end': '2026-09-30',
        'target_value': 98,
        'actual_value': 96.5,
      };

      final dto = EmployeeKpiDto.fromJson(json);

      expect(dto.id, equals('kpi_102'));
      expect(dto.score, isNull);
      expect(dto.remarks, isNull);
      expect(dto.createdAt, isNull);
      expect(dto.updatedAt, isNull);
    });

    test('serializes to JSON with snake_case keys', () {
      final dto = EmployeeKpiDto(
        id: 'kpi_301',
        employeeId: 'emp_3',
        periodStart: DateTime.utc(2026, 7, 1),
        periodEnd: DateTime.utc(2026, 9, 30),
        metricName: 'Quarterly Sales Revenue',
        targetValue: 150.0,
        actualValue: 165.0,
        score: 100.0,
        remarks: 'Surpassed target',
      );

      final json = dto.toJson();

      expect(json['id'], equals('kpi_301'));
      expect(json['employee_id'], equals('emp_3'));
      expect(json['metric_name'], equals('Quarterly Sales Revenue'));
      expect(json['period_start'], equals('2026-07-01'));
      expect(json['period_end'], equals('2026-09-30'));
      expect(json['target_value'], equals(150.0));
      expect(json['actual_value'], equals(165.0));
      expect(json['score'], equals(100.0));
      expect(json['remarks'], equals('Surpassed target'));
    });

    test('throws FormatException if id or employee_id is missing/empty', () {
      expect(
        () => EmployeeKpiDto.fromJson({
          'id': '',
          'employee_id': 'emp_1',
          'metric_name': 'Metric',
          'period_start': '2026-07-01',
          'period_end': '2026-09-30',
          'target_value': 100,
          'actual_value': 90,
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => EmployeeKpiDto.fromJson({
          'id': 'kpi_1',
          'employee_id': '   ',
          'metric_name': 'Metric',
          'period_start': '2026-07-01',
          'period_end': '2026-09-30',
          'target_value': 100,
          'actual_value': 90,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException if metric_name is missing or empty', () {
      expect(
        () => EmployeeKpiDto.fromJson({
          'id': 'kpi_1',
          'employee_id': 'emp_1',
          'metric_name': '   ',
          'period_start': '2026-07-01',
          'period_end': '2026-09-30',
          'target_value': 100,
          'actual_value': 90,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException if period_end is before period_start', () {
      expect(
        () => EmployeeKpiDto.fromJson({
          'id': 'kpi_1',
          'employee_id': 'emp_1',
          'metric_name': 'Metric',
          'period_start': '2026-09-30',
          'period_end': '2026-07-01',
          'target_value': 100,
          'actual_value': 90,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('roundtrips domain entity via fromDomain accurately', () {
      final domain = EmployeeKpi(
        id: 'kpi_domain_1',
        employeeId: 'emp_10',
        periodStart: DateTime.utc(2026, 1, 1),
        periodEnd: DateTime.utc(2026, 3, 31),
        metricName: 'Code Reviews Completed',
        targetValue: 50.0,
        actualValue: 55.0,
        score: 100.0,
        remarks: 'Strong engineering contribution',
      );

      final dto = EmployeeKpiDto.fromDomain(domain);
      final reconstructed = dto.toDomain();

      expect(reconstructed.id, equals(domain.id));
      expect(reconstructed.employeeId, equals(domain.employeeId));
      expect(reconstructed.periodStart, equals(domain.periodStart));
      expect(reconstructed.periodEnd, equals(domain.periodEnd));
      expect(reconstructed.metricName, equals(domain.metricName));
      expect(reconstructed.targetValue, equals(domain.targetValue));
      expect(reconstructed.actualValue, equals(domain.actualValue));
      expect(reconstructed.score, equals(domain.score));
      expect(reconstructed.remarks, equals(domain.remarks));
    });
  });
}
