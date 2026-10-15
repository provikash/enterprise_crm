import 'package:flutter/material.dart';

class PayrollConfirmation {
  final bool confirmed;
  final String? reason;
  const PayrollConfirmation({required this.confirmed, this.reason});
}

class PayrollConfirmDialog extends StatefulWidget {
  final String title;
  final String consequence;
  final String confirmLabel;
  final bool reasonRequired;

  const PayrollConfirmDialog({
    super.key,
    required this.title,
    required this.consequence,
    this.confirmLabel = 'Confirm',
    this.reasonRequired = false,
  });

  static Future<PayrollConfirmation?> show(
    BuildContext context, {
    required String title,
    required String consequence,
    String confirmLabel = 'Confirm',
    bool reasonRequired = false,
  }) => showDialog<PayrollConfirmation>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PayrollConfirmDialog(
      title: title,
      consequence: consequence,
      confirmLabel: confirmLabel,
      reasonRequired: reasonRequired,
    ),
  );

  @override
  State<PayrollConfirmDialog> createState() => _PayrollConfirmDialogState();
}

class _PayrollConfirmDialogState extends State<PayrollConfirmDialog> {
  final _reasonController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.consequence),
        if (widget.reasonRequired) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            autofocus: true,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: _submitted
            ? null
            : () => Navigator.pop(
                context,
                const PayrollConfirmation(confirmed: false),
              ),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed:
            _submitted ||
                (widget.reasonRequired && _reasonController.text.trim().isEmpty)
            ? null
            : () {
                setState(() => _submitted = true);
                Navigator.pop(
                  context,
                  PayrollConfirmation(
                    confirmed: true,
                    reason: _reasonController.text.trim().isEmpty
                        ? null
                        : _reasonController.text.trim(),
                  ),
                );
              },
        child: Text(widget.confirmLabel),
      ),
    ],
  );
}
