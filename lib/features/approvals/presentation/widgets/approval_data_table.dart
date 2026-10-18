import 'package:flutter/material.dart';
import '../../../dashboard/presentation/mappers/crm_module_presentation.dart';
import '../../domain/entities/approval_priority.dart';
import '../../domain/entities/approval_request.dart';
import '../../domain/entities/approval_status.dart';

/// Desktop & tablet multi-column data table for displaying [ApprovalRequest]s.
class ApprovalDataTable extends StatelessWidget {
  final List<ApprovalRequest> requests;
  final ValueChanged<ApprovalRequest> onSelectRequest;

  const ApprovalDataTable({
    super.key,
    required this.requests,
    required this.onSelectRequest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (requests.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              'No approval requests match the selected filters.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 800),
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          dataRowMinHeight: 52,
          dataRowMaxHeight: 64,
          columnSpacing: 20,
          horizontalMargin: 16,
          columns: const [
            DataColumn(
              label: Text(
                'Request #',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Item / Title',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Module',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Requester',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Submitted',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Priority',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Action',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: requests.map((request) {
            return DataRow(
              key: ValueKey('approval_row_${request.id}'),
              cells: [
                // Request Number
                DataCell(
                  Text(
                    request.requestNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),

                // Item Title
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          request.entityTitle,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (request.amount != null)
                          Text(
                            '${request.currencyCode ?? ''} ${request.amount!.toStringAsFixed(2)}'
                                .trim(),
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.outline,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Module
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      request.module.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),

                // Requester
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        request.requesterName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (request.departmentName != null)
                        Text(
                          request.departmentName!,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),

                // Submitted
                DataCell(
                  Text(
                    _formatDate(request.submittedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                // Priority
                DataCell(_buildPriorityChip(request.priority)),

                // Status
                DataCell(_buildStatusChip(request.status)),

                // Action
                DataCell(
                  FilledButton.tonal(
                    key: Key('approval_action_btn_${request.id}'),
                    onPressed: () => onSelectRequest(request),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: const Size(64, 34),
                    ),
                    child: Text(
                      request.status.isActionable ? 'Review' : 'View',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(ApprovalPriority priority) {
    Color bg;
    Color fg;

    switch (priority) {
      case ApprovalPriority.urgent:
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
      case ApprovalPriority.high:
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade900;
      case ApprovalPriority.normal:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
      case ApprovalPriority.low:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.displayName,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildStatusChip(ApprovalStatus status) {
    Color bg;
    Color fg;

    switch (status) {
      case ApprovalStatus.pending:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
      case ApprovalStatus.approved:
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
      case ApprovalStatus.rejected:
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
      case ApprovalStatus.revisionRequested:
        bg = Colors.purple.shade100;
        fg = Colors.purple.shade900;
      case ApprovalStatus.cancelled:
        bg = Colors.grey.shade300;
        fg = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
