import '../../domain/entities/employee_document.dart';

/// Data Transfer Object representing an Employee Document in backend communication.
///
/// Established in HR-10.5 as the strict parsing and serialization boundary
/// between the instructor backend JSON contracts and the immutable [EmployeeDocument] domain entity.
///
/// Invariants:
/// - [id], [employeeId], [title], and [fileName] are mandatory; missing values in JSON raise [FormatException].
/// - [uploadedAt] is normalized to UTC [DateTime].
/// - Raw binary file contents are never stored permanently in this DTO.
class EmployeeDocumentDto {
  final String id;
  final String employeeId;
  final String title;
  final String fileName;
  final String fileExtension;
  final int fileSizeBytes;
  final String documentType;
  final DateTime? expiryDate;
  final DateTime uploadedAt;
  final String? uploadedBy;
  final String? fileReference;
  final String? downloadUrl;

  const EmployeeDocumentDto({
    required this.id,
    required this.employeeId,
    required this.title,
    required this.fileName,
    required this.fileExtension,
    required this.fileSizeBytes,
    required this.documentType,
    this.expiryDate,
    required this.uploadedAt,
    this.uploadedBy,
    this.fileReference,
    this.downloadUrl,
  });

  /// Parses a backend JSON map into a validated [EmployeeDocumentDto].
  ///
  /// Throws [FormatException] if mandatory fields are missing or empty.
  factory EmployeeDocumentDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString().trim();
    if (rawId == null || rawId.isEmpty) {
      throw const FormatException('EmployeeDocumentDto.fromJson: missing or empty required field "id".');
    }

    final rawEmpId = (json['employee_id'] ?? json['employeeId'])?.toString().trim();
    if (rawEmpId == null || rawEmpId.isEmpty) {
      throw const FormatException('EmployeeDocumentDto.fromJson: missing or empty required field "employee_id".');
    }

    final rawTitle = json['title']?.toString().trim();
    if (rawTitle == null || rawTitle.isEmpty) {
      throw const FormatException('EmployeeDocumentDto.fromJson: missing or empty required field "title".');
    }

    final rawFileName = (json['file_name'] ?? json['fileName'])?.toString().trim();
    if (rawFileName == null || rawFileName.isEmpty) {
      throw const FormatException('EmployeeDocumentDto.fromJson: missing or empty required field "file_name".');
    }

    final rawExt = (json['file_extension'] ?? json['fileExtension'])?.toString().trim() ??
        (rawFileName.contains('.') ? rawFileName.split('.').last : '');

    final rawSizeBytes = json['file_size_bytes'] ?? json['fileSizeBytes'] ?? json['size'] ?? 0;
    final int parsedSize;
    if (rawSizeBytes is int) {
      parsedSize = rawSizeBytes;
    } else {
      parsedSize = int.tryParse(rawSizeBytes.toString()) ?? 0;
    }

    final rawDocType = (json['document_type'] ?? json['documentType'] ?? json['category'])?.toString().trim() ?? 'Other';

    DateTime? parsedExpiryDate;
    final rawExpiry = json['expiry_date'] ?? json['expiryDate'];
    if (rawExpiry != null) {
      parsedExpiryDate = DateTime.tryParse(rawExpiry.toString());
    }

    final rawUploadedAt = json['uploaded_at'] ?? json['uploadedAt'] ?? json['created_at'];
    final DateTime parsedUploadedAt;
    if (rawUploadedAt != null) {
      parsedUploadedAt = DateTime.tryParse(rawUploadedAt.toString())?.toUtc() ?? DateTime.now().toUtc();
    } else {
      parsedUploadedAt = DateTime.now().toUtc();
    }

    final rawUploadedBy = (json['uploaded_by'] ?? json['uploadedBy'])?.toString().trim();
    final rawFileRef = (json['file_reference'] ?? json['fileReference'] ?? json['reference'])?.toString().trim();
    final rawDownloadUrl = (json['download_url'] ?? json['downloadUrl'] ?? json['url'])?.toString().trim();

    return EmployeeDocumentDto(
      id: rawId,
      employeeId: rawEmpId,
      title: rawTitle,
      fileName: rawFileName,
      fileExtension: rawExt,
      fileSizeBytes: parsedSize,
      documentType: rawDocType,
      expiryDate: parsedExpiryDate,
      uploadedAt: parsedUploadedAt,
      uploadedBy: (rawUploadedBy != null && rawUploadedBy.isNotEmpty) ? rawUploadedBy : null,
      fileReference: (rawFileRef != null && rawFileRef.isNotEmpty) ? rawFileRef : null,
      downloadUrl: (rawDownloadUrl != null && rawDownloadUrl.isNotEmpty) ? rawDownloadUrl : null,
    );
  }

  /// Creates an [EmployeeDocumentDto] from an existing immutable [EmployeeDocument] domain entity.
  factory EmployeeDocumentDto.fromDomain(EmployeeDocument document, {String? downloadUrl}) {
    return EmployeeDocumentDto(
      id: document.id,
      employeeId: document.employeeId,
      title: document.title,
      fileName: document.fileName,
      fileExtension: document.fileExtension,
      fileSizeBytes: document.fileSizeBytes,
      documentType: document.documentType,
      expiryDate: document.expiryDate,
      uploadedAt: document.uploadedAt,
      uploadedBy: document.uploadedBy,
      fileReference: document.fileReference,
      downloadUrl: downloadUrl,
    );
  }

  /// Converts this DTO into an immutable [EmployeeDocument] domain entity.
  EmployeeDocument toDomain() {
    return EmployeeDocument(
      id: id,
      employeeId: employeeId,
      title: title,
      fileName: fileName,
      fileExtension: fileExtension,
      fileSizeBytes: fileSizeBytes,
      documentType: documentType,
      expiryDate: expiryDate,
      uploadedAt: uploadedAt,
      uploadedBy: uploadedBy,
      fileReference: fileReference,
    );
  }

  /// Serializes this DTO to a backend-compatible JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'title': title,
      'file_name': fileName,
      'file_extension': fileExtension,
      'file_size_bytes': fileSizeBytes,
      'document_type': documentType,
      if (expiryDate != null)
        'expiry_date':
            '${expiryDate!.year.toString().padLeft(4, '0')}-${expiryDate!.month.toString().padLeft(2, '0')}-${expiryDate!.day.toString().padLeft(2, '0')}',
      'uploaded_at': uploadedAt.toUtc().toIso8601String(),
      if (uploadedBy != null) 'uploaded_by': uploadedBy,
      if (fileReference != null) 'file_reference': fileReference,
      if (downloadUrl != null) 'download_url': downloadUrl,
    };
  }
}
