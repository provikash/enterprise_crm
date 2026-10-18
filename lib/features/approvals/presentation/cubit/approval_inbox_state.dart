import 'package:flutter/foundation.dart';
import '../../../../features/auth/domain/entities/crm_module.dart';
import '../../domain/entities/approval_priority.dart';
import '../../domain/entities/approval_request.dart';
import '../../domain/entities/approval_status.dart';
import 'approval_inbox_tab.dart';

/// Sealed hierarchy of states for the Approval Inbox.
sealed class ApprovalInboxState {
  const ApprovalInboxState();
}

/// Initial uninitialized state.
final class ApprovalInboxInitial extends ApprovalInboxState {
  const ApprovalInboxInitial();
}

/// Loading state indicating data retrieval in progress.
final class ApprovalInboxLoading extends ApprovalInboxState {
  const ApprovalInboxLoading();
}

/// Loaded state with requests and filtering criteria.
@immutable
final class ApprovalInboxLoaded extends ApprovalInboxState {
  final List<ApprovalRequest> allRequests;
  final ApprovalInboxTab selectedTab;
  final CrmModule? selectedModule;
  final ApprovalPriority? selectedPriority;
  final String searchQuery;
  final String? currentUserId;

  const ApprovalInboxLoaded({
    required this.allRequests,
    this.selectedTab = ApprovalInboxTab.pending,
    this.selectedModule,
    this.selectedPriority,
    this.searchQuery = '',
    this.currentUserId,
  });

  /// The filtered list of requests reflecting active tab, module, priority, and search filters.
  List<ApprovalRequest> get filteredRequests {
    return allRequests.where((req) {
      // 1. Tab filter
      switch (selectedTab) {
        case ApprovalInboxTab.pending:
          if (req.status != ApprovalStatus.pending &&
              req.status != ApprovalStatus.revisionRequested) {
            return false;
          }
        case ApprovalInboxTab.approved:
          if (req.status != ApprovalStatus.approved) {
            return false;
          }
        case ApprovalInboxTab.rejected:
          if (req.status != ApprovalStatus.rejected &&
              req.status != ApprovalStatus.cancelled) {
            return false;
          }
        case ApprovalInboxTab.mySubmissions:
          if (currentUserId != null && !_matchesUserActivity(req, currentUserId!)) {
            return false;
          }
      }

      // 2. Module filter
      if (selectedModule != null && req.module != selectedModule) {
        return false;
      }

      // 3. Priority filter
      if (selectedPriority != null && req.priority != selectedPriority) {
        return false;
      }

      // 4. Substring search query
      final query = searchQuery.trim().toLowerCase();
      if (query.isNotEmpty) {
        final matchesNumber = req.requestNumber.toLowerCase().contains(query);
        final matchesTitle = req.entityTitle.toLowerCase().contains(query);
        final matchesRequester = req.requesterName.toLowerCase().contains(query);
        if (!matchesNumber && !matchesTitle && !matchesRequester) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  static bool _matchesUserActivity(ApprovalRequest req, String currentUserId) {
    // 1. Matches as requester
    if (_matchesRequester(req.requesterId, currentUserId)) return true;

    // 2. Matches as final decider (approved or rejected)
    if (req.decidedByUserId != null &&
        _matchesUserId(req.decidedByUserId!, currentUserId)) {
      return true;
    }

    // 3. Matches in step decisions
    if (req.steps.any((s) =>
        s.decidedByUserId != null &&
        _matchesUserId(s.decidedByUserId!, currentUserId))) {
      return true;
    }

    // 4. Matches in audit activities
    if (req.auditTrail.any((a) => _matchesUserId(a.actorUserId, currentUserId))) {
      return true;
    }

    return false;
  }

  static bool _matchesUserId(String targetId, String currentUserId) {
    final t = targetId.trim().toLowerCase();
    final c = currentUserId.trim().toLowerCase();
    if (t == c) return true;
    if ((c == 'admin' || c == 'usr_admin') && (t == 'admin' || t == 'usr_admin')) {
      return true;
    }
    if ((c == 'user' || c == 'usr_standard') && (t == 'user' || t == 'usr_standard')) {
      return true;
    }
    return false;
  }

  static bool _matchesRequester(String reqRequesterId, String currentUserId) {
    final r = reqRequesterId.trim().toLowerCase();
    final c = currentUserId.trim().toLowerCase();
    if (r == c) return true;
    if ((c == 'admin' || c == 'usr_admin') &&
        (r == 'admin' ||
            r == 'usr_admin' ||
            r == 'usr_admin_assistant')) {
      return true;
    }
    if ((c == 'user' || c == 'usr_standard') &&
        (r == 'user' || r == 'usr_standard')) {
      return true;
    }
    return false;
  }

  /// Total pending items across all modules.
  int get pendingCount => allRequests
      .where((r) =>
          r.status == ApprovalStatus.pending ||
          r.status == ApprovalStatus.revisionRequested)
      .length;

  /// Total approved items across all modules.
  int get approvedCount =>
      allRequests.where((r) => r.status == ApprovalStatus.approved).length;

  /// Total rejected or cancelled items across all modules.
  int get rejectedCount => allRequests
      .where((r) =>
          r.status == ApprovalStatus.rejected ||
          r.status == ApprovalStatus.cancelled)
      .length;

  /// Total submissions or decisions actioned by the current user.
  int get mySubmissionsCount => currentUserId != null
      ? allRequests.where((r) => _matchesUserActivity(r, currentUserId!)).length
      : 0;

  /// Creates a copy of this state with specified parameters overridden.
  ApprovalInboxLoaded copyWith({
    List<ApprovalRequest>? allRequests,
    ApprovalInboxTab? selectedTab,
    CrmModule? Function()? selectedModule,
    ApprovalPriority? Function()? selectedPriority,
    String? searchQuery,
    String? Function()? currentUserId,
  }) {
    return ApprovalInboxLoaded(
      allRequests: allRequests ?? this.allRequests,
      selectedTab: selectedTab ?? this.selectedTab,
      selectedModule:
          selectedModule != null ? selectedModule() : this.selectedModule,
      selectedPriority: selectedPriority != null
          ? selectedPriority()
          : this.selectedPriority,
      searchQuery: searchQuery ?? this.searchQuery,
      currentUserId:
          currentUserId != null ? currentUserId() : this.currentUserId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApprovalInboxLoaded &&
        listEquals(other.allRequests, allRequests) &&
        other.selectedTab == selectedTab &&
        other.selectedModule == selectedModule &&
        other.selectedPriority == selectedPriority &&
        other.searchQuery == searchQuery &&
        other.currentUserId == currentUserId;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(allRequests),
        selectedTab,
        selectedModule,
        selectedPriority,
        searchQuery,
        currentUserId,
      );
}

/// State emitted when request loading fails.
final class ApprovalInboxFailure extends ApprovalInboxState {
  final String message;

  const ApprovalInboxFailure(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApprovalInboxFailure && other.message == message;

  @override
  int get hashCode => message.hashCode;
}
