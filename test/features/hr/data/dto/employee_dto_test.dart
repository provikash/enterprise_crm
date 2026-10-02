import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/hr/data/dto/employee_dto.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employment_status.dart';

void main() {
  group('EmployeeDto - Parsing & Serialization', () {
    test('parses full valid JSON with snake_case keys', () {
      final json = {
        'id': 'emp_001',
        'employee_code': 'EMP-001',
        'full_name': 'Aarav Sharma',
        'email': 'aarav.sharma@example.com',
        'phone': '+91 98765 43210',
        'department': 'Engineering',
        'designation': 'Staff Engineer',
        'status': 'active',
        'joining_date': '2023-01-15',
        'user_id': 'usr_002',
        'created_at': '2023-01-15T09:00:00Z',
        'updated_at': '2023-01-15T10:00:00Z',
      };

      final dto = EmployeeDto.fromJson(json);

      expect(dto.id, 'emp_001');
      expect(dto.employeeCode, 'EMP-001');
      expect(dto.fullName, 'Aarav Sharma');
      expect(dto.email, 'aarav.sharma@example.com');
      expect(dto.phone, '+91 98765 43210');
      expect(dto.department, 'Engineering');
      expect(dto.designation, 'Staff Engineer');
      expect(dto.status, 'active');
      expect(dto.joiningDate, DateTime.parse('2023-01-15'));
      expect(dto.userId, 'usr_002');
      expect(dto.createdAt, DateTime.parse('2023-01-15T09:00:00Z'));
      expect(dto.updatedAt, DateTime.parse('2023-01-15T10:00:00Z'));
    });

    test('parses camelCase keys gracefully (name, employeeCode, userId)', () {
      final json = {
        'id': 'emp_002',
        'name': 'Priya Patel',
        'employeeCode': 'EMP-002',
        'userId': 'usr_003',
        'employment_status': 'probation',
        'joiningDate': '2024-06-01',
      };

      final dto = EmployeeDto.fromJson(json);

      expect(dto.id, 'emp_002');
      expect(dto.fullName, 'Priya Patel');
      expect(dto.employeeCode, 'EMP-002');
      expect(dto.userId, 'usr_003');
      expect(dto.status, 'probation');
      expect(dto.joiningDate, DateTime.parse('2024-06-01'));
    });

    test('parses minimal JSON with only required fields (id, full_name)', () {
      final json = {
        'id': 'emp_003',
        'full_name': 'Rohan Gupta',
      };

      final dto = EmployeeDto.fromJson(json);

      expect(dto.id, 'emp_003');
      expect(dto.fullName, 'Rohan Gupta');
      expect(dto.employeeCode, isNull);
      expect(dto.email, isNull);
      expect(dto.status, 'active'); // Defaults to active
      expect(dto.joiningDate, isNull);
      expect(dto.userId, isNull);
    });

    test('throws FormatException when id is missing or empty', () {
      expect(
        () => EmployeeDto.fromJson({'full_name': 'Test User'}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => EmployeeDto.fromJson({'id': '  ', 'full_name': 'Test User'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when full_name is missing or empty', () {
      expect(
        () => EmployeeDto.fromJson({'id': 'emp_004'}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => EmployeeDto.fromJson({'id': 'emp_004', 'full_name': '   '}),
        throwsA(isA<FormatException>()),
      );
    });

    test('converts DTO to domain Employee entity correctly', () {
      final dto = EmployeeDto(
        id: 'emp_005',
        employeeCode: 'EMP-005',
        fullName: 'Kavita Rao',
        email: 'kavita.rao@example.com',
        phone: '+91 99887 76655',
        department: 'Operations',
        designation: 'Operations Lead',
        status: 'Inactive',
        joiningDate: DateTime.utc(2022, 5, 20),
        userId: 'usr_005',
      );

      final domain = dto.toDomain();

      expect(domain, isA<Employee>());
      expect(domain.id, 'emp_005');
      expect(domain.employeeCode, 'EMP-005');
      expect(domain.fullName, 'Kavita Rao');
      expect(domain.email, 'kavita.rao@example.com');
      expect(domain.phone, '+91 99887 76655');
      expect(domain.department, 'Operations');
      expect(domain.designation, 'Operations Lead');
      expect(domain.employmentStatus, EmploymentStatus.inactive);
      expect(domain.isActive, isFalse);
      expect(domain.joiningDate, DateTime.utc(2022, 5, 20));
      expect(domain.userId, 'usr_005');
      expect(domain.hasLinkedUser, isTrue);
    });

    test('converts domain Employee entity to DTO and serializes to JSON', () {
      const employee = Employee(
        id: 'emp_006',
        employeeCode: 'EMP-006',
        fullName: 'Vikram Seth',
        email: 'vikram@example.com',
        phone: '+91 91234 56789',
        department: 'Finance',
        designation: 'Financial Analyst',
        employmentStatus: EmploymentStatus.active,
        joiningDate: null,
      );

      final dto = EmployeeDto.fromDomain(employee);
      final json = dto.toJson();

      expect(json['id'], 'emp_006');
      expect(json['employee_code'], 'EMP-006');
      expect(json['full_name'], 'Vikram Seth');
      expect(json['email'], 'vikram@example.com');
      expect(json['department'], 'Finance');
      expect(json['status'], 'Active');
      expect(json.containsKey('joining_date'), isFalse);
    });

    test('serializes joining_date to YYYY-MM-DD in toJson()', () {
      final dto = EmployeeDto(
        id: 'emp_007',
        fullName: 'Meera Nambiar',
        joiningDate: DateTime(2025, 3, 9),
      );

      final json = dto.toJson();

      expect(json['joining_date'], '2025-03-09');
    });
  });
}
