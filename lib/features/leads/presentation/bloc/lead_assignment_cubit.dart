import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/crm_module.dart';
import '../../../notifications/domain/entities/notification_priority.dart';
import '../../../notifications/domain/services/notification_dispatcher.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_assignee.dart';
import '../../domain/entities/lead_assignment_request.dart';
import '../../domain/repositories/lead_repository.dart';
import 'lead_assignment_state.dart';

/// Cubit managing assignable user loading and lead assignment operations.
class LeadAssignmentCubit extends Cubit<LeadAssignmentState> {
  final LeadRepository _repository;
  final NotificationDispatcher? _notificationDispatcher;

  LeadAssignmentCubit(
    this._repository, {
    NotificationDispatcher? notificationDispatcher,
  })  : _notificationDispatcher = notificationDispatcher,
        super(const LeadAssignmentState());

  /// Loads the list of assignable users from the repository.
  Future<void> loadAssignableUsers() async {
    emit(
      state.copyWith(
        loadStatus: AssigneeLoadStatus.loading,
        clearLoadErrorMessage: true,
      ),
    );

    try {
      final users = await _repository.getAssignableUsers();
      final userList = List<LeadAssignee>.unmodifiable(users);

      // Verify whether the currently selected assignee is still in the loaded list
      final selectedStillValid =
          state.selectedAssignee != null &&
          userList.any((u) => u.id == state.selectedAssignee!.id);

      emit(
        state.copyWith(
          loadStatus: AssigneeLoadStatus.success,
          assignees: userList,
          clearSelectedAssignee:
              !selectedStillValid && state.selectedAssignee != null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          loadStatus: AssigneeLoadStatus.failure,
          loadErrorMessage: 'Unable to load assignable users.',
        ),
      );
    }
  }

  /// Selects an assignee from the loaded assignable-user list.
  /// Rejects / ignores unknown assignees not present in the loaded list.
  void selectAssignee(LeadAssignee assignee) {
    final matchedIndex = state.assignees.indexWhere((a) => a.id == assignee.id);
    if (matchedIndex != -1) {
      emit(
        state.copyWith(
          selectedAssignee: state.assignees[matchedIndex],
          clearSubmissionErrorMessage: true,
        ),
      );
    }
  }

  /// Clears the current assignee selection without altering the lead repository.
  void clearSelectedAssignee() {
    emit(state.copyWith(clearSelectedAssignee: true));
  }

  /// Resets the submission status back to idle.
  void resetSubmission() {
    emit(
      state.copyWith(
        submissionStatus: AssignmentSubmissionStatus.idle,
        clearSubmissionErrorMessage: true,
      ),
    );
  }

  /// Assigns a single unassigned lead to the currently selected assignee.
  Future<void> assignLead({required Lead lead}) async {
    if (state.isSubmitting) return;

    if (state.selectedAssignee == null) {
      emit(
        state.copyWith(
          submissionStatus: AssignmentSubmissionStatus.failure,
          submissionErrorMessage: 'Select an assignee first.',
        ),
      );
      return;
    }

    if (lead.isAssigned) {
      emit(
        state.copyWith(
          submissionStatus: AssignmentSubmissionStatus.failure,
          submissionErrorMessage: 'Lead is already assigned.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        submissionStatus: AssignmentSubmissionStatus.submitting,
        clearSubmissionErrorMessage: true,
      ),
    );

    try {
      await _repository.assignLead(
        leadId: lead.id,
        assigneeId: state.selectedAssignee!.id,
      );

      final dispatcher = _notificationDispatcher;
      if (dispatcher != null) {
        final assigneeId = state.selectedAssignee?.id;
        if (assigneeId != null) {
          try {
            final leadTitle = lead.name ?? 'Lead #${lead.id}';
            await dispatcher.notifySystemAlert(
              recipientUserId: assigneeId,
              title: 'New Lead Assignment: $leadTitle',
              message: 'Lead "$leadTitle" has been assigned to you.',
              priority: NotificationPriority.info,
              module: CrmModule.leadManagement,
            );
          } catch (_) {
            // Non-blocking notification dispatch
          }
        }
      }

      emit(
        state.copyWith(submissionStatus: AssignmentSubmissionStatus.success),
      );
    } catch (_) {
      emit(
        state.copyWith(
          submissionStatus: AssignmentSubmissionStatus.failure,
          submissionErrorMessage: 'Unable to assign the Lead.',
        ),
      );
    }
  }

  /// Assigns multiple unassigned leads to the currently selected assignee in bulk.
  Future<void> assignLeads({required List<Lead> leads}) async {
    if (state.isSubmitting) return;

    if (state.selectedAssignee == null) {
      emit(
        state.copyWith(
          submissionStatus: AssignmentSubmissionStatus.failure,
          submissionErrorMessage: 'Select an assignee first.',
        ),
      );
      return;
    }

    if (leads.isEmpty) {
      emit(
        state.copyWith(
          submissionStatus: AssignmentSubmissionStatus.failure,
          submissionErrorMessage: 'Select at least one Lead to assign.',
        ),
      );
      return;
    }

    if (leads.any((lead) => lead.isAssigned)) {
      emit(
        state.copyWith(
          submissionStatus: AssignmentSubmissionStatus.failure,
          submissionErrorMessage: 'Cannot assign already-assigned Leads.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        submissionStatus: AssignmentSubmissionStatus.submitting,
        clearSubmissionErrorMessage: true,
      ),
    );

    try {
      final request = LeadAssignmentRequest(
        leadIds: leads.map((l) => l.id).toList(),
        assigneeId: state.selectedAssignee!.id,
      );
      await _repository.assignLeads(request);

      final dispatcher = _notificationDispatcher;
      if (dispatcher != null) {
        final assigneeId = state.selectedAssignee?.id;
        if (assigneeId != null) {
          try {
            await dispatcher.notifySystemAlert(
              recipientUserId: assigneeId,
              title: 'Bulk Lead Assignment',
              message: '${leads.length} leads have been assigned to your queue.',
              priority: NotificationPriority.info,
              module: CrmModule.leadManagement,
            );
          } catch (_) {
            // Non-blocking notification dispatch
          }
        }
      }

      emit(
        state.copyWith(submissionStatus: AssignmentSubmissionStatus.success),
      );
    } catch (_) {
      emit(
        state.copyWith(
          submissionStatus: AssignmentSubmissionStatus.failure,
          submissionErrorMessage: 'Unable to assign the selected Leads.',
        ),
      );
    }
  }
}
