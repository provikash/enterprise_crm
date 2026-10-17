import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/vendor_record.dart';
import '../../domain/entities/vendor_status.dart';
import '../../domain/repositories/vendor_repository.dart';
import '../bloc/vendor_form_cubit.dart';
import '../bloc/vendor_form_state.dart';

/// Screen for creating or editing a vendor supplier profile.
class CreateEditVendorScreen extends StatefulWidget {
  final VendorRepository repository;
  final VendorRecord? vendor;
  final ValueChanged<VendorRecord>? onSaved;

  const CreateEditVendorScreen({
    super.key,
    required this.repository,
    this.vendor,
    this.onSaved,
  });

  @override
  State<CreateEditVendorScreen> createState() => _CreateEditVendorScreenState();
}

class _CreateEditVendorScreenState extends State<CreateEditVendorScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _companyNameController;
  late final TextEditingController _vendorCodeController;
  late final TextEditingController _contactPersonController;
  late final TextEditingController _phoneController;
  late final TextEditingController _alternatePhoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;
  late final TextEditingController _gstinController;
  late final TextEditingController _panController;
  late final TextEditingController _creditLimitController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _ifscCodeController;
  late final TextEditingController _branchNameController;
  late final TextEditingController _notesController;

  late VendorStatus _status;
  late String _category;
  late String _paymentTerms;
  late double _rating;

  static const List<String> categories = [
    'Electronics',
    'Furniture',
    'Manufacturing',
    'Hardware',
    'Logistics',
    'Chemicals',
    'Packaging',
    'Services',
    'General',
  ];

  static const List<String> termsOptions = [
    'Net 15 Days',
    'Net 30 Days',
    'Net 45 Days',
    'Net 60 Days',
    'Immediate on Receipt',
    '50% Advance, 50% on Delivery',
    'Advance Only',
  ];

  @override
  void initState() {
    super.initState();
    final v = widget.vendor;

    _companyNameController = TextEditingController(text: v?.companyName ?? '');
    _vendorCodeController = TextEditingController(text: v?.vendorCode ?? '');
    _contactPersonController = TextEditingController(text: v?.contactPerson ?? '');
    _phoneController = TextEditingController(text: v?.phone ?? '');
    _alternatePhoneController = TextEditingController(text: v?.alternatePhone ?? '');
    _emailController = TextEditingController(text: v?.email ?? '');
    _addressController = TextEditingController(text: v?.address ?? '');
    _cityController = TextEditingController(text: v?.city ?? '');
    _stateController = TextEditingController(text: v?.state ?? '');
    _pincodeController = TextEditingController(text: v?.pincode ?? '');
    _gstinController = TextEditingController(text: v?.gstin ?? '');
    _panController = TextEditingController(text: v?.pan ?? '');
    _creditLimitController = TextEditingController(
      text: v != null && v.creditLimitInr > 0 ? v.creditLimitInr.toStringAsFixed(0) : '',
    );
    _bankNameController = TextEditingController(text: v?.bankName ?? '');
    _accountNumberController = TextEditingController(text: v?.accountNumber ?? '');
    _ifscCodeController = TextEditingController(text: v?.ifscCode ?? '');
    _branchNameController = TextEditingController(text: v?.branchName ?? '');
    _notesController = TextEditingController(text: v?.notes ?? '');

    _status = v?.status ?? VendorStatus.active;
    _category = v != null && categories.contains(v.category) ? v.category : 'General';
    _paymentTerms = v != null && termsOptions.contains(v.paymentTerms) ? v.paymentTerms : 'Net 30 Days';
    _rating = v?.rating ?? 4.0;
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _vendorCodeController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _creditLimitController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _branchNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final creditLimit = double.tryParse(_creditLimitController.text.trim()) ?? 0.0;

    final record = (widget.vendor ??
            VendorRecord(
              id: '',
              vendorCode: _vendorCodeController.text.trim(),
              companyName: _companyNameController.text.trim(),
              createdAt: DateTime.now(),
            ))
        .copyWith(
      vendorCode: _vendorCodeController.text.trim(),
      companyName: _companyNameController.text.trim(),
      contactPerson: _contactPersonController.text.trim(),
      phone: _phoneController.text.trim(),
      alternatePhone: _alternatePhoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      gstin: _gstinController.text.trim().toUpperCase(),
      pan: _panController.text.trim().toUpperCase(),
      category: _category,
      paymentTerms: _paymentTerms,
      creditLimitInr: creditLimit,
      bankName: _bankNameController.text.trim(),
      accountNumber: _accountNumberController.text.trim(),
      ifscCode: _ifscCodeController.text.trim().toUpperCase(),
      branchName: _branchNameController.text.trim(),
      status: _status,
      rating: _rating,
      notes: _notesController.text.trim(),
    );

    context.read<VendorFormCubit>().submitVendor(record, isEdit: widget.vendor != null);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.vendor != null;

    return BlocProvider<VendorFormCubit>(
      create: (_) => VendorFormCubit(widget.repository),
      child: BlocConsumer<VendorFormCubit, VendorFormState>(
        listener: (context, state) {
          if (state is VendorFormSuccess) {
            widget.onSaved?.call(state.vendor);
            Navigator.of(context).pop(true);
          } else if (state is VendorFormFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: const Color(0xFFDC2626)),
            );
          }
        },
        builder: (context, state) {
          final isSubmitting = state is VendorFormSubmitting;

          return Scaffold(
            appBar: AppBar(
              title: Text(isEdit ? 'Edit Vendor' : 'Add New Vendor'),
            ),
            body: SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSectionCard(
                            title: '1. Basic Information',
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      key: const Key('vendor_form_name'),
                                      controller: _companyNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Company / Business Name *',
                                        hintText: 'e.g. Apex Industrial Supplies Pvt Ltd',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (val) =>
                                          val == null || val.trim().isEmpty ? 'Company name is required.' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      key: const Key('vendor_form_code'),
                                      controller: _vendorCodeController,
                                      decoration: const InputDecoration(
                                        labelText: 'Vendor Code',
                                        hintText: 'e.g. VND-008 (auto if blank)',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                   Expanded(
                                    child: DropdownButtonFormField<String>(
                                      key: const Key('vendor_form_category'),
                                      initialValue: _category,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Category',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: categories
                                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _category = val);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<VendorStatus>(
                                      key: const Key('vendor_form_status'),
                                      initialValue: _status,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Status',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: VendorStatus.values
                                          .map((s) => DropdownMenuItem(value: s, child: Text(s.displayName)))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _status = val);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      const Text('Supplier Rating: ', style: TextStyle(fontWeight: FontWeight.w500)),
                                      const Icon(Icons.star, color: Color(0xFFF59E0B), size: 18),
                                      const SizedBox(width: 4),
                                      Text(_rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Slider(
                                    key: const Key('vendor_form_rating_slider'),
                                    value: _rating,
                                    min: 1.0,
                                    max: 5.0,
                                    divisions: 8,
                                    onChanged: (val) => setState(() => _rating = val),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildSectionCard(
                            title: '2. Contact Information',
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      key: const Key('vendor_form_contact_person'),
                                      controller: _contactPersonController,
                                      decoration: const InputDecoration(
                                        labelText: 'Primary Contact Person',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      key: const Key('vendor_form_phone'),
                                      controller: _phoneController,
                                      decoration: const InputDecoration(
                                        labelText: 'Primary Phone Number *',
                                        hintText: '+91 98000 00000',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (val) =>
                                          val == null || val.trim().isEmpty ? 'Phone is required.' : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      key: const Key('vendor_form_email'),
                                      controller: _emailController,
                                      decoration: const InputDecoration(
                                        labelText: 'Email Address',
                                        hintText: 'vendor@domain.com',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      key: const Key('vendor_form_alternate_phone'),
                                      controller: _alternatePhoneController,
                                      decoration: const InputDecoration(
                                        labelText: 'Alternate Phone / Landline',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                key: const Key('vendor_form_address'),
                                controller: _addressController,
                                decoration: const InputDecoration(
                                  labelText: 'Office / Facility Address',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      key: const Key('vendor_form_city'),
                                      controller: _cityController,
                                      decoration: const InputDecoration(
                                        labelText: 'City',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      key: const Key('vendor_form_state'),
                                      controller: _stateController,
                                      decoration: const InputDecoration(
                                        labelText: 'State',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      key: const Key('vendor_form_pincode'),
                                      controller: _pincodeController,
                                      decoration: const InputDecoration(
                                        labelText: 'Pincode',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildSectionCard(
                            title: '3. Compliance & Commercial Terms',
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      key: const Key('vendor_form_gstin'),
                                      controller: _gstinController,
                                      decoration: const InputDecoration(
                                        labelText: 'GSTIN (15 characters)',
                                        hintText: '07AAAAA0000A1Z5',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      key: const Key('vendor_form_pan'),
                                      controller: _panController,
                                      decoration: const InputDecoration(
                                        labelText: 'PAN Number (10 characters)',
                                        hintText: 'AAAAA0000A',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      key: const Key('vendor_form_payment_terms'),
                                      initialValue: _paymentTerms,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Payment Terms',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: termsOptions
                                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _paymentTerms = val);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      key: const Key('vendor_form_credit_limit'),
                                      controller: _creditLimitController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Credit Limit (INR)',
                                        prefixText: '₹ ',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildSectionCard(
                            title: '4. Bank Details & Notes',
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      key: const Key('vendor_form_bank_name'),
                                      controller: _bankNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Bank Name',
                                        hintText: 'HDFC Bank',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      key: const Key('vendor_form_account_number'),
                                      controller: _accountNumberController,
                                      decoration: const InputDecoration(
                                        labelText: 'Account Number',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      key: const Key('vendor_form_ifsc'),
                                      controller: _ifscCodeController,
                                      decoration: const InputDecoration(
                                        labelText: 'IFSC Code',
                                        hintText: 'HDFC0000123',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      key: const Key('vendor_form_branch'),
                                      controller: _branchNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Branch Name',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                key: const Key('vendor_form_notes'),
                                controller: _notesController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Operational Notes & Comments',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Actions
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton.icon(
                                key: const Key('vendor_form_submit_button'),
                                onPressed: isSubmitting ? null : () => _submit(context),
                                icon: isSubmitting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.check, size: 18),
                                label: Text(isEdit ? 'Save Changes' : 'Create Vendor'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
            ),
            Divider(height: 20, color: colorScheme.outlineVariant),
            ...children,
          ],
        ),
      ),
    );
  }
}
