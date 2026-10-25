import 'lead.dart';
import 'lead_source.dart';

/// Outcome of an automated inbound lead ingestion operation (Portal or Meta Campaign).
class LeadIngestionResult {
  final bool isSuccess;
  final Lead? lead;
  final LeadSource source;
  final String? errorMessage;
  final String? externalReferenceId;

  const LeadIngestionResult({
    required this.isSuccess,
    required this.source,
    this.lead,
    this.errorMessage,
    this.externalReferenceId,
  });

  LeadIngestionResult.success({
    required this.lead,
    this.externalReferenceId,
  })  : isSuccess = true,
        source = lead?.source ?? LeadSource.manual,
        errorMessage = null;

  const LeadIngestionResult.failure({
    required this.source,
    required this.errorMessage,
    this.externalReferenceId,
  })  : isSuccess = false,
        lead = null;

  @override
  String toString() => isSuccess
      ? 'LeadIngestionResult.success(id: ${lead?.id}, source: $source, ref: $externalReferenceId)'
      : 'LeadIngestionResult.failure(source: $source, error: $errorMessage, ref: $externalReferenceId)';
}
