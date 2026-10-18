import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/domain/entities/crm_module.dart';
import '../../domain/entities/approval_priority.dart';
import '../../domain/repositories/approval_repository.dart';
import 'approval_inbox_state.dart';
import 'approval_inbox_tab.dart';

/// Cubit managing listing, multi-tab switching, filtering, and searching for the Approval Inbox.
class ApprovalInboxCubit extends Cubit<ApprovalInboxState> {
  final ApprovalRepository _repository;
  String? _currentUserId;
  int _loadSequence = 0;

  ApprovalInboxCubit(
    this._repository, {
    String? currentUserId,
  })  : _currentUserId = currentUserId,
        super(const ApprovalInboxInitial());

  /// Sets or updates the active user context for 'My Submissions'.
  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
    if (state is ApprovalInboxLoaded) {
      final loaded = state as ApprovalInboxLoaded;
      emit(loaded.copyWith(currentUserId: () => userId));
    }
  }

  /// Fetches approvals from the repository, with sequence protection.
  Future<void> loadApprovals({String? currentUserId}) async {
    if (currentUserId != null) {
      _currentUserId = currentUserId;
    }

    final seq = ++_loadSequence;

    final currentTab = state is ApprovalInboxLoaded
        ? (state as ApprovalInboxLoaded).selectedTab
        : ApprovalInboxTab.pending;
    final currentModule = state is ApprovalInboxLoaded
        ? (state as ApprovalInboxLoaded).selectedModule
        : null;
    final currentPriority = state is ApprovalInboxLoaded
        ? (state as ApprovalInboxLoaded).selectedPriority
        : null;
    final currentQuery = state is ApprovalInboxLoaded
        ? (state as ApprovalInboxLoaded).searchQuery
        : '';

    emit(const ApprovalInboxLoading());

    try {
      final requests = await _repository.getApprovals();

      // Guard against race conditions and closed cubit.
      if (isClosed || seq != _loadSequence) return;

      emit(
        ApprovalInboxLoaded(
          allRequests: requests,
          selectedTab: currentTab,
          selectedModule: currentModule,
          selectedPriority: currentPriority,
          searchQuery: currentQuery,
          currentUserId: _currentUserId,
        ),
      );
    } catch (e) {
      if (isClosed || seq != _loadSequence) return;
      emit(ApprovalInboxFailure('Failed to load approvals: ${e.toString()}'));
    }
  }

  /// Refreshes current approval list while retaining existing filter and tab parameters.
  Future<void> refresh() async {
    await loadApprovals();
  }

  /// Switches the active inbox tab.
  void setTab(ApprovalInboxTab tab) {
    if (state is ApprovalInboxLoaded) {
      final loaded = state as ApprovalInboxLoaded;
      emit(loaded.copyWith(selectedTab: tab));
    }
  }

  /// Filters approvals by CRM module (null clears filter).
  void setModuleFilter(CrmModule? module) {
    if (state is ApprovalInboxLoaded) {
      final loaded = state as ApprovalInboxLoaded;
      emit(loaded.copyWith(selectedModule: () => module));
    }
  }

  /// Filters approvals by urgency priority (null clears filter).
  void setPriorityFilter(ApprovalPriority? priority) {
    if (state is ApprovalInboxLoaded) {
      final loaded = state as ApprovalInboxLoaded;
      emit(loaded.copyWith(selectedPriority: () => priority));
    }
  }

  /// Filters approvals by substring text query across ID, title, and requester name.
  void setSearchQuery(String query) {
    if (state is ApprovalInboxLoaded) {
      final loaded = state as ApprovalInboxLoaded;
      emit(loaded.copyWith(searchQuery: query));
    }
  }

  /// Clears active module, priority, and text search filters.
  void clearFilters() {
    if (state is ApprovalInboxLoaded) {
      final loaded = state as ApprovalInboxLoaded;
      emit(
        loaded.copyWith(
          selectedModule: () => null,
          selectedPriority: () => null,
          searchQuery: '',
        ),
      );
    }
  }
}
