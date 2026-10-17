import 'package:flutter/material.dart';
import '../../../../features/auth/domain/entities/current_user.dart';
import '../../../../features/auth/presentation/screens/access_restricted_screen.dart';
import '../../domain/policies/approvals_access_policy.dart';
import '../../domain/repositories/approval_repository.dart';
import 'approval_history_export_screen.dart';
import 'approval_inbox_screen.dart';

/// Central workspace screen for Module 07 — Approvals & Notifications.
class ApprovalsWorkspaceScreen extends StatelessWidget {
  final CurrentUser user;
  final ApprovalRepository repository;

  const ApprovalsWorkspaceScreen({
    super.key,
    required this.user,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    if (!ApprovalsAccessPolicy.canAccessModule(user)) {
      return const AccessRestrictedScreen();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: const Key('approvals_workspace_scaffold'),
      appBar: AppBar(
        title: const Text('Approvals & Governance'),
        actions: [
          if (ApprovalsAccessPolicy.canExport(user))
            IconButton(
              key: const Key('workspace_export_history_button'),
              tooltip: 'Export & History',
              icon: const Icon(Icons.history_edu),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ApprovalHistoryExportScreen(
                      user: user,
                      repository: repository,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Workspace Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          Icons.verified_outlined,
                          color: colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Approvals Workspace',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'GOVERNANCE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Review pending workflows, multi-tier approvals, and decision audit logs.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Embedded Inbox Screen
            Expanded(
              child: ApprovalInboxScreen(
                user: user,
                repository: repository,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
