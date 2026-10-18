import 'package:flutter/material.dart';
import '../../domain/entities/purchase_order_record.dart';
import 'purchase_status_badge.dart';

/// Desktop & Web data table presenting purchase orders with responsive
/// horizontal and vertical native scrollbar navigation.
class PurchaseDataTable extends StatefulWidget {
  final List<PurchaseOrderRecord> orders;
  final ScrollController? horizontalScrollController;
  final ScrollController? verticalScrollController;
  final ValueChanged<PurchaseOrderRecord> onViewRecord;

  const PurchaseDataTable({
    super.key,
    required this.orders,
    this.horizontalScrollController,
    this.verticalScrollController,
    required this.onViewRecord,
  });

  @override
  State<PurchaseDataTable> createState() => _PurchaseDataTableState();
}

class _PurchaseDataTableState extends State<PurchaseDataTable> {
  ScrollController? _internalHController;
  ScrollController? _internalVController;

  ScrollController get _effectiveHController =>
      widget.horizontalScrollController ??
      (_internalHController ??= ScrollController());

  ScrollController get _effectiveVController =>
      widget.verticalScrollController ??
      (_internalVController ??= ScrollController());

  @override
  void dispose() {
    _internalHController?.dispose();
    _internalVController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hController = _effectiveHController;
    final vController = _effectiveVController;

    final columns = const [
      DataColumn(
        label: Text('PO #', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      DataColumn(
        label: Text(
          'Vendor Name',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn(
        label: Text(
          'Order Date',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn(
        label: Text(
          'Exp. Delivery',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn(
        label: Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      DataColumn(
        label: Text('Total (₹)', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      DataColumn(
        label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      DataColumn(
        label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    ];

    final rows = widget.orders.map((record) {
      return DataRow(
        key: ValueKey('purchase_table_row_${record.id}'),
        cells: [
          DataCell(
            Text(
              record.poNumber,
              key: Key('purchase_po_${record.id}'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  record.vendorName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (record.vendorContact.isNotEmpty)
                  Text(
                    record.vendorContact,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          DataCell(Text(_formatDate(record.orderDate))),
          DataCell(
            Text(
              record.expectedDeliveryDate != null
                  ? _formatDate(record.expectedDeliveryDate!)
                  : '—',
            ),
          ),
          DataCell(Text('${record.items.length} items')),
          DataCell(
            Text(
              '₹${record.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataCell(PurchaseStatusBadge(status: record.status)),
          DataCell(
            OutlinedButton.icon(
              key: Key('purchase_view_button_${record.id}'),
              onPressed: () => widget.onViewRecord(record),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text('View'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
        ],
      );
    }).toList();

    final headerTextStyle = theme.textTheme.titleSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    );

    final dataTableWidget = DataTable(
      key: const Key('purchase_orders_table'),
      headingRowColor: WidgetStateProperty.all(const Color(0xFF1E293B)),
      headingTextStyle: headerTextStyle,
      border: TableBorder.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        width: 1,
        borderRadius: BorderRadius.circular(4),
      ),
      dataRowMinHeight: 52,
      dataRowMaxHeight: 64,
      columnSpacing: 24,
      horizontalMargin: 16,
      columns: columns,
      rows: rows,
    );

    final innerVertical = Scrollbar(
      controller: vController,
      thumbVisibility: true,
      trackVisibility: true,
      interactive: true,
      child: SingleChildScrollView(
        controller: vController,
        scrollDirection: Axis.vertical,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: dataTableWidget,
      ),
    );

    final tableWidget = Scrollbar(
      key: const Key('purchase_horizontal_scroll_bar'),
      controller: hController,
      child: SingleChildScrollView(
        controller: hController,
        scrollDirection: Axis.horizontal,
        child: innerVertical,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight.isFinite && constraints.maxHeight > 140) {
          return SizedBox.expand(child: tableWidget);
        }

        return tableWidget;
      },
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
