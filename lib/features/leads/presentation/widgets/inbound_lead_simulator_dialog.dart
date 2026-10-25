import 'package:flutter/material.dart';

import '../../domain/entities/lead.dart';
import '../../domain/entities/meta_leadgen_payload.dart';
import '../../domain/entities/portal_lead_payload.dart';
import '../../domain/repositories/lead_repository.dart';
import '../../domain/services/meta_leadgen_ingestion_service.dart';
import '../../domain/services/portal_lead_ingestion_service.dart';

/// Modal dialog allowing administrators to simulate inbound lead submissions
/// from external channels (Meta Lead Ads and Web Portal Forms).
class InboundLeadSimulatorDialog extends StatefulWidget {
  final LeadRepository repository;
  final void Function(Lead lead)? onLeadCreated;

  const InboundLeadSimulatorDialog({
    super.key,
    required this.repository,
    this.onLeadCreated,
  });

  static Future<Lead?> show(
    BuildContext context, {
    required LeadRepository repository,
    void Function(Lead lead)? onLeadCreated,
  }) {
    return showDialog<Lead>(
      context: context,
      builder: (context) => InboundLeadSimulatorDialog(
        repository: repository,
        onLeadCreated: onLeadCreated,
      ),
    );
  }

  @override
  State<InboundLeadSimulatorDialog> createState() =>
      _InboundLeadSimulatorDialogState();
}

class _InboundLeadSimulatorDialogState
    extends State<InboundLeadSimulatorDialog> {
  int _selectedTab = 0; // 0 = Ad Funnels, 1 = Web Portal
  bool _isSubmitting = false;
  String? _errorMessage;
  String _selectedPlatform = 'Meta Ads';

  // Ad Funnel Form Controllers
  final _metaNameController =
      TextEditingController(text: 'Suresh Raina');
  final _metaBusinessController =
      TextEditingController(text: 'Raina Sports & Fitness');
  final _metaPhoneController =
      TextEditingController(text: '+91 9876543000');
  final _metaEmailController =
      TextEditingController(text: 'suresh@rainasports.in');
  final _metaCityController = TextEditingController(text: 'Kanpur');
  final _metaStateController = TextEditingController(text: 'Uttar Pradesh');
  final _metaCampaignNameController =
      TextEditingController(text: 'Diwali Festive B2B Acquisition');
  final _metaAdNameController =
      TextEditingController(text: 'Carousel Video Ad #2');
  final _metaFormIdController =
      TextEditingController(text: 'meta_form_festive_2026');

  // Web Portal Form Controllers
  final _portalNameController =
      TextEditingController(text: 'Ananya Deshmukh');
  final _portalBusinessController =
      TextEditingController(text: 'Deshmukh Agro Foods');
  final _portalPhoneController =
      TextEditingController(text: '+91 9823456780');
  final _portalEmailController =
      TextEditingController(text: 'ananya@deshmukhagro.com');
  final _portalCityController = TextEditingController(text: 'Nagpur');
  final _portalStateController = TextEditingController(text: 'Maharashtra');
  final _portalSiteNameController =
      TextEditingController(text: 'Corporate Website');
  final _portalUrlController = TextEditingController(
      text: 'https://vinayenterprises.com/enquiry');
  final _portalFormIdController =
      TextEditingController(text: 'contact_rfq_v1');
  final _portalUtmSourceController =
      TextEditingController(text: 'google_ads');
  final _portalUtmCampaignController =
      TextEditingController(text: 'b2b_monsoon_expansion');

  @override
  void dispose() {
    _metaNameController.dispose();
    _metaBusinessController.dispose();
    _metaPhoneController.dispose();
    _metaEmailController.dispose();
    _metaCityController.dispose();
    _metaStateController.dispose();
    _metaCampaignNameController.dispose();
    _metaAdNameController.dispose();
    _metaFormIdController.dispose();

    _portalNameController.dispose();
    _portalBusinessController.dispose();
    _portalPhoneController.dispose();
    _portalEmailController.dispose();
    _portalCityController.dispose();
    _portalStateController.dispose();
    _portalSiteNameController.dispose();
    _portalUrlController.dispose();
    _portalFormIdController.dispose();
    _portalUtmSourceController.dispose();
    _portalUtmCampaignController.dispose();
    super.dispose();
  }

  Future<void> _submitMeta() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final metaService = MetaLeadgenIngestionService(repository: widget.repository);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final compactId = 'AF-${((timestamp % 9000) + 1000)}';
    final payload = MetaLeadgenPayload(
      leadgenId: compactId,
      platform: _selectedPlatform,
      formId: _metaFormIdController.text.trim().isEmpty
          ? 'form_ad_funnel'
          : _metaFormIdController.text.trim(),
      campaignName: _metaCampaignNameController.text.trim(),
      campaignId: 'camp_${timestamp.toString().substring(8)}',
      adName: _metaAdNameController.text.trim(),
      adId: 'ad_${timestamp.toString().substring(9)}',
      createdTime: DateTime.now(),
      fieldData: {
        'full_name': _metaNameController.text.trim(),
        'company_name': _metaBusinessController.text.trim(),
        'phone_number': _metaPhoneController.text.trim(),
        'email': _metaEmailController.text.trim(),
        'city': _metaCityController.text.trim(),
        'state': _metaStateController.text.trim(),
      },
    );

    final result = await metaService.ingest(payload: payload);
    if (!mounted) return;

    if (result.isSuccess && result.lead != null) {
      widget.onLeadCreated?.call(result.lead!);
      Navigator.of(context).pop(result.lead);
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = result.errorMessage ?? 'Ad funnel lead ingestion failed.';
      });
    }
  }

  Future<void> _submitPortal() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final portalService =
        PortalLeadIngestionService(repository: widget.repository);
    final payload = PortalLeadPayload(
      contactName: _portalNameController.text.trim(),
      businessName: _portalBusinessController.text.trim(),
      phone: _portalPhoneController.text.trim(),
      email: _portalEmailController.text.trim(),
      city: _portalCityController.text.trim(),
      state: _portalStateController.text.trim(),
      portalName: _portalSiteNameController.text.trim(),
      portalUrl: _portalUrlController.text.trim(),
      formId: _portalFormIdController.text.trim(),
      utmSource: _portalUtmSourceController.text.trim(),
      utmCampaign: _portalUtmCampaignController.text.trim(),
      submittedAt: DateTime.now(),
    );

    final result = await portalService.ingest(payload: payload);
    if (!mounted) return;

    if (result.isSuccess && result.lead != null) {
      widget.onLeadCreated?.call(result.lead!);
      Navigator.of(context).pop(result.lead);
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = result.errorMessage ?? 'Portal lead ingestion failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      key: const Key('inbound_lead_simulator_dialog'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    child: const Icon(Icons.hub_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Simulate Inbound Lead',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Simulate live leads from Ad Funnels or Web Portal',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Channel Selector Tabs
              SegmentedButton<int>(
                key: const Key('simulator_channel_segmented_button'),
                segments: const [
                  ButtonSegment<int>(
                    value: 0,
                    label: Text('Ad Funnels'),
                    icon: Icon(Icons.campaign_outlined),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    label: Text('Web Portal'),
                    icon: Icon(Icons.language_outlined),
                  ),
                ],
                selected: {_selectedTab},
                onSelectionChanged: _isSubmitting
                    ? null
                    : (newSet) {
                        setState(() {
                          _selectedTab = newSet.first;
                          _errorMessage = null;
                        });
                      },
              ),
              const SizedBox(height: 16),

              // Error banner if any
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          size: 18, color: colorScheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Form content
              Expanded(
                child: SingleChildScrollView(
                  child: _selectedTab == 0
                      ? _buildMetaForm(theme, colorScheme)
                      : _buildPortalForm(theme, colorScheme),
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    key: const Key('simulator_submit_button'),
                    onPressed: _isSubmitting
                        ? null
                        : (_selectedTab == 0 ? _submitMeta : _submitPortal),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(_selectedTab == 0
                            ? Icons.campaign
                            : Icons.language),
                    label: Text(
                      _isSubmitting
                          ? 'Ingesting...'
                          : (_selectedTab == 0
                              ? 'Ingest Ad Funnel Lead'
                              : 'Ingest Portal Lead'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaForm(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Lead Contact Information', theme, colorScheme),
        const SizedBox(height: 8),
        TextFormField(
          key: const Key('meta_name_input'),
          controller: _metaNameController,
          enabled: !_isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Full Name (Contact)',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          key: const Key('meta_business_input'),
          controller: _metaBusinessController,
          enabled: !_isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Business / Company Name',
            prefixIcon: Icon(Icons.business_outlined),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: const Key('meta_phone_input'),
                controller: _metaPhoneController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                key: const Key('meta_email_input'),
                controller: _metaEmailController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: const Key('meta_city_input'),
                controller: _metaCityController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_city_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                key: const Key('meta_state_input'),
                controller: _metaStateController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'State',
                  prefixIcon: Icon(Icons.map_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Ad Funnel Attribution', theme, colorScheme),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: const Key('ad_funnel_platform_dropdown'),
          initialValue: _selectedPlatform,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Ad Network / Funnel',
            prefixIcon: Icon(Icons.hub_outlined),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: 'Meta Ads', child: Text('Meta Ads')),
            DropdownMenuItem(value: 'Google Ads', child: Text('Google Ads')),
            DropdownMenuItem(value: 'LinkedIn Ads', child: Text('LinkedIn Ads')),
            DropdownMenuItem(value: 'YouTube Ads', child: Text('YouTube Ads')),
            DropdownMenuItem(value: 'Custom Webhook', child: Text('Custom Webhook')),
          ],
          onChanged: _isSubmitting
              ? null
              : (val) {
                  if (val != null) {
                    setState(() {
                      _selectedPlatform = val;
                      if (val == 'Google Ads') {
                        _metaCampaignNameController.text = 'B2B Search High-Intent';
                        _metaAdNameController.text = 'Responsive Search Ad #1';
                        _metaFormIdController.text = 'google_form_lead_01';
                      } else if (val == 'Meta Ads') {
                        _metaCampaignNameController.text = 'Diwali Festive B2B Acquisition';
                        _metaAdNameController.text = 'Carousel Video Ad #2';
                        _metaFormIdController.text = 'meta_form_festive_2026';
                      } else if (val == 'LinkedIn Ads') {
                        _metaCampaignNameController.text = 'Enterprise Decision Makers';
                        _metaAdNameController.text = 'Sponsored InMail Lead Form';
                        _metaFormIdController.text = 'li_lead_rfq';
                      } else if (val == 'YouTube Ads') {
                        _metaCampaignNameController.text = 'B2B Video Action Campaign';
                        _metaAdNameController.text = 'TrueView In-Stream Ad #3';
                        _metaFormIdController.text = 'yt_lead_form_01';
                      }
                    });
                  }
                },
        ),
        const SizedBox(height: 10),
        TextFormField(
          key: const Key('meta_campaign_name_input'),
          controller: _metaCampaignNameController,
          enabled: !_isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Campaign Name',
            prefixIcon: Icon(Icons.campaign_outlined),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          key: const Key('meta_ad_name_input'),
          controller: _metaAdNameController,
          enabled: !_isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Ad Name / Creative',
            prefixIcon: Icon(Icons.ad_units_outlined),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          key: const Key('meta_form_id_input'),
          controller: _metaFormIdController,
          enabled: !_isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Instant Form ID',
            prefixIcon: Icon(Icons.dynamic_form_outlined),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildPortalForm(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Lead Contact Information', theme, colorScheme),
        const SizedBox(height: 8),
        TextFormField(
          key: const Key('portal_name_input'),
          controller: _portalNameController,
          enabled: !_isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Contact Person Name',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          key: const Key('portal_business_input'),
          controller: _portalBusinessController,
          enabled: !_isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Business / Company Name',
            prefixIcon: Icon(Icons.business_outlined),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: const Key('portal_phone_input'),
                controller: _portalPhoneController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                key: const Key('portal_email_input'),
                controller: _portalEmailController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: const Key('portal_city_input'),
                controller: _portalCityController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_city_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                key: const Key('portal_state_input'),
                controller: _portalStateController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'State',
                  prefixIcon: Icon(Icons.map_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Portal & Form Source', theme, colorScheme),
        const SizedBox(height: 8),
        TextFormField(
          key: const Key('portal_site_name_input'),
          controller: _portalSiteNameController,
          enabled: !_isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Portal / Site Name',
            prefixIcon: Icon(Icons.web_outlined),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          key: const Key('portal_url_input'),
          controller: _portalUrlController,
          enabled: !_isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Submission URL',
            prefixIcon: Icon(Icons.link_outlined),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: const Key('portal_utm_source_input'),
                controller: _portalUtmSourceController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'UTM Source',
                  prefixIcon: Icon(Icons.track_changes_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                key: const Key('portal_utm_campaign_input'),
                controller: _portalUtmCampaignController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'UTM Campaign',
                  prefixIcon: Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
      String title, ThemeData theme, ColorScheme colorScheme) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
      ),
    );
  }
}
