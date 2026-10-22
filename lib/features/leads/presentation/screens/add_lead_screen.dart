import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_draft.dart';
import '../../domain/entities/lead_source.dart';
import '../../domain/repositories/lead_repository.dart';
import '../bloc/lead_form_cubit.dart';
import '../bloc/lead_form_state.dart';
import '../utils/lead_display_formatters.dart';
import '../utils/lead_field_validators.dart';
import '../utils/lead_location_and_source_presets.dart';
import '../widgets/hybrid_dropdown_field.dart';

class AddLeadScreen extends StatelessWidget {
  final LeadFormCubit? cubit;
  final LeadRepository? repository;
  final void Function(Lead lead)? onLeadCreated;
  final VoidCallback? onCancel;

  const AddLeadScreen({
    super.key,
    this.cubit,
    this.repository,
    this.onLeadCreated,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: _AddLeadView(onLeadCreated: onLeadCreated, onCancel: onCancel),
      );
    }

    if (repository != null) {
      return BlocProvider(
        create: (_) => LeadFormCubit(repository!),
        child: _AddLeadView(onLeadCreated: onLeadCreated, onCancel: onCancel),
      );
    }

    return _AddLeadView(onLeadCreated: onLeadCreated, onCancel: onCancel);
  }
}

class _AddLeadView extends StatefulWidget {
  final void Function(Lead lead)? onLeadCreated;
  final VoidCallback? onCancel;

  const _AddLeadView({this.onLeadCreated, this.onCancel});

  @override
  State<_AddLeadView> createState() => _AddLeadViewState();
}

class _AddLeadViewState extends State<_AddLeadView> {
  final _formKey = GlobalKey<FormState>();
  final _contactPersonNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _sourceController = TextEditingController(text: 'Manual Entry');
  LeadSource _selectedSource = LeadSource.manual;

  @override
  void dispose() {
    _contactPersonNameController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _submit() {
    final cubit = context.read<LeadFormCubit>();
    if (cubit.state is LeadFormSubmitting) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _contactPersonNameController.text.trim();
    final businessName = _businessNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final city = _cityController.text.trim();
    final stateVal = _stateController.text.trim();
    final sourceText = _sourceController.text.trim();

    final resolvedSource = resolveLeadSource(
      sourceText.isNotEmpty ? sourceText : _selectedSource.displayName,
    );

    final metadata = <String, String>{};
    if (sourceText.isNotEmpty &&
        sourceText.toLowerCase() != resolvedSource.displayName.toLowerCase() &&
        sourceText.toLowerCase() != resolvedSource.name.toLowerCase()) {
      metadata['source_detail'] = sourceText;
    }

    final draft = LeadDraft(
      name: name.isEmpty ? null : name,
      businessName: businessName.isEmpty ? null : businessName,
      phone: phone.isEmpty ? null : phone,
      email: email.isEmpty ? null : email,
      city: city.isEmpty ? null : city,
      state: stateVal.isEmpty ? null : stateVal,
      source: resolvedSource,
      metadata: metadata.isEmpty ? null : metadata,
    );

    cubit.createLead(draft);
  }

  IconData _sourceIcon(LeadSource source) {
    switch (source) {
      case LeadSource.manual:
        return Icons.edit_note;
      case LeadSource.excel:
        return Icons.table_chart_outlined;
      case LeadSource.csv:
        return Icons.description_outlined;
      case LeadSource.portal:
        return Icons.language_outlined;
      case LeadSource.metaCampaign:
        return Icons.campaign_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Lead'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: _handleCancel,
        ),
      ),
      body: BlocConsumer<LeadFormCubit, LeadFormState>(
        listener: (context, state) {
          if (state is LeadFormSuccess) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lead created successfully'),
                duration: Duration(seconds: 2),
              ),
            );
            widget.onLeadCreated?.call(state.lead);
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          } else if (state is LeadFormFailure) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          final isSubmitting = state is LeadFormSubmitting;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 24 : 16,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isWide ? 24 : 16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Form Header
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: constraints.maxWidth > 80
                                          ? constraints.maxWidth - 48
                                          : 200,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                              colorScheme.primaryContainer,
                                          foregroundColor:
                                              colorScheme.onPrimaryContainer,
                                          child: const Icon(
                                            Icons.person_add_outlined,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'New Lead',
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              Text(
                                                'Lead registration',
                                                style: theme
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Chip(
                                    key: const Key('add_lead_source_badge'),
                                    label: Text(
                                      _sourceController.text.trim().isNotEmpty
                                          ? _sourceController.text.trim()
                                          : formatLeadSource(_selectedSource),
                                    ),
                                    avatar: Icon(
                                      _sourceIcon(_selectedSource),
                                      size: 16,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor:
                                        colorScheme.surfaceContainerHighest,
                                    side: BorderSide.none,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Divider(height: 1),
                              const SizedBox(height: 20),

                              // Failure Banner
                              if (state is LeadFormFailure) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: colorScheme.onErrorContainer,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          state.message,
                                          style: TextStyle(
                                            color: colorScheme.onErrorContainer,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Section: Primary Information
                              Text(
                                'Primary Information',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (isWide) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildContactPersonField(
                                        isSubmitting,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildBusinessNameField(
                                        isSubmitting,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                _buildContactPersonField(isSubmitting),
                                const SizedBox(height: 16),
                                _buildBusinessNameField(isSubmitting),
                              ],
                              const SizedBox(height: 20),

                              // Section: Contact Information
                              Text(
                                'Contact Information',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (isWide) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildPhoneField(isSubmitting),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildEmailField(isSubmitting),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                _buildPhoneField(isSubmitting),
                                const SizedBox(height: 16),
                                _buildEmailField(isSubmitting),
                              ],
                              const SizedBox(height: 20),

                              // Section: Location Information
                              Text(
                                'Location Information',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (isWide) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildCityField(isSubmitting),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildStateField(isSubmitting),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                _buildCityField(isSubmitting),
                                const SizedBox(height: 16),
                                _buildStateField(isSubmitting),
                              ],
                              const SizedBox(height: 20),

                              // Section: Lead Source
                              Text(
                                'Lead Source',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildSourceDropdown(isSubmitting),
                              const SizedBox(height: 28),

                              // Form Actions
                              if (isWide) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      onPressed: isSubmitting
                                          ? null
                                          : _handleCancel,
                                      child: const Text('Cancel'),
                                    ),
                                    const SizedBox(width: 12),
                                    FilledButton.icon(
                                      onPressed: isSubmitting ? null : _submit,
                                      icon: isSubmitting
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.add, size: 18),
                                      label: Text(
                                        isSubmitting
                                            ? 'Creating...'
                                            : 'Create Lead',
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    FilledButton(
                                      onPressed: isSubmitting ? null : _submit,
                                      child: isSubmitting
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child:
                                                  CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                            )
                                          : const Text('Create Lead'),
                                    ),
                                    const SizedBox(height: 10),
                                    OutlinedButton(
                                      onPressed: isSubmitting
                                          ? null
                                          : _handleCancel,
                                      child: const Text('Cancel'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContactPersonField(bool isSubmitting) {
    return TextFormField(
      key: const Key('add_lead_contact_person_name_field'),
      controller: _contactPersonNameController,
      enabled: !isSubmitting,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.name,
      decoration: const InputDecoration(
        labelText: 'Contact Person Name',
        hintText: 'e.g. John Doe',
        prefixIcon: Icon(Icons.person_outline),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildBusinessNameField(bool isSubmitting) {
    return TextFormField(
      key: const Key('add_lead_business_name_field'),
      controller: _businessNameController,
      enabled: !isSubmitting,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.text,
      decoration: const InputDecoration(
        labelText: 'Business Name',
        hintText: 'e.g. Acme Enterprises',
        prefixIcon: Icon(Icons.business_outlined),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildPhoneField(bool isSubmitting) {
    return TextFormField(
      key: const Key('add_lead_phone_field'),
      controller: _phoneController,
      enabled: !isSubmitting,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (!isValidOptionalLeadPhone(value)) {
          return 'Enter a valid mobile number (10-15 digits)';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Phone Number',
        hintText: 'e.g. +91 9876543210',
        prefixIcon: Icon(Icons.phone_outlined),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildEmailField(bool isSubmitting) {
    return TextFormField(
      key: const Key('add_lead_email_field'),
      controller: _emailController,
      enabled: !isSubmitting,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (!isValidOptionalLeadEmail(value)) {
          return 'Enter a valid email address';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Email ID',
        hintText: 'e.g. name@example.com',
        prefixIcon: Icon(Icons.email_outlined),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildCityField(bool isSubmitting) {
    return HybridDropdownField(
      fieldKey: const Key('add_lead_city_field'),
      controller: _cityController,
      options: defaultCitySuggestions,
      labelText: 'City',
      hintText: 'e.g. Mumbai or type custom',
      prefixIcon: const Icon(Icons.location_city_outlined),
      enabled: !isSubmitting,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.streetAddress,
    );
  }

  Widget _buildStateField(bool isSubmitting) {
    return HybridDropdownField(
      fieldKey: const Key('add_lead_state_field'),
      controller: _stateController,
      options: defaultStateSuggestions,
      labelText: 'State',
      hintText: 'e.g. Maharashtra or type custom',
      prefixIcon: const Icon(Icons.map_outlined),
      enabled: !isSubmitting,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.text,
    );
  }

  Widget _buildSourceDropdown(bool isSubmitting) {
    return HybridDropdownField(
      fieldKey: const Key('add_lead_source_dropdown'),
      controller: _sourceController,
      options: defaultSourceSuggestions,
      labelText: 'Source',
      hintText: 'e.g. Manual Entry, Meta Campaign or type custom',
      prefixIcon: Icon(_sourceIcon(_selectedSource)),
      enabled: !isSubmitting,
      textInputAction: TextInputAction.done,
      onChanged: (val) {
        setState(() {
          _selectedSource = resolveLeadSource(val);
        });
      },
    );
  }
}
