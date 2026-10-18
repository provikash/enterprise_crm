import 'package:flutter/material.dart';
import '../../domain/entities/dispatch_status.dart';

/// Modal dialog enabling dispatchers to transition a dispatch order's status with optional remarks.
class UpdateDispatchStatusDialog extends StatefulWidget {
  final DispatchStatus currentStatus;
  final ValueChanged<({DispatchStatus newStatus, String? remarks})> onUpdate;

  const UpdateDispatchStatusDialog({
    super.key,
    required this.currentStatus,
    required this.onUpdate,
  });

  @override
  State<UpdateDispatchStatusDialog> createState() => _UpdateDispatchStatusDialogState();
}

class _UpdateDispatchStatusDialogState extends State<UpdateDispatchStatusDialog> {
  late DispatchStatus _selectedStatus;
  final TextEditingController _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default to next status in pipeline if available, otherwise current
    final milestones = [
      DispatchStatus.pending,
      DispatchStatus.packed,
      DispatchStatus.inTransit,
      DispatchStatus.outForDelivery,
      DispatchStatus.delivered,
    ];
    final idx = milestones.indexOf(widget.currentStatus);
    if (idx >= 0 && idx < milestones.length - 1) {
      _selectedStatus = milestones[idx + 1];
    } else {
      _selectedStatus = widget.currentStatus;
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Dispatch Status'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Current Status: ${widget.currentStatus.displayName}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select New Status:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<DispatchStatus>(
              key: const Key('dispatch_status_dropdown'),
              isExpanded: true,
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: DispatchStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.displayName),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedStatus = val;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('dispatch_status_remarks_input'),
              controller: _remarksController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Remarks / Notes (Optional)',
                hintText: 'e.g. Handed over to carrier, delivered to gate 4',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('cancel_status_update_button'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('confirm_status_update_button'),
          onPressed: () {
            final remarks = _remarksController.text.trim();
            widget.onUpdate((
              newStatus: _selectedStatus,
              remarks: remarks.isEmpty ? null : remarks,
            ));
            Navigator.of(context).pop();
          },
          child: const Text('Update Status'),
        ),
      ],
    );
  }
}
