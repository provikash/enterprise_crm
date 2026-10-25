import 'lead_draft.dart';
import 'lead_source.dart';

/// Represents an inbound lead submission from any Ad Funnel (Meta Ads, Google Ads,
/// LinkedIn Ads, TikTok, or generic webhook integrations).
class MetaLeadgenPayload {
  final String leadgenId;
  final String formId;
  final String platform;
  final String? pageId;
  final String? campaignId;
  final String? campaignName;
  final String? adId;
  final String? adName;
  final String? adsetId;
  final String? adsetName;
  final DateTime? createdTime;
  final Map<String, String> fieldData;

  const MetaLeadgenPayload({
    required this.leadgenId,
    required this.formId,
    this.platform = 'Ad Funnels',
    this.pageId,
    this.campaignId,
    this.campaignName,
    this.adId,
    this.adName,
    this.adsetId,
    this.adsetName,
    this.createdTime,
    this.fieldData = const {},
  });

  /// Alias for leadgenId for multi-platform ad funnels.
  String get leadId => leadgenId;

  /// Valid if leadgenId is not empty and at least one contact field is present
  bool get isValid {
    if (leadgenId.trim().isEmpty) return false;
    final name = resolveField(['full_name', 'name', 'first_name', 'contact_name', 'contact_person']);
    final phone = resolveField(['phone_number', 'phone', 'mobile', 'mobile_number', 'contact_number']);
    final email = resolveField(['email', 'email_address', 'work_email']);
    final company = resolveField(['company_name', 'business_name', 'company', 'organization', 'firm']);
    return (name != null && name.isNotEmpty) ||
        (phone != null && phone.isNotEmpty) ||
        (email != null && email.isNotEmpty) ||
        (company != null && company.isNotEmpty);
  }

  /// Helper to resolve a field by trying multiple candidate question keys across ad networks
  String? resolveField(List<String> candidates) {
    for (final c in candidates) {
      final val = fieldData[c] ??
          fieldData[c.toLowerCase()] ??
          fieldData[c.toUpperCase()];
      if (val != null && val.trim().isNotEmpty) {
        return val.trim();
      }
    }
    return null;
  }

  /// Converts Ad Funnel payload into a normalized [LeadDraft].
  LeadDraft toLeadDraft() {
    final contactName = resolveField(['full_name', 'name', 'first_name', 'contact_name', 'contact_person']);
    final businessName = resolveField(['company_name', 'business_name', 'company', 'organization', 'firm']);
    final phone = resolveField(['phone_number', 'phone', 'mobile_number', 'mobile', 'contact_number']);
    final email = resolveField(['email', 'email_address', 'work_email']);
    final city = resolveField(['city', 'location_city', 'town', 'district']);
    final state = resolveField(['state', 'province', 'region']);

    final meta = <String, String>{
      'platform': platform.trim().isNotEmpty ? platform.trim() : 'Ad Funnels',
      'leadId': leadgenId.trim(),
      'leadgenId': leadgenId.trim(),
      'formId': formId.trim(),
    };
    if (campaignName != null && campaignName!.trim().isNotEmpty) {
      meta['campaignName'] = campaignName!.trim();
    }
    if (campaignId != null && campaignId!.trim().isNotEmpty) {
      meta['campaignId'] = campaignId!.trim();
    }
    if (adName != null && adName!.trim().isNotEmpty) {
      meta['adName'] = adName!.trim();
    }
    if (adId != null && adId!.trim().isNotEmpty) {
      meta['adId'] = adId!.trim();
    }
    if (adsetName != null && adsetName!.trim().isNotEmpty) {
      meta['adsetName'] = adsetName!.trim();
    }
    if (pageId != null && pageId!.trim().isNotEmpty) {
      meta['pageId'] = pageId!.trim();
    }
    if (createdTime != null) {
      meta['createdTime'] = createdTime!.toIso8601String();
    }

    return LeadDraft(
      name: contactName,
      businessName: businessName,
      phone: phone,
      email: email,
      city: city,
      state: state,
      source: LeadSource.metaCampaign,
      metadata: Map.unmodifiable(meta),
    );
  }

  factory MetaLeadgenPayload.fromJson(Map<String, dynamic> json) {
    DateTime? parsedTime;
    final rawTime = json['created_time'] ?? json['createdTime'] ?? json['timestamp'];
    if (rawTime is String) {
      parsedTime = DateTime.tryParse(rawTime);
    } else if (rawTime is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(
        rawTime > 10000000000 ? rawTime : rawTime * 1000,
      );
    }

    final fields = <String, String>{};
    String detectedPlatform = json['platform']?.toString() ?? '';

    // 1. Google Ads Lead Form webhook format:
    // {"lead_id": "...", "form_id": "...", "user_column_data": [{"column_id": "FULL_NAME", "string_value": "..."}]}
    final userColumnData = json['user_column_data'] ?? json['userColumnData'];
    if (userColumnData is List) {
      if (detectedPlatform.isEmpty) detectedPlatform = 'Google Ads';
      for (final col in userColumnData) {
        if (col is Map) {
          final colId = (col['column_id'] ?? col['columnId'] ?? '').toString().toLowerCase();
          final val = (col['string_value'] ?? col['stringValue'] ?? col['value'] ?? '').toString();
          if (colId.isNotEmpty) {
            fields[colId] = val;
          }
        }
      }
    }

    // 2. Standard Meta Webhook format:
    // {"field_data": [{"name": "full_name", "values": ["Vinay Sharma"]}]}
    final rawFieldData = json['field_data'] ?? json['fieldData'];
    if (rawFieldData is List) {
      if (detectedPlatform.isEmpty) detectedPlatform = 'Meta Ads';
      for (final item in rawFieldData) {
        if (item is Map) {
          final name = item['name']?.toString() ?? '';
          final values = item['values'];
          if (name.isNotEmpty && values is List && values.isNotEmpty) {
            fields[name] = values.first?.toString() ?? '';
          }
        }
      }
    } else if (rawFieldData is Map) {
      for (final e in rawFieldData.entries) {
        fields[e.key.toString()] = e.value?.toString() ?? '';
      }
    }

    // 3. LinkedIn Lead Gen webhook format:
    // {"form_response": {"answers": [{"question_name": "...", "answer": "..."}]}}
    final formResponse = json['form_response'] ?? json['formResponse'];
    if (formResponse is Map && formResponse['answers'] is List) {
      if (detectedPlatform.isEmpty) detectedPlatform = 'LinkedIn Ads';
      for (final ans in formResponse['answers']) {
        if (ans is Map) {
          final qName = (ans['question_name'] ?? ans['questionName'] ?? ans['key'] ?? '').toString();
          final ansVal = (ans['answer'] ?? ans['value'] ?? '').toString();
          if (qName.isNotEmpty) fields[qName] = ansVal;
        }
      }
    }

    // 4. Flat / generic ad webhook format fallback:
    // e.g. {"name": "...", "phone": "...", "email": "...", "company": "..."}
    for (final e in json.entries) {
      final k = e.key.toLowerCase();
      if (!fields.containsKey(k) &&
          e.value != null &&
          e.value is! Map &&
          e.value is! List) {
        fields[k] = e.value.toString();
      }
    }

    if (detectedPlatform.isEmpty) {
      detectedPlatform = 'Ad Funnels';
    }

    final resolvedId = (json['lead_id'] ??
            json['leadId'] ??
            json['leadgen_id'] ??
            json['leadgenId'] ??
            json['id'] ??
            '')
        .toString();

    final resolvedFormId = (json['form_id'] ??
            json['formId'] ??
            json['form_name'] ??
            'ad_funnel_form')
        .toString();

    return MetaLeadgenPayload(
      leadgenId: resolvedId,
      formId: resolvedFormId,
      platform: detectedPlatform,
      pageId: json['page_id']?.toString() ?? json['pageId']?.toString(),
      campaignId: json['campaign_id']?.toString() ?? json['campaignId']?.toString(),
      campaignName: json['campaign_name']?.toString() ?? json['campaignName']?.toString(),
      adId: json['ad_id']?.toString() ?? json['adId']?.toString(),
      adName: json['ad_name']?.toString() ?? json['adName']?.toString(),
      adsetId: json['adset_id']?.toString() ?? json['adsetId']?.toString(),
      adsetName: json['adset_name']?.toString() ?? json['adsetName']?.toString(),
      createdTime: parsedTime,
      fieldData: Map.unmodifiable(fields),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'lead_id': leadgenId,
      'leadgen_id': leadgenId,
      'form_id': formId,
      if (pageId != null) 'page_id': pageId,
      if (campaignId != null) 'campaign_id': campaignId,
      if (campaignName != null) 'campaign_name': campaignName,
      if (adId != null) 'ad_id': adId,
      if (adName != null) 'ad_name': adName,
      if (adsetId != null) 'adset_id': adsetId,
      if (adsetName != null) 'adset_name': adsetName,
      if (createdTime != null) 'created_time': createdTime!.toIso8601String(),
      'field_data': fieldData,
    };
  }
}

/// Generalized type alias so instructors and integrations can use either name.
typedef AdFunnelLeadPayload = MetaLeadgenPayload;
