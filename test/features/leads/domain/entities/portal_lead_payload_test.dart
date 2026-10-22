import 'package:enterprise_crm/features/leads/domain/entities/lead_source.dart';
import 'package:enterprise_crm/features/leads/domain/entities/portal_lead_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PortalLeadPayload', () {
    test('isValid returns true when at least one contact identifier is present', () {
      const payloadWithName = PortalLeadPayload(contactName: 'Rohit Verma');
      expect(payloadWithName.isValid, isTrue);

      const payloadWithPhone = PortalLeadPayload(phone: '+91 9876543210');
      expect(payloadWithPhone.isValid, isTrue);

      const payloadWithEmail = PortalLeadPayload(email: 'rohit@example.com');
      expect(payloadWithEmail.isValid, isTrue);

      const payloadWithBusiness = PortalLeadPayload(businessName: 'Verma Traders');
      expect(payloadWithBusiness.isValid, isTrue);
    });

    test('isValid returns false when all contact fields are empty or whitespace', () {
      const emptyPayload = PortalLeadPayload();
      expect(emptyPayload.isValid, isFalse);

      const whitespacePayload = PortalLeadPayload(
        contactName: '   ',
        phone: '  ',
        email: '',
      );
      expect(whitespacePayload.isValid, isFalse);
    });

    test('toLeadDraft correctly maps fields and sets LeadSource.portal with metadata', () {
      final now = DateTime(2026, 10, 22, 14, 30);
      final payload = PortalLeadPayload(
        contactName: '  Neha Gupta  ',
        businessName: 'Gupta Enterprises',
        phone: '+91 9988776655',
        email: 'neha@gupta.com',
        city: 'Pune',
        state: 'Maharashtra',
        portalName: 'Corporate Website',
        portalUrl: 'https://vinayenterprises.com/contact-us',
        formId: 'rfq_form_2026',
        utmSource: 'google_ads',
        utmMedium: 'cpc',
        utmCampaign: 'diwali_sale',
        submittedAt: now,
        customFields: const {
          'industry': 'Manufacturing',
          'team_size': '50+',
        },
      );

      final draft = payload.toLeadDraft();

      expect(draft.name, 'Neha Gupta');
      expect(draft.businessName, 'Gupta Enterprises');
      expect(draft.phone, '+91 9988776655');
      expect(draft.email, 'neha@gupta.com');
      expect(draft.city, 'Pune');
      expect(draft.state, 'Maharashtra');
      expect(draft.source, LeadSource.portal);
      expect(draft.metadata?['portalName'], 'Corporate Website');
      expect(draft.metadata?['portalUrl'], 'https://vinayenterprises.com/contact-us');
      expect(draft.metadata?['formId'], 'rfq_form_2026');
      expect(draft.metadata?['utmSource'], 'google_ads');
      expect(draft.metadata?['utmMedium'], 'cpc');
      expect(draft.metadata?['utmCampaign'], 'diwali_sale');
      expect(draft.metadata?['submittedAt'], now.toIso8601String());
      expect(draft.metadata?['custom_industry'], 'Manufacturing');
      expect(draft.metadata?['custom_team_size'], '50+');
    });

    test('fromJson and toJson deserialize and serialize properly', () {
      final json = {
        'contact_name': 'Amit Patel',
        'company_name': 'Patel Logistics',
        'phone_number': '+91 9123456789',
        'email_address': 'amit@patellogistics.in',
        'city': 'Ahmedabad',
        'state': 'Gujarat',
        'portal_name': 'Landing Page A',
        'portal_url': 'https://vinayenterprises.com/quote',
        'form_id': 'quote_v1',
        'utm_source': 'linkedin',
        'utm_campaign': 'logistics_reach',
        'submitted_at': '2026-10-22T10:00:00.000Z',
        'custom_fields': {'annual_budget': '50L'},
      };

      final payload = PortalLeadPayload.fromJson(json);

      expect(payload.contactName, 'Amit Patel');
      expect(payload.businessName, 'Patel Logistics');
      expect(payload.phone, '+91 9123456789');
      expect(payload.email, 'amit@patellogistics.in');
      expect(payload.city, 'Ahmedabad');
      expect(payload.state, 'Gujarat');
      expect(payload.portalName, 'Landing Page A');
      expect(payload.formId, 'quote_v1');
      expect(payload.utmSource, 'linkedin');
      expect(payload.customFields['annual_budget'], '50L');

      final serialized = payload.toJson();
      expect(serialized['contactName'], 'Amit Patel');
      expect(serialized['businessName'], 'Patel Logistics');
      expect(serialized['portalName'], 'Landing Page A');
    });
  });
}
