import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/entities/crm_module.dart';
import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/domain/policies/access_policy.dart';
import '../../../auth/domain/policies/crm_permissions.dart';
import '../../../auth/domain/repositories/user_lead_link_repository.dart';
import '../../../leads/domain/repositories/lead_repository.dart';
import '../../domain/policies/user_calling_policy.dart';
import '../../domain/repositories/lead_call_activity_repository.dart';
import 'lead_call_history_state.dart';

/// Cubit managing loading and state for lead call history.
///
/// Enforces complete authorization chain before querying the repository:
/// Calling module -> calling.use -> Lead module -> lead.view_assigned -> link -> validate assignee -> fresh Lead -> ownership.
class LeadCallHistoryCubit extends Cubit<LeadCallHistoryState> {
  final CurrentUser _user;
  final String _leadId;
  final UserLeadLinkRepository _linkRepository;
  final LeadRepository _leadRepository;
  final LeadCallActivityRepository _callActivityRepository;

  LeadCallHistoryCubit({
    required CurrentUser user,
    required String leadId,
    required UserLeadLinkRepository linkRepository,
    required LeadRepository leadRepository,
    required LeadCallActivityRepository callActivityRepository,
  }) : _user = user,
       _leadId = leadId,
       _linkRepository = linkRepository,
       _leadRepository = leadRepository,
       _callActivityRepository = callActivityRepository,
       super(const LeadCallHistoryInitial());

  /// Loads call history for the authorized lead.
  Future<void> loadHistory() async {
    emit(const LeadCallHistoryLoading());

    // 1. Calling module guard
    if (!AccessPolicy.canAccessModule(_user, CrmModule.calling)) {
      emit(const LeadCallHistoryAccessDenied('Calling module not assigned.'));
      return;
    }

    // 2. calling.use / calling.history.view permission guard
    final hasCallingPerm =
        AccessPolicy.hasPermission(_user, CrmPermissions.callingUse) ||
        AccessPolicy.hasPermission(_user, CrmPermissions.callingHistoryView);
    if (!hasCallingPerm) {
      emit(
        const LeadCallHistoryAccessDenied(
          'calling.use permission not granted.',
        ),
      );
      return;
    }

    // 3. Lead Management module guard
    if (!AccessPolicy.canAccessModule(_user, CrmModule.leadManagement)) {
      emit(
        const LeadCallHistoryAccessDenied(
          'Lead Management module not assigned.',
        ),
      );
      return;
    }

    // 4. lead view permission guard
    final hasLeadView =
        AccessPolicy.hasPermission(_user, CrmPermissions.leadViewAssigned) ||
        AccessPolicy.hasPermission(_user, CrmPermissions.leadViewAll);
    if (!hasLeadView) {
      emit(
        const LeadCallHistoryAccessDenied(
          'lead.view_assigned permission not granted.',
        ),
      );
      return;
    }

    try {
      // 5. Resolve identity link
      final link = await _linkRepository.getLinkForUser(_user.id);
      if (!_user.isAdmin && link == null) {
        emit(
          const LeadCallHistoryAccessDenied(
            'User is not linked to an assignee identity.',
          ),
        );
        return;
      }

      // 6. Validate assignee identity exists
      if (link != null) {
        final assignees = await _leadRepository.getAssignableUsers();
        final assigneeExists = assignees.any((a) => a.id == link.leadAssigneeId);
        if (!_user.isAdmin && !assigneeExists) {
          emit(
            const LeadCallHistoryAccessDenied('Assigned identity is invalid.'),
          );
          return;
        }
      }

      // 7. Fresh Lead retrieval
      final freshLead = await _leadRepository.getLeadById(_leadId);
      if (freshLead == null) {
        emit(const LeadCallHistoryAccessDenied('Lead not found.'));
        return;
      }

      // 8. Strict ownership check
      if (!UserCallingPolicy.canViewLeadHistory(
        user: _user,
        lead: freshLead,
        linkedAssigneeId: link?.leadAssigneeId,
      )) {
        emit(
          const LeadCallHistoryAccessDenied(
            'Access restricted to assigned leads only.',
          ),
        );
        return;
      }

      // 9. Query call history
      final activities = await _callActivityRepository.getActivitiesForLead(
        _leadId,
      );

      if (activities.isEmpty) {
        emit(const LeadCallHistoryEmpty());
      } else {
        emit(LeadCallHistoryLoaded(activities));
      }
    } catch (_) {
      emit(const LeadCallHistoryFailure('Unable to load call history.'));
    }
  }
}
