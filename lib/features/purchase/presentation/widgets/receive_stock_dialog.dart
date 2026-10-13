import 'package:flutter/material.dart';
import '../../domain/entities/purchase_order_record.dart';

/// Modal dialog enabling warehouse or procurement staff to record received item quantities.
class ReceiveStockDialog extends StatefulWidget {
  final PurchaseOrderRecord record;
  final ValueChanged<Map<String, int>> onReceiveConfirmed;

  const ReceiveStockDialog({
    super.key,
    required this.record,
    required this.onReceiveConfirmed,
  });

  @override
  State<ReceiveStockDialog> createState() => _ReceiveStockDialogState();
}

class _ReceiveStockDialogState extends State<ReceiveStockDialog> {
  final Map<String, TextEditingController> _controllers = {};
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    for (final item in widget.record.items) {
      // Default to receiving all remaining pending items
      _controllers[item.id] = TextEditingController(
        text: item.pendingQuantity.toString(),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleConfirm() {
    if (!_formKey.currentState!.validate()) return;

    final result = <String, int>{};
    for (final item in widget.record.items) {
      final text = _controllers[item.id]?.text.trim() ?? '0';
      final qty = int.tryParse(text) ?? 0;
      if (qty > 0) {
        result[item.id] = qty;
      }
    }

    if (result.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one quantity greater than zero.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    widget.onReceiveConfirmed(result);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      key: const Key('receive_stock_dialog'),
      title: Row(
        children: [
          Icon(Icons.inventory_2_outlined, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Receive Stock (${widget.record.poNumber})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Record quantities received at warehouse gate from ${widget.record.vendorName}:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                ...widget.record.items.map((item) {
                  final controller = _controllers[item.id];
                  final isDone = item.isFullyReceived;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDone
                          ? Colors.green.withValues(alpha: 0.08)
                          : colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDone
                            ? Colors.green.withValues(alpha: 0.4)
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.itemName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${item.receivedQuantity}/${item.orderedQuantity} ${item.unit}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SKU: ${item.sku} • Pending: ${item.pendingQuantity} ${item.unit}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (!isDone)
                          TextFormField(
                            key: Key('receive_quantity_input_${item.id}'),
                            controller: controller,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Quantity to Receive (${item.unit})',
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (val) {
                              final parsed = int.tryParse(val?.trim() ?? '');
                              if (parsed == null || parsed < 0) {
                                return 'Enter valid quantity >= 0';
                              }
                              if (parsed > item.pendingQuantity) {
                                return 'Cannot exceed pending (${item.pendingQuantity})';
                              }
                              return null;
                            },
                          )
                        else
                          Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 16, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Fully Received',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const Key('confirm_receive_stock_button'),
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Confirm Receipt'),
          onPressed: _handleConfirm,
        ),
      ],
    );
  }
}
