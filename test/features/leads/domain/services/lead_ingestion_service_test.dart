import 'package:enterprise_crm/features/leads/data/datasources/mock_lead_data_source.dart';
import 'package:enterprise_crm/features/leads/data/repositories/mock_lead_repository.dart';
import 'package:enterprise_crm/features/leads/domain/entities/lead_source.dart';
import 'package:enterprise_crm/features/leads/domain/entities/meta_leadgen_payload.dart';
import 'package:enterprise_crm/features/leads/domain/entities/portal_lead_payload.dart';
import 'package:enterprise_crm/features/leads/domain/services/meta_leadgen_ingestion_service.dart';
import 'package:enterprise_crm/features/leads/domain/services/portal_lead_ingestion_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockLeadDataSource dataSource;
  late MockLeadRepository repository;
  late PortalLeadIngestionService portalService;
  late MetaLeadgenIngestionService metaService;

  setUp(() {
    dataSource = MockLeadDataSource();
    repository = MockLeadRepository(dataSource: dataSource);
    portalService = PortalLeadIngestionService(
      repository: repository,
      expectedSecretKey: 'portal_secret_123',
    );
    metaService = MetaLeadgenIngestionService(
      repository: repository,
      verifyToken: 'meta_verify_token_abc',
    );
  });

  group('PortalLeadIngestionService', () {
    test('successfully ingests valid portal lead and generates clean LEAD- prefix', () async {
      const payload = PortalLeadPayload(
        contactName: 'Nisha Mehra',
        businessName: 'Mehra Exports',
        phone: '+91 9888877777',
        email: 'nisha@mehraexports.com',
        city: 'Jaipur',
        state: 'Rajasthan',
        portalName: 'Corporate Website',
        formId: 'inquiry_v1',
      );

      final result = await portalService.ingest(
        payload: payload,
        providedSecretKey: 'portal_secret_123',
      );

      expect(result.isSuccess, isTrue);
      expect(result.source, LeadSource.portal);
      expect(result.lead, isNotNull);
      expect(result.lead!.id, startsWith('LEAD-'));
      expect(result.lead!.name, 'Nisha Mehra');
      expect(result.lead!.businessName, 'Mehra Exports');
      expect(result.lead!.source, LeadSource.portal);
      expect(result.lead!.metadata?['portalName'], 'Corporate Website');
      expect(result.externalReferenceId, 'inquiry_v1');

      // Verify repository summary increments portalLeads
      final summary = await repository.getLeadSummary();
      expect(summary.portalLeads, 1);
    });

    test('rejects portal ingestion when secret key does not match', () async {
      const payload = PortalLeadPayload(contactName: 'Unauthorized Lead');

      final result = await portalService.ingest(
        payload: payload,
        providedSecretKey: 'wrong_secret',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Invalid Portal Secret Key'));
      expect(result.lead, isNull);
    });

    test('rejects portal ingestion when payload has no contact info', () async {
      const emptyPayload = PortalLeadPayload();

      final result = await portalService.ingest(
        payload: emptyPayload,
        providedSecretKey: 'portal_secret_123',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('At least one contact field'));
      expect(result.lead, isNull);
    });
  });

  group('MetaLeadgenIngestionService', () {
    test('verifies Meta webhook challenge correctly', () {
      final challenge = metaService.verifyWebhookChallenge(
        mode: 'subscribe',
        token: 'meta_verify_token_abc',
        challenge: '1158201244',
      );
      expect(challenge, '1158201244');

      final invalidChallenge = metaService.verifyWebhookChallenge(
        mode: 'subscribe',
        token: 'wrong_token',
        challenge: '1158201244',
      );
      expect(invalidChallenge, isNull);
    });

    test('successfully ingests valid Meta Lead Ads payload', () async {
      const payload = MetaLeadgenPayload(
        leadgenId: 'meta_lg_1001',
        formId: 'meta_form_2002',
        campaignName: 'Summer Enterprise Promo',
        fieldData: {
          'full_name': 'Karan Johar',
          'company_name': 'Dharma Productions',
          'phone_number': '+91 9999900000',
          'email': 'karan@dharma.com',
          'city': 'Mumbai',
        },
      );

      final result = await metaService.ingest(payload: payload);

      expect(result.isSuccess, isTrue);
      expect(result.source, LeadSource.metaCampaign);
      expect(result.lead, isNotNull);
      expect(result.lead!.id, startsWith('LEAD-'));
      expect(result.lead!.name, 'Karan Johar');
      expect(result.lead!.businessName, 'Dharma Productions');
      expect(result.lead!.metadata?['leadgenId'], 'meta_lg_1001');
      expect(result.lead!.metadata?['campaignName'], 'Summer Enterprise Promo');

      final summary = await repository.getLeadSummary();
      expect(summary.metaCampaignLeads, 1);
    });

    test('deduplicates Meta leads with identical leadgenId', () async {
      const payload = MetaLeadgenPayload(
        leadgenId: 'meta_lg_unique_456',
        formId: 'meta_form_2002',
        fieldData: {
          'full_name': 'First Submission',
          'phone_number': '+91 9876543210',
        },
      );

      final firstResult = await metaService.ingest(payload: payload);
      expect(firstResult.isSuccess, isTrue);

      final secondResult = await metaService.ingest(payload: payload);
      expect(secondResult.isSuccess, isFalse);
      expect(secondResult.errorMessage, contains('Duplicate Meta Lead'));
      expect(secondResult.errorMessage, contains('meta_lg_unique_456'));
    });

    test('rejects Meta ingestion when payload is invalid', () async {
      const invalidPayload = MetaLeadgenPayload(
        leadgenId: '',
        formId: 'meta_form_2002',
        fieldData: {},
      );

      final result = await metaService.ingest(payload: invalidPayload);
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Invalid Meta lead'));
    });
  });
}
