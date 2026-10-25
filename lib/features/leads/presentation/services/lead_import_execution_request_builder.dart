import '../../domain/entities/lead_draft.dart';
import '../../domain/entities/lead_import.dart';
import '../../domain/entities/lead_source.dart';
import '../models/lead_import_preview.dart';
import '../models/lead_import_review.dart';

/// Exception thrown when preparing an execution request from preview and review
/// decisions fails due to invalid or inconsistent inputs.
class LeadImportExecutionPreparationException implements Exception {
  const LeadImportExecutionPreparationException([
    this.message = 'The selected import rows are no longer valid.',
  ]);

  final String message;

  @override
  String toString() => 'LeadImportExecutionPreparationException: $message';
}

/// Prepares a domain [LeadImportRequest] with structured [LeadDraft] items
/// from a validated [LeadImportPreview] and user [LeadImportReviewDecision].
abstract interface class LeadImportExecutionRequestBuilder {
  LeadImportRequest build({
    required LeadImportPreview preview,
    required LeadImportReviewDecision decision,
  });
}

class DefaultLeadImportExecutionRequestBuilder
    implements LeadImportExecutionRequestBuilder {
  const DefaultLeadImportExecutionRequestBuilder();

  @override
  LeadImportRequest build({
    required LeadImportPreview preview,
    required LeadImportReviewDecision decision,
  }) {
    if (decision.includedSourceRowIndices.isEmpty) {
      throw const LeadImportExecutionPreparationException(
        'The selected import rows are no longer valid.',
      );
    }

    final LeadImportFileType fileType;
    switch (preview.source) {
      case LeadSource.csv:
        fileType = LeadImportFileType.csv;
        break;
      case LeadSource.excel:
        fileType = LeadImportFileType.excel;
        break;
      case LeadSource.manual:
      case LeadSource.portal:
      case LeadSource.metaCampaign:
        throw const LeadImportExecutionPreparationException(
          'The selected import rows are no longer valid.',
        );
    }

    final uniqueSourceIndices = <int>{};
    final rowMap = <int, LeadImportPreviewRow>{};
    for (final row in preview.rows) {
      if (!uniqueSourceIndices.add(row.sourceRowIndex)) {
        throw const LeadImportExecutionPreparationException(
          'The selected import rows are no longer valid.',
        );
      }
      rowMap[row.sourceRowIndex] = row;
    }

    for (final index in decision.includedSourceRowIndices) {
      final row = rowMap[index];
      if (row == null || row.status != LeadImportPreviewRowStatus.valid) {
        throw const LeadImportExecutionPreparationException(
          'The selected import rows are no longer valid.',
        );
      }
    }

    final drafts = <LeadDraft>[];
    for (final row in preview.rows) {
      if (decision.includedSourceRowIndices.contains(row.sourceRowIndex)) {
        final fileSource = (preview.source == LeadSource.csv)
            ? LeadSource.csv
            : LeadSource.excel;
        final leadSource = preview.mapping.defaultSource ?? fileSource;

        final metadata = <String, String>{};
        if (row.country != null && row.country!.trim().isNotEmpty) {
          metadata['country'] = row.country!.trim();
        }
        if (row.priority != null && row.priority!.trim().isNotEmpty) {
          metadata['priority'] = row.priority!.trim();
        }
        if (row.requirement != null && row.requirement!.trim().isNotEmpty) {
          metadata['requirement'] = row.requirement!.trim();
        }
        if (row.estimatedValue != null &&
            row.estimatedValue!.trim().isNotEmpty) {
          metadata['estimated_value'] = row.estimatedValue!.trim();
        }
        if (row.notes != null && row.notes!.trim().isNotEmpty) {
          metadata['notes'] = row.notes!.trim();
        }
        if (row.source != null && row.source!.trim().isNotEmpty) {
          metadata['source_detail'] = row.source!.trim();
        }

        drafts.add(
          LeadDraft(
            name: _normalizeOptional(row.name),
            businessName: _normalizeOptional(row.businessName),
            phone: _normalizeOptional(row.phone),
            email: _normalizeOptional(row.email),
            city: _normalizeOptional(row.city),
            state: _normalizeOptional(row.state),
            status: null,
            source: leadSource,
            metadata: metadata.isEmpty ? null : metadata,
          ),
        );
      }
    }

    return LeadImportRequest.fromDrafts(
      fileName: preview.fileName,
      fileType: fileType,
      drafts: drafts,
    );
  }

  String? _normalizeOptional(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }
}
