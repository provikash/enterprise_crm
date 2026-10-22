import '../entities/lead_draft.dart';
import '../entities/lead_ingestion_result.dart';
import '../entities/lead_source.dart';
import '../entities/portal_lead_payload.dart';
import '../repositories/lead_repository.dart';

/// Ingestion service handling Web Portal and Landing Page lead submissions.
class PortalLeadIngestionService {
  final LeadRepository _repository;
  final String? _expectedSecretKey;

  const PortalLeadIngestionService({
    required LeadRepository repository,
    String? expectedSecretKey,
  })  : _repository = repository,
        _expectedSecretKey = expectedSecretKey;

  /// Ingests an inbound portal payload, checking auth secret if configured.
  Future<LeadIngestionResult> ingest({
    required PortalLeadPayload payload,
    String? providedSecretKey,
  }) async {
    if (_expectedSecretKey != null && _expectedSecretKey.isNotEmpty) {
      if (providedSecretKey != _expectedSecretKey) {
        return const LeadIngestionResult.failure(
          source: LeadSource.portal,
          errorMessage: 'Authentication failed: Invalid Portal Secret Key.',
        );
      }
    }

    if (!payload.isValid) {
      return const LeadIngestionResult.failure(
        source: LeadSource.portal,
        errorMessage:
            'Invalid portal lead: At least one contact field (name, phone, email, or business name) is required.',
      );
    }

    try {
      final draft = payload.toLeadDraft();
      final created =
          await _repository.createLead(CreateLeadInput(draft: draft));
      return LeadIngestionResult.success(
        lead: created,
        externalReferenceId: payload.formId,
      );
    } catch (e) {
      return LeadIngestionResult.failure(
        source: LeadSource.portal,
        errorMessage: 'Portal ingestion failed: $e',
        externalReferenceId: payload.formId,
      );
    }
  }
}
