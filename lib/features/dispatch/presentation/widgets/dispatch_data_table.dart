import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/dispatch_record.dart';
import 'dispatch_status_badge.dart';

/// Desktop & Web data table presenting dispatch orders with responsive
/// horizontal left-to-right / right-to-left bottom scroll navigation.
class DispatchDataTable extends StatefulWidget {
  final List<DispatchRecord> dispatches;
  final ScrollController? horizontalScrollController;
  final ScrollController? verticalScrollController;
  final ValueChanged<DispatchRecord> onViewRecord;

  const DispatchDataTable({
    super.key,
    required this.dispatches,
    this.horizontalScrollController,
    this.verticalScrollController,
    required this.onViewRecord,
  });

  @override
  State<DispatchDataTable> createState() => _DispatchDataTableState();
}

class _DispatchDataTableState extends State<DispatchDataTable> {
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
    final isAndroidApk =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    final hController = _effectiveHController;
    final vController = _effectiveVController;

    final columns = const [
      DataColumn(
          label: Text('Dispatch #',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label:
              Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label:
              Text('Invoice #', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Transporter & Vehicle',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Builty (LR) #',
              style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Items', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
    ];

    final rows = widget.dispatches.map((record) {
      return DataRow(
        key: ValueKey('dispatch_table_row_${record.id}'),
        cells: [
          DataCell(
            Text(
              record.dispatchCode,
              key: Key('dispatch_code_${record.id}'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  record.customerName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  record.customerPhone,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          DataCell(Text(record.invoiceNumber)),
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(record.transporterName),
                Text(
                  record.vehicleNumber,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          DataCell(
            Text(
              record.builtyNumber.isEmpty ? '—' : record.builtyNumber,
              style: TextStyle(
                fontFamily: 'monospace',
                color: record.builtyNumber.isEmpty
                    ? colorScheme.outline
                    : colorScheme.onSurface,
              ),
            ),
          ),
          DataCell(
            Text(
                '${record.items.length} ${record.items.length == 1 ? "item" : "items"}'),
          ),
          DataCell(
            Text(
              '₹${record.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          DataCell(DispatchStatusBadge(status: record.status)),
          DataCell(
            IconButton(
              key: Key('dispatch_view_button_${record.id}'),
              icon: const Icon(Icons.remove_red_eye_outlined, size: 20),
              tooltip: 'View details',
              onPressed: () => widget.onViewRecord(record),
            ),
          ),
        ],
      );
    }).toList();

    final dataTableWidget = DataTable(
      key: const Key('dispatch_records_table'),
      headingRowColor: WidgetStateProperty.all(
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      border: TableBorder.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        width: 1,
        borderRadius: BorderRadius.circular(8),
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

    final tableWidget = isAndroidApk
        ? SingleChildScrollView(
            controller: hController,
            scrollDirection: Axis.horizontal,
            child: innerVertical,
          )
        : Scrollbar(
            key: const Key('dispatch_horizontal_scroll_bar'),
            controller: hController,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
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
}
