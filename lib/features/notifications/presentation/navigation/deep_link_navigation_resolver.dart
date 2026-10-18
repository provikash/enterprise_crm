import 'package:flutter/material.dart';
import '../../../../features/approvals/data/repositories/mock_approval_repository.dart';
import '../../../../features/approvals/domain/repositories/approval_repository.dart';
import '../../../../features/approvals/presentation/screens/approval_detail_screen.dart';
import '../../../../features/auth/domain/entities/current_user.dart';
import '../../domain/entities/crm_notification.dart';

/// Pure, decoupled navigation resolver that handles deep links from in-app notifications.
class DeepLinkNavigationResolver {
  /// Resolves the target screen for [notification] and navigates to it if supported.
  ///
  /// Returns `true` if navigation was resolved and handled, `false` otherwise.
  static bool resolve(
    BuildContext context, {
    required CrmNotification notification,
    required CurrentUser user,
    ApprovalRepository? approvalRepository,
  }) {
    final entityType = notification.referenceEntityType;
    final entityId = notification.referenceEntityId;

    if (entityId == null || entityId.isEmpty) {
      return false;
    }

    // 1. Approval Request Deep Link
    if (entityType == 'approval_request' ||
        notification.category.name.toLowerCase().contains('approval')) {
      final repo = approvalRepository ?? MockApprovalRepository();

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ApprovalDetailScreen(
            requestId: entityId,
            user: user,
            repository: repo,
          ),
        ),
      );
      return true;
    }

    // 2. Fallback for other domain entity types (Purchase, HR, Inventory, Vendor)
    // When deep linking to other modules is not yet configured, show informative feedback.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Target reference: ${notification.referenceModule?.name ?? entityType} ($entityId)',
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    return true;
  }
}
