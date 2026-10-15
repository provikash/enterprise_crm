import 'package:flutter/material.dart';

import '../../domain/entities/attendance_record.dart';
import '../widgets/attendance_status_badge.dart';
import '../widgets/hr_info_row.dart';

/// Modal dialog displaying full metadata for an [AttendanceRecord].
class AttendanceDetailsDialog extends StatelessWidget {
  final AttendanceRecord record;

  const AttendanceDetailsDialog({super.key, required this.record});

  static Future<void> show(BuildContext context, AttendanceRecord record) {
    return showDialog(
      context: context,
      builder: (_) => AttendanceDetailsDialog(record: record),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      key: const Key('attendance_details_dialog'),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Attendance Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AttendanceStatusBadge(status: record.attendanceStatus),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HrInfoRow(label: 'Record ID', value: record.id, labelWidth: 120),
              HrInfoRow(
                label: 'Employee ID',
                value: record.employeeId,
                labelWidth: 120,
              ),
              HrInfoRow(
                label: 'Date',
                value: record.formattedDate,
                labelWidth: 120,
              ),
              HrInfoRow(
                label: 'Check In',
                value: record.formattedCheckIn ?? '—',
                labelWidth: 120,
              ),
              HrInfoRow(
                label: 'Check Out',
                value: record.formattedCheckOut ?? '—',
                labelWidth: 120,
              ),
              HrInfoRow(
                label: 'Remarks',
                value: record.remarks ?? '—',
                labelWidth: 120,
              ),
              if (record.recordedBy != null)
                HrInfoRow(
                  label: 'Recorded By',
                  value: record.recordedBy!,
                  labelWidth: 120,
                ),
              if (record.createdAt != null)
                HrInfoRow(
                  label: 'Created At',
                  value:
                      '${record.createdAt!.year}-${record.createdAt!.month.toString().padLeft(2, '0')}-${record.createdAt!.day.toString().padLeft(2, '0')}',
                  labelWidth: 120,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('attendance_details_close_button'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
