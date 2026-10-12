import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../user_management/domain/repositories/user_management_repository.dart';
import 'account_profile_dialog.dart';

/// Application header displayed across authenticated CRM dashboards.
///
/// Places the account avatar in the top right corner, providing profile
/// management, non-editable User ID display, password reset, and logout options.
class CrmAppHeader extends StatelessWidget {
  final CurrentUser user;
  final VoidCallback onLogout;
  final UserManagementRepository? userManagementRepository;

  const CrmAppHeader({
    super.key,
    required this.user,
    required this.onLogout,
    this.userManagementRepository,
  });

  void _openAccountDialog(BuildContext context) {
    UserManagementRepository? repo = userManagementRepository;
    if (repo == null) {
      try {
        repo = context.read<UserManagementRepository?>();
      } catch (_) {
        try {
          repo = context.read<UserManagementRepository>();
        } catch (_) {}
      }
    }

    AccountProfileDialog.show(
      context,
      user: user,
      onLogout: onLogout,
      userManagementRepository: repo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              const Spacer(),

              // Right side: Display Name (if not narrow)
              if (!isNarrow && user.displayName.isNotEmpty) ...[
                Text(
                  user.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 10),
              ],

              // Top Right Corner: Account Avatar
              Tooltip(
                message: 'Account Profile & Settings',
                child: InkWell(
                  key: const Key('home_account_avatar'),
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _openAccountDialog(context),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: CircleAvatar(
                      key: const Key('account_avatar_button'),
                      radius: 16,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        user.displayName.isNotEmpty
                            ? user.displayName.substring(0, 1).toUpperCase()
                            : 'U',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Logout Button
              IconButton(
                key: const Key('crm_header_logout_button'),
                icon: const Icon(Icons.logout, size: 20),
                tooltip: 'Logout',
                onPressed: onLogout,
              ),
            ],
          ),
        );
      },
    );
  }
}
