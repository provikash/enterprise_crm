import '../entities/lead_draft.dart';
import '../entities/lead_ingestion_result.dart';
import '../entities/lead_query.dart';
import '../entities/lead_source.dart';
import '../entities/meta_leadgen_payload.dart';
import '../repositories/lead_repository.dart';

/// Ingestion service handling Meta (Facebook / Instagram) Leadgen Webhook events.
class MetaLeadgenIngestionService {
  final LeadRepository _repository;
  final String? _verifyToken;

  const MetaLeadgenIngestionService({
    required LeadRepository repository,
    String? verifyToken,
  })  : _repository = repository,
        _verifyToken = verifyToken;

  /// Verifies Meta Webhook setup challenge (GET webhook handshake).
  String? verifyWebhookChallenge({
    required String mode,
    required String token,
    required String challenge,
  }) {
    if (mode == 'subscribe' &&
        (_verifyToken == null || token == _verifyToken)) {
      return challenge;
    }
    return null;
  }

  /// Ingests a Meta Leadgen payload.
  Future<LeadIngestionResult> ingest({
    required MetaLeadgenPayload payload,
  }) async {
    if (!payload.isValid) {
      return LeadIngestionResult.failure(
        source: LeadSource.metaCampaign,
        errorMessage:
            'Invalid Meta lead: leadgen_id and at least one contact field are required.',
        externalReferenceId: payload.leadgenId,
      );
    }

    try {
      // Deduplication check via getLeads
      final existingPage = await _repository.getLeads(
        const LeadQuery(source: LeadSource.metaCampaign),
      );
      final isDuplicate = existingPage.items.any(
        (l) => l.metadata?['leadgenId'] == payload.leadgenId.trim(),
      );
      if (isDuplicate) {
        return LeadIngestionResult.failure(
          source: LeadSource.metaCampaign,
          errorMessage:
              'Duplicate Meta Lead: Lead with leadgen_id ${payload.leadgenId} has already been ingested.',
          externalReferenceId: payload.leadgenId,
        );
      }

      final draft = payload.toLeadDraft();
      final created =
          await _repository.createLead(CreateLeadInput(draft: draft));
      return LeadIngestionResult.success(
        lead: created,
        externalReferenceId: payload.leadgenId,
      );
    } catch (e) {
      return LeadIngestionResult.failure(
        source: LeadSource.metaCampaign,
        errorMessage: 'Meta lead ingestion failed: $e',
        externalReferenceId: payload.leadgenId,
      );
    }
  }
}
