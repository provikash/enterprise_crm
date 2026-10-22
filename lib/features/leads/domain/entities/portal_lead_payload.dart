import 'lead_draft.dart';
import 'lead_source.dart';

/// Represents an inbound lead submission payload from a Web Portal or Landing Page form.
class PortalLeadPayload {
  final String? contactName;
  final String? businessName;
  final String? phone;
  final String? email;
  final String? city;
  final String? state;
  final String? portalName;
  final String? portalUrl;
  final String? formId;
  final String? utmSource;
  final String? utmMedium;
  final String? utmCampaign;
  final DateTime? submittedAt;
  final Map<String, String> customFields;

  const PortalLeadPayload({
    this.contactName,
    this.businessName,
    this.phone,
    this.email,
    this.city,
    this.state,
    this.portalName,
    this.portalUrl,
    this.formId,
    this.utmSource,
    this.utmMedium,
    this.utmCampaign,
    this.submittedAt,
    this.customFields = const {},
  });

  /// True if the payload contains at least one meaningful contact identifier
  bool get isValid =>
      (contactName != null && contactName!.trim().isNotEmpty) ||
      (phone != null && phone!.trim().isNotEmpty) ||
      (email != null && email!.trim().isNotEmpty) ||
      (businessName != null && businessName!.trim().isNotEmpty);

  /// Converts this inbound portal payload into a normalized [LeadDraft].
  LeadDraft toLeadDraft() {
    final meta = <String, String>{};
    if (portalName != null && portalName!.trim().isNotEmpty) {
      meta['portalName'] = portalName!.trim();
    }
    if (portalUrl != null && portalUrl!.trim().isNotEmpty) {
      meta['portalUrl'] = portalUrl!.trim();
    }
    if (formId != null && formId!.trim().isNotEmpty) {
      meta['formId'] = formId!.trim();
    }
    if (utmSource != null && utmSource!.trim().isNotEmpty) {
      meta['utmSource'] = utmSource!.trim();
    }
    if (utmMedium != null && utmMedium!.trim().isNotEmpty) {
      meta['utmMedium'] = utmMedium!.trim();
    }
    if (utmCampaign != null && utmCampaign!.trim().isNotEmpty) {
      meta['utmCampaign'] = utmCampaign!.trim();
    }
    if (submittedAt != null) {
      meta['submittedAt'] = submittedAt!.toIso8601String();
    }
    for (final entry in customFields.entries) {
      if (entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty) {
        meta['custom_${entry.key.trim()}'] = entry.value.trim();
      }
    }

    return LeadDraft(
      name: contactName?.trim().isNotEmpty == true ? contactName!.trim() : null,
      businessName: businessName?.trim().isNotEmpty == true
          ? businessName!.trim()
          : null,
      phone: phone?.trim().isNotEmpty == true ? phone!.trim() : null,
      email: email?.trim().isNotEmpty == true ? email!.trim() : null,
      city: city?.trim().isNotEmpty == true ? city!.trim() : null,
      state: state?.trim().isNotEmpty == true ? state!.trim() : null,
      source: LeadSource.portal,
      metadata: Map.unmodifiable(meta),
    );
  }

  factory PortalLeadPayload.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final dateRaw = json['submittedAt'] ?? json['submitted_at'] ?? json['timestamp'];
    if (dateRaw is String) {
      parsedDate = DateTime.tryParse(dateRaw);
    } else if (dateRaw is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(dateRaw);
    }

    final rawCustom = json['customFields'] ?? json['custom_fields'];
    final customMap = <String, String>{};
    if (rawCustom is Map) {
      for (final e in rawCustom.entries) {
        customMap[e.key.toString()] = e.value?.toString() ?? '';
      }
    }

    return PortalLeadPayload(
      contactName: json['contactName'] ?? json['contact_name'] ?? json['name'] ?? json['full_name'],
      businessName: json['businessName'] ?? json['business_name'] ?? json['company'] ?? json['company_name'],
      phone: json['phone'] ?? json['phone_number'] ?? json['mobile'],
      email: json['email'] ?? json['email_id'] ?? json['email_address'],
      city: json['city'],
      state: json['state'],
      portalName: json['portalName'] ?? json['portal_name'] ?? json['site_name'],
      portalUrl: json['portalUrl'] ?? json['portal_url'] ?? json['page_url'] ?? json['url'],
      formId: json['formId'] ?? json['form_id'],
      utmSource: json['utmSource'] ?? json['utm_source'],
      utmMedium: json['utmMedium'] ?? json['utm_medium'],
      utmCampaign: json['utmCampaign'] ?? json['utm_campaign'],
      submittedAt: parsedDate,
      customFields: Map.unmodifiable(customMap),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (contactName != null) 'contactName': contactName,
      if (businessName != null) 'businessName': businessName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (portalName != null) 'portalName': portalName,
      if (portalUrl != null) 'portalUrl': portalUrl,
      if (formId != null) 'formId': formId,
      if (utmSource != null) 'utmSource': utmSource,
      if (utmMedium != null) 'utmMedium': utmMedium,
      if (utmCampaign != null) 'utmCampaign': utmCampaign,
      if (submittedAt != null) 'submittedAt': submittedAt!.toIso8601String(),
      if (customFields.isNotEmpty) 'customFields': customFields,
    };
  }
}
