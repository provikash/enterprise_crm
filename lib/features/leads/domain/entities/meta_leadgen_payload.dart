import 'lead_draft.dart';
import 'lead_source.dart';

/// Represents an inbound lead submission from Meta (Facebook / Instagram) Lead Ads.
class MetaLeadgenPayload {
  final String leadgenId;
  final String formId;
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

  /// Valid if leadgenId is not empty and at least one contact field is present
  bool get isValid {
    if (leadgenId.trim().isEmpty) return false;
    final name = resolveField(['full_name', 'name', 'first_name']);
    final phone = resolveField(['phone_number', 'phone', 'mobile']);
    final email = resolveField(['email', 'email_address']);
    final company = resolveField(['company_name', 'business_name', 'company']);
    return (name != null && name.isNotEmpty) ||
        (phone != null && phone.isNotEmpty) ||
        (email != null && email.isNotEmpty) ||
        (company != null && company.isNotEmpty);
  }

  /// Helper to resolve a field by trying multiple candidate Meta question keys
  String? resolveField(List<String> candidates) {
    for (final c in candidates) {
      final val = fieldData[c] ?? fieldData[c.toLowerCase()];
      if (val != null && val.trim().isNotEmpty) {
        return val.trim();
      }
    }
    return null;
  }

  /// Converts Meta Leadgen payload into a normalized [LeadDraft].
  LeadDraft toLeadDraft() {
    final contactName = resolveField(['full_name', 'name', 'first_name']);
    final businessName = resolveField(['company_name', 'business_name', 'company', 'organization']);
    final phone = resolveField(['phone_number', 'phone', 'mobile_number', 'mobile']);
    final email = resolveField(['email', 'email_address', 'work_email']);
    final city = resolveField(['city', 'location_city']);
    final state = resolveField(['state', 'province', 'region']);

    final meta = <String, String>{
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
    final rawTime = json['created_time'] ?? json['createdTime'];
    if (rawTime is String) {
      parsedTime = DateTime.tryParse(rawTime);
    } else if (rawTime is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTime * 1000);
    }

    final fields = <String, String>{};
    final rawFieldData = json['field_data'] ?? json['fieldData'];
    if (rawFieldData is List) {
      // Standard Meta Webhook format: [{"name": "full_name", "values": ["Vinay Sharma"]}]
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
      // Flat simulated format: {"full_name": "Vinay Sharma", "email": "..."}
      for (final e in rawFieldData.entries) {
        fields[e.key.toString()] = e.value?.toString() ?? '';
      }
    }

    return MetaLeadgenPayload(
      leadgenId: (json['leadgen_id'] ?? json['leadgenId'] ?? json['id'] ?? '').toString(),
      formId: (json['form_id'] ?? json['formId'] ?? '').toString(),
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
