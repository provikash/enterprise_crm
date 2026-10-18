import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../domain/entities/purchase_order_item.dart';
import '../../domain/inputs/create_purchase_order_input.dart';
import '../../domain/policies/purchase_access_policy.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../../approvals/domain/services/approval_bridge.dart';
import '../../../notifications/domain/services/notification_dispatcher.dart';
import '../bloc/create_purchase_order_cubit.dart';
import '../bloc/create_purchase_order_state.dart';

/// Screen allowing authorized purchasers and administrators to create a new Purchase Order.
class CreatePurchaseOrderScreen extends StatelessWidget {
  final CurrentUser user;
  final PurchaseRepository repository;
  final ApprovalBridge? approvalBridge;
  final NotificationDispatcher? notificationDispatcher;

  const CreatePurchaseOrderScreen({
    super.key,
    required this.user,
    required this.repository,
    this.approvalBridge,
    this.notificationDispatcher,
  });

  @override
  Widget build(BuildContext context) {
    if (!PurchaseAccessPolicy.canCreate(user)) {
      return const AccessRestrictedScreen();
    }

    ApprovalBridge? bridge = approvalBridge;
    if (bridge == null) {
      try {
        bridge = context.read<ApprovalBridge>();
      } catch (_) {}
    }

    NotificationDispatcher? dispatcher = notificationDispatcher;
    if (dispatcher == null) {
      try {
        dispatcher = context.read<NotificationDispatcher>();
      } catch (_) {}
    }

    return BlocProvider<CreatePurchaseOrderCubit>(
      create: (_) => CreatePurchaseOrderCubit(
        repository,
        approvalBridge: bridge,
        notificationDispatcher: dispatcher,
        currentUser: user,
      ),
      child: const _CreatePurchaseOrderView(),
    );
  }
}

class _CreatePurchaseOrderView extends StatefulWidget {
  const _CreatePurchaseOrderView();

  @override
  State<_CreatePurchaseOrderView> createState() => _CreatePurchaseOrderViewState();
}

class _LineItemEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController categoryController = TextEditingController(text: 'General');
  final TextEditingController quantityController = TextEditingController(text: '1');
  final TextEditingController unitController = TextEditingController(text: 'Pcs');
  final TextEditingController priceController = TextEditingController(text: '0.0');

  void dispose() {
    nameController.dispose();
    skuController.dispose();
    categoryController.dispose();
    quantityController.dispose();
    unitController.dispose();
    priceController.dispose();
  }

  double get lineTotal {
    final qty = int.tryParse(quantityController.text.trim()) ?? 0;
    final price = double.tryParse(priceController.text.trim()) ?? 0.0;
    return qty * price;
  }
}

class _CreatePurchaseOrderViewState extends State<_CreatePurchaseOrderView> {
  final _formKey = GlobalKey<FormState>();

  // Vendor Details
  final _vendorNameController = TextEditingController();
  final _vendorGstController = TextEditingController();
  final _vendorContactController = TextEditingController();

  // Order Details
  final _paymentTermsController = TextEditingController(text: 'Net 30 Days');
  final _shippingAddressController = TextEditingController(
    text: 'Main Warehouse, Sector 18, Gurugram',
  );
  final _notesController = TextEditingController();
  DateTime? _expectedDeliveryDate;

  // Dynamic Line Items
  final List<_LineItemEntry> _lineItems = [];

  @override
  void initState() {
    super.initState();
    _addItem();
  }

  @override
  void dispose() {
    _vendorNameController.dispose();
    _vendorGstController.dispose();
    _vendorContactController.dispose();
    _paymentTermsController.dispose();
    _shippingAddressController.dispose();
    _notesController.dispose();
    for (final item in _lineItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    final entry = _LineItemEntry();
    entry.quantityController.addListener(_onCalculationsChanged);
    entry.priceController.addListener(_onCalculationsChanged);
    setState(() {
      _lineItems.add(entry);
    });
  }

  void _removeItem(int index) {
    if (_lineItems.length <= 1) return;
    setState(() {
      final removed = _lineItems.removeAt(index);
      removed.quantityController.removeListener(_onCalculationsChanged);
      removed.priceController.removeListener(_onCalculationsChanged);
      removed.dispose();
    });
  }

  void _onCalculationsChanged() {
    setState(() {});
  }

  double get _subtotalAmount =>
      _lineItems.fold(0.0, (sum, item) => sum + item.lineTotal);

  double get _taxAmount => _subtotalAmount * 0.18;

  double get _totalAmount => _subtotalAmount + _taxAmount;

  Future<void> _pickDeliveryDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedDeliveryDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _expectedDeliveryDate = picked;
      });
    }
  }

  void _handleSubmit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final parsedItems = <PurchaseOrderItem>[];
    for (int i = 0; i < _lineItems.length; i++) {
      final entry = _lineItems[i];
      final name = entry.nameController.text.trim();
      final sku = entry.skuController.text.trim();
      final category = entry.categoryController.text.trim();
      final qty = int.tryParse(entry.quantityController.text.trim()) ?? 1;
      final unit = entry.unitController.text.trim().isEmpty ? 'Pcs' : entry.unitController.text.trim();
      final price = double.tryParse(entry.priceController.text.trim()) ?? 0.0;

      if (name.isNotEmpty) {
        parsedItems.add(
          PurchaseOrderItem(
            id: 'poi_${DateTime.now().millisecondsSinceEpoch}_$i',
            itemName: name,
            sku: sku.isEmpty ? 'SKU-${i + 1}' : sku,
            category: category.isEmpty ? 'General' : category,
            orderedQuantity: qty,
            receivedQuantity: 0,
            unit: unit,
            unitPriceInr: price,
          ),
        );
      }
    }

    if (parsedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one purchase item is required.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final input = CreatePurchaseOrderInput(
      vendorName: _vendorNameController.text.trim(),
      vendorGst: _vendorGstController.text.trim(),
      vendorContact: _vendorContactController.text.trim(),
      orderDate: DateTime.now(),
      expectedDeliveryDate: _expectedDeliveryDate,
      paymentTerms: _paymentTermsController.text.trim(),
      shippingAddress: _shippingAddressController.text.trim(),
      notes: _notesController.text.trim(),
      items: parsedItems,
    );

    context.read<CreatePurchaseOrderCubit>().submit(input);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<CreatePurchaseOrderCubit, CreatePurchaseOrderState>(
      listener: (context, state) {
        if (state is CreatePurchaseOrderSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PO ${state.record.poNumber} created successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state is CreatePurchaseOrderFailure) {
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
        final isSubmitting = state is CreatePurchaseOrderSubmitting;

        return Scaffold(
          appBar: AppBar(
            title: const Text('New Purchase Order'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: FilledButton.icon(
                  key: const Key('purchase_save_po_button'),
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Create PO'),
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 600;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Section 1: Vendor Details
                          _buildSectionCard(
                            context,
                            title: 'Vendor Details',
                            icon: Icons.storefront_outlined,
                            children: [
                              if (isNarrow) ...[
                                TextFormField(
                                  key: const Key('purchase_form_vendor_name'),
                                  controller: _vendorNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Vendor Name *',
                                    hintText: 'e.g. Apex Tech Supplies Pvt Ltd',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Vendor name required'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  key: const Key('purchase_form_vendor_gst'),
                                  controller: _vendorGstController,
                                  decoration: const InputDecoration(
                                    labelText: 'Vendor GSTIN',
                                    hintText: 'e.g. 07AAAAA0000A1Z5',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  key: const Key('purchase_form_vendor_contact'),
                                  controller: _vendorContactController,
                                  decoration: const InputDecoration(
                                    labelText: 'Contact / Phone',
                                    hintText: 'e.g. +91 98111 22334',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        key: const Key('purchase_form_vendor_name'),
                                        controller: _vendorNameController,
                                        decoration: const InputDecoration(
                                          labelText: 'Vendor Name *',
                                          hintText: 'e.g. Apex Tech Supplies Pvt Ltd',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (v) =>
                                            (v == null || v.trim().isEmpty)
                                                ? 'Vendor name required'
                                                : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 1,
                                      child: TextFormField(
                                        key: const Key('purchase_form_vendor_gst'),
                                        controller: _vendorGstController,
                                        decoration: const InputDecoration(
                                          labelText: 'Vendor GSTIN',
                                          hintText: 'e.g. 07AAAAA0000A1Z5',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  key: const Key('purchase_form_vendor_contact'),
                                  controller: _vendorContactController,
                                  decoration: const InputDecoration(
                                    labelText: 'Contact Person & Phone',
                                    hintText: 'e.g. Rahul Sharma (+91 98111 22334)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Section 2: Order Terms & Logistics
                          _buildSectionCard(
                            context,
                            title: 'Order Terms & Logistics',
                            icon: Icons.local_shipping_outlined,
                            children: [
                              if (isNarrow) ...[
                                TextFormField(
                                  key: const Key('purchase_form_payment_terms'),
                                  controller: _paymentTermsController,
                                  decoration: const InputDecoration(
                                    labelText: 'Payment Terms',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildDatePickerField(context),
                                const SizedBox(height: 12),
                                TextFormField(
                                  key: const Key('purchase_form_shipping_address'),
                                  controller: _shippingAddressController,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'Delivery / Shipping Address',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        key: const Key('purchase_form_payment_terms'),
                                        controller: _paymentTermsController,
                                        decoration: const InputDecoration(
                                          labelText: 'Payment Terms',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildDatePickerField(context),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  key: const Key('purchase_form_shipping_address'),
                                  controller: _shippingAddressController,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'Delivery / Shipping Address',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Section 3: Line Items (Dynamic Table/Cards)
                          _buildSectionCard(
                            context,
                            title: 'Purchase Line Items',
                            icon: Icons.inventory_2_outlined,
                            trailing: OutlinedButton.icon(
                              key: const Key('purchase_add_item_button'),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Item'),
                              onPressed: _addItem,
                            ),
                            children: [
                              ..._lineItems.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final item = entry.value;

                                if (isNarrow) {
                                  return Container(
                                    key: Key('purchase_line_item_card_$idx'),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: colorScheme.outlineVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                key: Key('item_name_$idx'),
                                                controller: item.nameController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Item Name *',
                                                  isDense: true,
                                                  border: OutlineInputBorder(),
                                                ),
                                                validator: (v) => (v == null ||
                                                        v.trim().isEmpty)
                                                    ? 'Item name required'
                                                    : null,
                                              ),
                                            ),
                                            if (_lineItems.length > 1) ...[
                                              const SizedBox(width: 8),
                                              IconButton(
                                                key: Key('item_remove_$idx'),
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 20,
                                                  color: Colors.red,
                                                ),
                                                tooltip: 'Remove Item',
                                                onPressed: () =>
                                                    _removeItem(idx),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: TextFormField(
                                                key: Key('item_sku_$idx'),
                                                controller: item.skuController,
                                                decoration: const InputDecoration(
                                                  labelText: 'SKU',
                                                  isDense: true,
                                                  border: OutlineInputBorder(),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 2,
                                              child: TextFormField(
                                                key: Key('item_category_$idx'),
                                                controller:
                                                    item.categoryController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Category',
                                                  isDense: true,
                                                  border: OutlineInputBorder(),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: TextFormField(
                                                key: Key('item_quantity_$idx'),
                                                controller:
                                                    item.quantityController,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration: const InputDecoration(
                                                  labelText: 'Qty *',
                                                  isDense: true,
                                                  border: OutlineInputBorder(),
                                                ),
                                                validator: (v) {
                                                  final q = int.tryParse(
                                                          v?.trim() ?? '') ??
                                                      0;
                                                  return q <= 0
                                                      ? 'Qty > 0'
                                                      : null;
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 1,
                                              child: TextFormField(
                                                key: Key('item_unit_$idx'),
                                                controller: item.unitController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Unit',
                                                  isDense: true,
                                                  border: OutlineInputBorder(),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 2,
                                              child: TextFormField(
                                                key: Key('item_price_$idx'),
                                                controller:
                                                    item.priceController,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration: const InputDecoration(
                                                  labelText: 'Price (₹) *',
                                                  isDense: true,
                                                  border: OutlineInputBorder(),
                                                ),
                                                validator: (v) {
                                                  final p = double.tryParse(
                                                          v?.trim() ?? '') ??
                                                      -1;
                                                  return p < 0
                                                      ? 'Price >= 0'
                                                      : null;
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            'Line Total: ₹${item.lineTotal.toStringAsFixed(2)}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return Container(
                                  key: Key('purchase_line_item_card_$idx'),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant
                                          .withValues(alpha: 0.5),
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
                                          decoration: const InputDecoration(
                                            labelText: 'Item Name *',
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                          ),
                                          validator: (v) =>
                                              (v == null || v.trim().isEmpty)
                                                  ? 'Item name required'
                                                  : null,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          key: Key('item_sku_$idx'),
                                          controller: item.skuController,
                                          decoration: const InputDecoration(
                                            labelText: 'SKU',
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          key: Key('item_category_$idx'),
                                          controller: item.categoryController,
                                          decoration: const InputDecoration(
                                            labelText: 'Category',
                                            isDense: true,
                                            border: OutlineInputBorder(),
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
                                          decoration: const InputDecoration(
                                            labelText: 'Qty *',
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                          ),
                                          validator: (v) {
                                            final q = int.tryParse(
                                                    v?.trim() ?? '') ??
                                                0;
                                            return q <= 0 ? 'Qty > 0' : null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 1,
                                        child: TextFormField(
                                          key: Key('item_unit_$idx'),
                                          controller: item.unitController,
                                          decoration: const InputDecoration(
                                            labelText: 'Unit',
                                            isDense: true,
                                            border: OutlineInputBorder(),
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
                                          decoration: const InputDecoration(
                                            labelText: 'Price (₹) *',
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                          ),
                                          validator: (v) {
                                            final p = double.tryParse(
                                                    v?.trim() ?? '') ??
                                                -1;
                                            return p < 0 ? 'Price >= 0' : null;
                                          },
                                        ),
                                      ),
                                      if (_lineItems.length > 1) ...[
                                        const SizedBox(width: 4),
                                        IconButton(
                                          key: Key('item_remove_$idx'),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 20,
                                            color: Colors.red,
                                          ),
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

                          // Section 4: Financial Summary Card
                          Card(
                            key: const Key('purchase_financial_summary_card'),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Subtotal (Before Tax):',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '₹${_subtotalAmount.toStringAsFixed(2)}',
                                        key: const Key('purchase_summary_subtotal'),
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'GST (18% Standard):',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '₹${_taxAmount.toStringAsFixed(2)}',
                                        key: const Key('purchase_summary_tax'),
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Total Estimated PO Amount:',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '₹${_totalAmount.toStringAsFixed(2)}',
                                        key: const Key('purchase_summary_total_amount'),
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Section 5: Notes & Remarks
                          _buildSectionCard(
                            context,
                            title: 'Notes & Instructions',
                            icon: Icons.note_outlined,
                            children: [
                              TextFormField(
                                key: const Key('purchase_form_notes'),
                                controller: _notesController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Terms, Delivery Instructions, or Remarks',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDatePickerField(BuildContext context) {
    return InkWell(
      onTap: () => _pickDeliveryDate(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Expected Delivery Date',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today, size: 20),
        ),
        child: Text(
          _expectedDeliveryDate == null
              ? 'Select expected delivery date'
              : '${_expectedDeliveryDate!.year}-${_expectedDeliveryDate!.month.toString().padLeft(2, '0')}-${_expectedDeliveryDate!.day.toString().padLeft(2, '0')}',
        ),
      ),
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
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
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
