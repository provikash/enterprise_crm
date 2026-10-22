import 'package:enterprise_crm/features/leads/domain/entities/lead_source.dart';
import 'package:enterprise_crm/features/leads/domain/entities/meta_leadgen_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MetaLeadgenPayload', () {
    test('isValid validates leadgenId and contact fields', () {
      const validPayload = MetaLeadgenPayload(
        leadgenId: 'meta_123',
        formId: 'form_456',
        fieldData: {'full_name': 'Kavita Singh'},
      );
      expect(validPayload.isValid, isTrue);

      const emptyIdPayload = MetaLeadgenPayload(
        leadgenId: '',
        formId: 'form_456',
        fieldData: {'full_name': 'Kavita Singh'},
      );
      expect(emptyIdPayload.isValid, isFalse);

      const noContactFieldsPayload = MetaLeadgenPayload(
        leadgenId: 'meta_123',
        formId: 'form_456',
        fieldData: {},
      );
      expect(noContactFieldsPayload.isValid, isFalse);
    });

    test('toLeadDraft correctly maps standard Meta questions to LeadDraft fields', () {
      final now = DateTime(2026, 10, 22, 12, 0);
      final payload = MetaLeadgenPayload(
        leadgenId: 'meta_lg_987654321',
        formId: 'form_festive_leadgen',
        campaignId: 'camp_554433',
        campaignName: 'Diwali B2B Promotion 2026',
        adId: 'ad_112233',
        adName: 'Video Ad #3 Carousel',
        adsetId: 'adset_778899',
        pageId: 'page_990011',
        createdTime: now,
        fieldData: const {
          'full_name': 'Sanjay Singhania',
          'company_name': 'Singhania Textiles',
          'phone_number': '+91 9822001122',
          'email': 'sanjay@singhaniatex.com',
          'city': 'Surat',
          'state': 'Gujarat',
        },
      );

      final draft = payload.toLeadDraft();

      expect(draft.name, 'Sanjay Singhania');
      expect(draft.businessName, 'Singhania Textiles');
      expect(draft.phone, '+91 9822001122');
      expect(draft.email, 'sanjay@singhaniatex.com');
      expect(draft.city, 'Surat');
      expect(draft.state, 'Gujarat');
      expect(draft.source, LeadSource.metaCampaign);
      expect(draft.metadata?['leadgenId'], 'meta_lg_987654321');
      expect(draft.metadata?['formId'], 'form_festive_leadgen');
      expect(draft.metadata?['campaignName'], 'Diwali B2B Promotion 2026');
      expect(draft.metadata?['campaignId'], 'camp_554433');
      expect(draft.metadata?['adName'], 'Video Ad #3 Carousel');
      expect(draft.metadata?['adId'], 'ad_112233');
      expect(draft.metadata?['pageId'], 'page_990011');
      expect(draft.metadata?['createdTime'], now.toIso8601String());
    });

    test('fromJson parses official Meta Graph API field_data array format', () {
      final json = {
        'leadgen_id': 'meta_lead_abc123',
        'form_id': 'meta_form_xyz789',
        'campaign_id': 'camp_001',
        'campaign_name': 'Real Estate Q4 Launch',
        'ad_id': 'ad_555',
        'ad_name': 'Image Ad Banner',
        'created_time': '2026-10-22T08:30:00.000Z',
        'field_data': [
          {
            'name': 'full_name',
            'values': ['Vikram Malhotra'],
          },
          {
            'name': 'phone_number',
            'values': ['+91 9765432100'],
          },
          {
            'name': 'email',
            'values': ['vikram.m@domain.com'],
          },
          {
            'name': 'company_name',
            'values': ['Malhotra Holdings'],
          },
          {
            'name': 'city',
            'values': ['Bengaluru'],
          },
        ],
      };

      final payload = MetaLeadgenPayload.fromJson(json);

      expect(payload.leadgenId, 'meta_lead_abc123');
      expect(payload.formId, 'meta_form_xyz789');
      expect(payload.campaignName, 'Real Estate Q4 Launch');
      expect(payload.fieldData['full_name'], 'Vikram Malhotra');
      expect(payload.fieldData['phone_number'], '+91 9765432100');
      expect(payload.fieldData['email'], 'vikram.m@domain.com');
      expect(payload.fieldData['company_name'], 'Malhotra Holdings');
      expect(payload.fieldData['city'], 'Bengaluru');

      final draft = payload.toLeadDraft();
      expect(draft.name, 'Vikram Malhotra');
      expect(draft.businessName, 'Malhotra Holdings');
      expect(draft.phone, '+91 9765432100');
      expect(draft.email, 'vikram.m@domain.com');
      expect(draft.city, 'Bengaluru');
      expect(draft.source, LeadSource.metaCampaign);
    });
  });
}
