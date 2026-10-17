import 'package:flutter/material.dart';
import '../../domain/entities/vendor_record.dart';
import '../../domain/entities/vendor_status.dart';

/// Desktop data table presenting vendor records in high density.
class VendorDataTable extends StatelessWidget {
  final List<VendorRecord> vendors;
  final ValueChanged<VendorRecord> onView;
  final ValueChanged<VendorRecord>? onEdit;
  final ValueChanged<VendorRecord>? onDelete;
  final ScrollController? horizontalController;

  const VendorDataTable({
    super.key,
    required this.vendors,
    required this.onView,
    this.onEdit,
    this.onDelete,
    this.horizontalController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (vendors.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.storefront_outlined, size: 48, color: colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              'No vendors found matching your criteria.',
              style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          controller: horizontalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: horizontalController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(colorScheme.surfaceContainerHigh),
                dataRowMinHeight: 48,
                dataRowMaxHeight: 56,
                horizontalMargin: 16,
                columnSpacing: 20,
                columns: [
                  DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface))),
                  DataColumn(label: Text('Company Name', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface))),
                  DataColumn(label: Text('Contact Person', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface))),
                  DataColumn(label: Text('Contact', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface))),
                  DataColumn(label: Text('GSTIN', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface))),
                  DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface))),
                  DataColumn(label: Text('Terms', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface))),
                  DataColumn(label: Text('Rating', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface))),
                ],
                rows: vendors.map((vendor) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          vendor.vendorCode,
                          style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.primary),
                        ),
                        onTap: () => onView(vendor),
                      ),
                      DataCell(
                        Text(
                          vendor.companyName,
                          style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                        ),
                        onTap: () => onView(vendor),
                      ),
                      DataCell(
                        Text(
                          vendor.contactPerson.isEmpty ? '—' : vendor.contactPerson,
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(vendor.phone, style: TextStyle(fontSize: 12, color: colorScheme.onSurface)),
                            if (vendor.email.isNotEmpty)
                              Text(
                                vendor.email,
                                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          vendor.gstin.isEmpty ? '—' : vendor.gstin,
                          style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: colorScheme.onSurface),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            vendor.category,
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                          ),
                        ),
                      ),
                      DataCell(Text(vendor.paymentTerms, style: TextStyle(fontSize: 12, color: colorScheme.onSurface))),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 4),
                            Text(
                              vendor.rating.toStringAsFixed(1),
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                      DataCell(_buildStatusBadge(vendor.status, colorScheme)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, size: 18),
                              tooltip: 'View Details',
                              onPressed: () => onView(vendor),
                            ),
                            if (onEdit != null)
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Edit Vendor',
                                onPressed: () => onEdit!(vendor),
                              ),
                            if (onDelete != null)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                                tooltip: 'Delete Vendor',
                                onPressed: () => onDelete!(vendor),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(VendorStatus status, ColorScheme colorScheme) {
    Color bg;
    Color fg;

    switch (status) {
      case VendorStatus.active:
        bg = const Color(0xFF10B981).withValues(alpha: 0.15);
        fg = const Color(0xFF10B981);
        break;
      case VendorStatus.underReview:
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        fg = const Color(0xFFF59E0B);
        break;
      case VendorStatus.blacklisted:
        bg = const Color(0xFFEF4444).withValues(alpha: 0.15);
        fg = const Color(0xFFEF4444);
        break;
      case VendorStatus.inactive:
        bg = colorScheme.onSurfaceVariant.withValues(alpha: 0.15);
        fg = colorScheme.onSurfaceVariant;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
