import 'package:flutter/material.dart';

class PayrollSkeleton extends StatelessWidget {
  final int rows;
  const PayrollSkeleton({super.key, this.rows = 5});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Semantics(
      label: 'Loading',
      child: Column(
        children: List.generate(
          rows,
          (_) => Container(
            height: 52,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

class PermissionDeniedState extends StatelessWidget {
  final String message;
  const PermissionDeniedState({
    super.key,
    this.message = 'You do not have permission to view this payroll data.',
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class LockedBanner extends StatelessWidget {
  final String message;
  const LockedBanner({
    super.key,
    this.message = 'This payroll period is locked. Editing is disabled.',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: message,
      child: MaterialBanner(
        leading: const Icon(Icons.lock_outline),
        content: Text(message),
        backgroundColor: scheme.secondaryContainer,
        actions: const [SizedBox.shrink()],
      ),
    );
  }
}

class ConflictReloadDialog extends StatelessWidget {
  final String message;
  const ConflictReloadDialog({
    super.key,
    this.message =
        'This item was updated by someone else. Reload the latest version?',
  });

  static Future<bool> show(BuildContext context, {String? message}) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => ConflictReloadDialog(
          message:
              message ??
              'This item was updated by someone else. Reload the latest version?',
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Update conflict'),
    content: Text(message),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Reload'),
      ),
    ],
  );
}
