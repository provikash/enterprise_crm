import 'package:flutter/material.dart';
import '../../domain/entities/approval_action_type.dart';

/// Modal dialog for confirming approval actions (Approve, Reject, Request Revision, Cancel).
///
/// Strictly enforces non-empty comments for Rejection and Revision Requests.
class ApprovalActionDialog extends StatefulWidget {
  final ApprovalActionType actionType;
  final String requestNumber;
  final bool isSubmitting;
  final Future<void> Function(String? comment) onConfirm;

  const ApprovalActionDialog({
    super.key,
    required this.actionType,
    required this.requestNumber,
    this.isSubmitting = false,
    required this.onConfirm,
  });

  @override
  State<ApprovalActionDialog> createState() => _ApprovalActionDialogState();
}

class _ApprovalActionDialogState extends State<ApprovalActionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  bool _localSubmitting = false;

  bool get _isMandatoryReason =>
      widget.actionType == ApprovalActionType.rejected ||
      widget.actionType == ApprovalActionType.revisionRequested;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isMandatoryReason && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _localSubmitting = true);
    try {
      final comment = _commentController.text.trim();
      await widget.onConfirm(comment.isNotEmpty ? comment : null);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _localSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isBusy = widget.isSubmitting || _localSubmitting;

    final config = _dialogConfig(widget.actionType, colorScheme);

    return PopScope(
      canPop: !isBusy,
      child: AlertDialog(
        key: const Key('approval_action_dialog'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: config.color.withValues(alpha: 0.15),
              child: Icon(config.icon, size: 18, color: config.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                config.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${config.description} (${widget.requestNumber})',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('approval_dialog_comment_input'),
                  controller: _commentController,
                  enabled: !isBusy,
                  maxLines: 3,
                  autofocus: _isMandatoryReason,
                  decoration: InputDecoration(
                    labelText: _isMandatoryReason
                        ? '${config.commentLabel} *'
                        : config.commentLabel,
                    hintText: config.commentHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  ),
                  validator: (value) {
                    if (_isMandatoryReason) {
                      if (value == null || value.trim().isEmpty) {
                        return widget.actionType == ApprovalActionType.rejected
                            ? 'Rejection reason is required.'
                            : 'Revision notes are required.';
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            key: const Key('approval_dialog_cancel_btn'),
            onPressed: isBusy ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('approval_dialog_confirm_btn'),
            onPressed: isBusy ? null : _handleSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: config.color,
              foregroundColor: Colors.white,
            ),
            child: isBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(config.confirmButtonLabel),
          ),
        ],
      ),
    );
  }

  _ActionDialogConfig _dialogConfig(
    ApprovalActionType action,
    ColorScheme colorScheme,
  ) {
    switch (action) {
      case ApprovalActionType.approved:
        return _ActionDialogConfig(
          title: 'Approve Request',
          description: 'Are you sure you want to approve this workflow request?',
          confirmButtonLabel: 'Approve',
          commentLabel: 'Optional Remarks',
          commentHint: 'Add any sign-off notes or conditions...',
          color: Colors.green,
          icon: Icons.check_circle_outline,
        );
      case ApprovalActionType.rejected:
        return _ActionDialogConfig(
          title: 'Reject Request',
          description:
              'Rejecting this request will terminate the workflow. Please provide a clear justification.',
          confirmButtonLabel: 'Reject',
          commentLabel: 'Rejection Reason',
          commentHint: 'Explain why this request is being rejected...',
          color: Colors.red,
          icon: Icons.cancel_outlined,
        );
      case ApprovalActionType.revisionRequested:
        return _ActionDialogConfig(
          title: 'Request Revisions',
          description:
              'The request will be sent back to the submitter for adjustments.',
          confirmButtonLabel: 'Send Back',
          commentLabel: 'Revision Notes',
          commentHint: 'Specify the changes or corrections required...',
          color: Colors.orange.shade800,
          icon: Icons.replay,
        );
      case ApprovalActionType.cancelled:
        return _ActionDialogConfig(
          title: 'Cancel Request',
          description: 'Are you sure you want to withdraw and cancel this request?',
          confirmButtonLabel: 'Cancel Request',
          commentLabel: 'Cancellation Reason',
          commentHint: 'Optional reason for withdrawal...',
          color: Colors.grey.shade700,
          icon: Icons.block,
        );
      default:
        return _ActionDialogConfig(
          title: 'Confirm Action',
          description: 'Are you sure you want to proceed?',
          confirmButtonLabel: 'Confirm',
          commentLabel: 'Comments',
          commentHint: 'Add comments...',
          color: colorScheme.primary,
          icon: Icons.help_outline,
        );
    }
  }
}

class _ActionDialogConfig {
  final String title;
  final String description;
  final String confirmButtonLabel;
  final String commentLabel;
  final String commentHint;
  final Color color;
  final IconData icon;

  const _ActionDialogConfig({
    required this.title,
    required this.description,
    required this.confirmButtonLabel,
    required this.commentLabel,
    required this.commentHint,
    required this.color,
    required this.icon,
  });
}
