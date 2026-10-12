import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../domain/entities/dispatch_item.dart';
import '../../domain/inputs/create_dispatch_input.dart';
import '../../domain/policies/dispatch_access_policy.dart';
import '../../domain/repositories/dispatch_repository.dart';
import '../bloc/create_dispatch_cubit.dart';
import '../bloc/create_dispatch_state.dart';

/// Screen allowing authorized staff to record a new shipment / dispatch order.
class CreateDispatchScreen extends StatelessWidget {
  final CurrentUser user;
  final DispatchRepository repository;

  const CreateDispatchScreen({
    super.key,
    required this.user,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    if (!DispatchAccessPolicy.canCreate(user)) {
      return const AccessRestrictedScreen();
    }

    return BlocProvider<CreateDispatchCubit>(
      create: (_) => CreateDispatchCubit(repository),
      child: const _CreateDispatchView(),
    );
  }
}

class _CreateDispatchView extends StatefulWidget {
  const _CreateDispatchView();

  @override
  State<_CreateDispatchView> createState() => _CreateDispatchViewState();
}

class _LineItemEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(text: '1');
  final TextEditingController unitController = TextEditingController(text: 'Pcs');
  final TextEditingController priceController = TextEditingController(text: '0.0');

  void dispose() {
    nameController.dispose();
    skuController.dispose();
    quantityController.dispose();
    unitController.dispose();
    priceController.dispose();
  }
}

class _CreateDispatchViewState extends State<_CreateDispatchView> {
  final _formKey = GlobalKey<FormState>();

  // Customer & Delivery
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _deliveryAddressController = TextEditingController();

  // Invoice & Order
  final _orderNumberController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _invoiceAmountController = TextEditingController(text: '0.0');

  // Transport & Vehicle Logistics
  final _transporterNameController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _vehicleTypeController = TextEditingController(text: 'Truck');
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _builtyNumberController = TextEditingController();

  // Notes
  final _notesController = TextEditingController();

  // Dynamic Line Items
  final List<_LineItemEntry> _lineItems = [];

  @override
  void initState() {
    super.initState();
    // Default initial line item
    _lineItems.add(_LineItemEntry());
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _deliveryAddressController.dispose();
    _orderNumberController.dispose();
    _invoiceNumberController.dispose();
    _invoiceAmountController.dispose();
    _transporterNameController.dispose();
    _vehicleNumberController.dispose();
    _vehicleTypeController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _builtyNumberController.dispose();
    _notesController.dispose();
    for (final item in _lineItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _lineItems.add(_LineItemEntry());
    });
  }

  void _removeItem(int index) {
    if (_lineItems.length <= 1) return;
    setState(() {
      final removed = _lineItems.removeAt(index);
      removed.dispose();
    });
  }

  void _handleSubmit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final parsedItems = <DispatchItem>[];
    for (int i = 0; i < _lineItems.length; i++) {
      final entry = _lineItems[i];
      final name = entry.nameController.text.trim();
      final sku = entry.skuController.text.trim();
      final qty = double.tryParse(entry.quantityController.text.trim()) ?? 1.0;
      final unit = entry.unitController.text.trim().isEmpty ? 'Pcs' : entry.unitController.text.trim();
      final price = double.tryParse(entry.priceController.text.trim()) ?? 0.0;

      if (name.isNotEmpty) {
        parsedItems.add(
          DispatchItem(
            id: 'item_${DateTime.now().millisecondsSinceEpoch}_$i',
            name: name,
            sku: sku.isEmpty ? 'SKU-$i' : sku,
            quantity: qty,
            unit: unit,
            unitPrice: price,
          ),
        );
      }
    }

    if (parsedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one line item with a name is required.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final input = CreateDispatchInput(
      orderNumber: _orderNumberController.text.trim().isEmpty
          ? 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'
          : _orderNumberController.text.trim(),
      customerName: _customerNameController.text.trim(),
      customerPhone: _customerPhoneController.text.trim(),
      deliveryAddress: _deliveryAddressController.text.trim(),
      invoiceNumber: _invoiceNumberController.text.trim(),
      invoiceDate: DateTime.now(),
      invoiceAmount: double.tryParse(_invoiceAmountController.text.trim()) ?? 0.0,
      transporterName: _transporterNameController.text.trim().isEmpty
          ? 'Standard Carrier'
          : _transporterNameController.text.trim(),
      vehicleNumber: _vehicleNumberController.text.trim(),
      vehicleType: _vehicleTypeController.text.trim().isEmpty ? 'Truck' : _vehicleTypeController.text.trim(),
      driverName: _driverNameController.text.trim(),
      driverPhone: _driverPhoneController.text.trim(),
      builtyNumber: _builtyNumberController.text.trim(),
      builtyDate: DateTime.now(),
      notes: _notesController.text.trim(),
      items: parsedItems,
    );

    context.read<CreateDispatchCubit>().submit(input);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<CreateDispatchCubit, CreateDispatchState>(
      listener: (context, state) {
        if (state is CreateDispatchSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dispatch ${state.record.dispatchCode} created successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state is CreateDispatchFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state is CreateDispatchSubmitting;

        return Scaffold(
          appBar: AppBar(
            title: const Text('New Dispatch Order'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: FilledButton.icon(
                  key: const Key('dispatch_save_button'),
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Save Dispatch'),
                  onPressed: isSubmitting ? null : () => _handleSubmit(context),
                ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section 1: Customer & Delivery Details
                      _buildSectionCard(
                        context,
                        title: 'Customer & Delivery Destination',
                        icon: Icons.person_pin_circle_outlined,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  key: const Key('dispatch_form_customer_name'),
                                  controller: _customerNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Customer / Consignee Name *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Customer name required' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  key: const Key('dispatch_form_customer_phone'),
                                  controller: _customerPhoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Customer Phone *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Customer phone required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('dispatch_form_delivery_address'),
                            controller: _deliveryAddressController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Delivery Address *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Delivery address required' : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Section 2: Invoice & Reference Information
                      _buildSectionCard(
                        context,
                        title: 'Invoice & Commercial Details',
                        icon: Icons.receipt_long_outlined,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  key: const Key('dispatch_form_order_number'),
                                  controller: _orderNumberController,
                                  decoration: const InputDecoration(
                                    labelText: 'Order # (Optional)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  key: const Key('dispatch_form_invoice_number'),
                                  controller: _invoiceNumberController,
                                  decoration: const InputDecoration(
                                    labelText: 'Invoice Number *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Invoice number required' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  key: const Key('dispatch_form_invoice_amount'),
                                  controller: _invoiceAmountController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Invoice Amount (₹)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Section 3: Transport & Logistics
                      _buildSectionCard(
                        context,
                        title: 'Transport & Logistics Information',
                        icon: Icons.local_shipping_outlined,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  key: const Key('dispatch_form_transporter_name'),
                                  controller: _transporterNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Transporter Name',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  key: const Key('dispatch_form_vehicle_number'),
                                  controller: _vehicleNumberController,
                                  decoration: const InputDecoration(
                                    labelText: 'Vehicle Number *',
                                    hintText: 'e.g. DL-01-AB-1234',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Vehicle number required' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  key: const Key('dispatch_form_vehicle_type'),
                                  controller: _vehicleTypeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Vehicle Type',
                                    hintText: 'e.g. Truck, Van',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  key: const Key('dispatch_form_driver_name'),
                                  controller: _driverNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Driver Name *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Driver name required' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  key: const Key('dispatch_form_driver_phone'),
                                  controller: _driverPhoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Driver Phone *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Driver phone required' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  key: const Key('dispatch_form_builty_number'),
                                  controller: _builtyNumberController,
                                  decoration: const InputDecoration(
                                    labelText: 'Builty / LR # *',
                                    hintText: 'e.g. BL-VRL-9921',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Builty number required' : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Section 4: Line Items (Dynamic Table)
                      _buildSectionCard(
                        context,
                        title: 'Shipment Line Items',
                        icon: Icons.inventory_2_outlined,
                        trailing: OutlinedButton.icon(
                          key: const Key('dispatch_add_item_button'),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Item'),
                          onPressed: _addItem,
                        ),
                        children: [
                          ..._lineItems.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;

                            return Container(
                              key: Key('dispatch_line_item_row_$idx'),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      key: Key('item_name_$idx'),
                                      controller: item.nameController,
                                      decoration: InputDecoration(
                                        labelText: 'Item Name *',
                                        isDense: true,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty) ? 'Name required' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      key: Key('item_sku_$idx'),
                                      controller: item.skuController,
                                      decoration: InputDecoration(
                                        labelText: 'SKU',
                                        isDense: true,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      key: Key('item_quantity_$idx'),
                                      controller: item.quantityController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Qty',
                                        isDense: true,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      key: Key('item_unit_$idx'),
                                      controller: item.unitController,
                                      decoration: InputDecoration(
                                        labelText: 'Unit',
                                        isDense: true,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      key: Key('item_price_$idx'),
                                      controller: item.priceController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Price (₹)',
                                        isDense: true,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                  ),
                                  if (_lineItems.length > 1) ...[
                                    const SizedBox(width: 4),
                                    IconButton(
                                      key: Key('item_remove_$idx'),
                                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                      tooltip: 'Remove Item',
                                      onPressed: () => _removeItem(idx),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Section 5: Notes
                      _buildSectionCard(
                        context,
                        title: 'Handling & Delivery Notes',
                        icon: Icons.note_outlined,
                        children: [
                          TextFormField(
                            key: const Key('dispatch_form_notes'),
                            controller: _notesController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Additional Instructions / Delivery Notes',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Bottom Submit Action
                      FilledButton.icon(
                        key: const Key('dispatch_form_submit_button'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          isSubmitting ? 'Creating Dispatch...' : 'Create Dispatch Order',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: isSubmitting ? null : () => _handleSubmit(context),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    Widget? trailing,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      color: colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}
