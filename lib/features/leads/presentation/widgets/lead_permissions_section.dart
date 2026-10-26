import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/domain/policies/crm_permissions.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/lead.dart';
import '../utils/lead_display_formatters.dart';

/// Reusable section displaying the access control policy, permissions, and effective user access for a Lead.
class LeadPermissionsSection extends StatelessWidget {
  final Lead lead;
  final CurrentUser? currentUser;

  const LeadPermissionsSection({
    super.key,
    required this.lead,
    this.currentUser,
  });

  CurrentUser? _resolveUser(BuildContext context) {
    if (currentUser != null) return currentUser;
    try {
      final authState = context.read<AuthCubit?>()?.state;
      if (authState is AuthAuthenticated) {
        return authState.user;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = _resolveUser(context);

    final isAssigned = lead.isAssigned;
    final badgeText = isAssigned ? 'Role & Assignee Scoped' : 'Admin Only';
    final badgeBg = isAssigned
        ? colorScheme.secondaryContainer
        : colorScheme.surfaceContainerHighest;
    final badgeFg = isAssigned
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;

    // Resolve user effective access
    String userAccessText;
    String userBadgeLabel;
    Color userBadgeBg;
    Color userBadgeFg;

    if (user == null || user.isAdmin) {
      userAccessText = 'Administrator (Unrestricted access)';
      userBadgeLabel = 'Full Access';
      userBadgeBg = colorScheme.primaryContainer;
      userBadgeFg = colorScheme.onPrimaryContainer;
    } else {
      final isAssignedToUser =
          isAssigned && lead.assignedUserId == user.id;

      if (isAssignedToUser) {
        final canEdit = user.permissions.contains(CrmPermissions.leadUpdate);
        if (canEdit) {
          userAccessText = 'Assigned Editor (Contact info modifiable)';
          userBadgeLabel = 'Editor';
          userBadgeBg = colorScheme.tertiaryContainer;
          userBadgeFg = colorScheme.onTertiaryContainer;
        } else {
          userAccessText = 'Assigned Viewer (Read-only access)';
          userBadgeLabel = 'Viewer';
          userBadgeBg = colorScheme.secondaryContainer;
          userBadgeFg = colorScheme.onSecondaryContainer;
        }
      } else if (user.permissions.contains(CrmPermissions.leadViewAll)) {
        final canEdit = user.permissions.contains(CrmPermissions.leadUpdate);
        if (canEdit) {
          userAccessText = 'Global Editor (All leads modifiable)';
          userBadgeLabel = 'Editor';
          userBadgeBg = colorScheme.tertiaryContainer;
          userBadgeFg = colorScheme.onTertiaryContainer;
        } else {
          userAccessText = 'Global Viewer (All leads readable)';
          userBadgeLabel = 'Viewer';
          userBadgeBg = colorScheme.secondaryContainer;
          userBadgeFg = colorScheme.onSecondaryContainer;
        }
      } else {
        userAccessText = 'Restricted (Not assigned to your account)';
        userBadgeLabel = 'Restricted';
        userBadgeBg = colorScheme.errorContainer;
        userBadgeFg = colorScheme.onErrorContainer;
      }
    }

    return Card(
      key: const Key('lead_permissions_section'),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Access & Permissions',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText,
                      key: const Key('lead_permissions_badge'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: badgeFg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Rows
            _buildRow(
              context: context,
              label: 'Access Model',
              value: 'RBAC & Assignee Ownership',
              icon: Icons.security_outlined,
              valueKey: const Key('lead_permissions_access_model'),
            ),
            _buildRow(
              context: context,
              label: 'Visibility Scope',
              value: isAssigned
                  ? 'Admin & Assigned (${formatLeadAssignee(lead)})'
                  : 'Restricted (Admin only until assigned)',
              icon: Icons.visibility_outlined,
              valueKey: const Key('lead_permissions_visibility_scope'),
            ),
            _buildRow(
              context: context,
              label: 'Edit Policy',
              value: isAssigned
                  ? 'Admin (Full) · Assignee (Contact fields only)'
                  : 'Admin (Full access)',
              icon: Icons.edit_outlined,
              valueKey: const Key('lead_permissions_edit_permissions'),
            ),
            _buildRow(
              context: context,
              label: 'Lead Assignment',
              value: 'Admin Only (Reassign & Allocate)',
              icon: Icons.person_pin_outlined,
              valueKey: const Key('lead_permissions_assignment_control'),
            ),
            _buildRow(
              context: context,
              label: 'Permissions',
              value:
                  '${CrmPermissions.leadViewAssigned}, ${CrmPermissions.leadUpdate}',
              icon: Icons.vpn_key_outlined,
              valueKey: const Key('lead_permissions_required_grants'),
            ),
            _buildRow(
              context: context,
              label: 'Your Access',
              value: userAccessText,
              icon: Icons.badge_outlined,
              valueKey: const Key('lead_permissions_effective_access'),
              trailingBadge: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: userBadgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  userBadgeLabel,
                  key: const Key('lead_permissions_effective_badge'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: userBadgeFg,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    Key? valueKey,
    Widget? trailingBadge,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  key: valueKey,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (trailingBadge != null) ...[
                  const SizedBox(height: 4),
                  trailingBadge,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
