import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/hr/data/dto/employee_document_dto.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee_document.dart';

void main() {
  group('EmployeeDocumentDto - Parsing & Serialization', () {
    test('parses full valid JSON with snake_case keys', () {
      final json = {
        'id': 'doc_001',
        'employee_id': 'emp_101',
        'title': 'Degree Certificate',
        'file_name': 'degree.pdf',
        'file_extension': 'pdf',
        'file_size_bytes': 2048576,
        'document_type': 'Education',
        'expiry_date': '2030-12-31',
        'uploaded_at': '2026-01-15T10:30:00Z',
        'uploaded_by': 'usr_admin',
        'file_reference': 's3://crm-docs/emp_101/degree.pdf',
        'download_url': 'https://crm.example.com/download/doc_001',
      };

      final dto = EmployeeDocumentDto.fromJson(json);

      expect(dto.id, 'doc_001');
      expect(dto.employeeId, 'emp_101');
      expect(dto.title, 'Degree Certificate');
      expect(dto.fileName, 'degree.pdf');
      expect(dto.fileExtension, 'pdf');
      expect(dto.fileSizeBytes, 2048576);
      expect(dto.documentType, 'Education');
      expect(dto.expiryDate, DateTime.parse('2030-12-31'));
      expect(dto.uploadedAt, DateTime.parse('2026-01-15T10:30:00Z'));
      expect(dto.uploadedBy, 'usr_admin');
      expect(dto.fileReference, 's3://crm-docs/emp_101/degree.pdf');
      expect(dto.downloadUrl, 'https://crm.example.com/download/doc_001');
    });

    test('parses camelCase keys gracefully (employeeId, fileName, fileSizeBytes)', () {
      final json = {
        'id': 'doc_002',
        'employeeId': 'emp_102',
        'title': 'ID Proof',
        'fileName': 'id_card.png',
        'fileSizeBytes': 512000,
        'category': 'Identity',
        'uploadedAt': '2026-02-01T08:00:00Z',
      };

      final dto = EmployeeDocumentDto.fromJson(json);

      expect(dto.id, 'doc_002');
      expect(dto.employeeId, 'emp_102');
      expect(dto.title, 'ID Proof');
      expect(dto.fileName, 'id_card.png');
      expect(dto.fileExtension, 'png');
      expect(dto.fileSizeBytes, 512000);
      expect(dto.documentType, 'Identity');
    });

    test('throws FormatException when mandatory fields are missing', () {
      expect(
        () => EmployeeDocumentDto.fromJson({
          'employee_id': 'emp_101',
          'title': 'Title',
          'file_name': 'file.pdf',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => EmployeeDocumentDto.fromJson({
          'id': 'doc_001',
          'title': 'Title',
          'file_name': 'file.pdf',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => EmployeeDocumentDto.fromJson({
          'id': 'doc_001',
          'employee_id': 'emp_101',
          'file_name': 'file.pdf',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => EmployeeDocumentDto.fromJson({
          'id': 'doc_001',
          'employee_id': 'emp_101',
          'title': 'Title',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('converts DTO to domain EmployeeDocument accurately', () {
      final dto = EmployeeDocumentDto(
        id: 'doc_003',
        employeeId: 'emp_103',
        title: 'Offer Letter',
        fileName: 'offer.pdf',
        fileExtension: 'pdf',
        fileSizeBytes: 1024,
        documentType: 'Employment',
        uploadedAt: DateTime.utc(2025, 5, 10, 12, 0),
        uploadedBy: 'usr_hr',
      );

      final domain = dto.toDomain();

      expect(domain, isA<EmployeeDocument>());
      expect(domain.id, 'doc_003');
      expect(domain.employeeId, 'emp_103');
      expect(domain.title, 'Offer Letter');
      expect(domain.formattedFileSize, '1.0 KB');
      expect(domain.uploadedBy, 'usr_hr');
    });

    test('serializes DTO to JSON map', () {
      final dto = EmployeeDocumentDto(
        id: 'doc_004',
        employeeId: 'emp_104',
        title: 'Passport',
        fileName: 'passport.jpg',
        fileExtension: 'jpg',
        fileSizeBytes: 3000000,
        documentType: 'Identification',
        expiryDate: DateTime(2035, 1, 1),
        uploadedAt: DateTime.utc(2026, 1, 1, 0, 0),
      );

      final json = dto.toJson();

      expect(json['id'], 'doc_004');
      expect(json['employee_id'], 'emp_104');
      expect(json['expiry_date'], '2035-01-01');
      expect(json['uploaded_at'], '2026-01-01T00:00:00.000Z');
    });
  });
}
