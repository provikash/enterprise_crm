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
          if (currentUserId != null && req.requesterId != currentUserId) {
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

  /// Total submissions created by the current user.
  int get mySubmissionsCount => currentUserId != null
      ? allRequests.where((r) => r.requesterId == currentUserId).length
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
