import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_priority.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_status.dart';
import 'package:enterprise_crm/features/approvals/data/mock/mock_approval_store.dart';
import 'package:enterprise_crm/features/approvals/data/repositories/mock_approval_repository.dart';
import 'package:enterprise_crm/features/approvals/presentation/cubit/approval_inbox_cubit.dart';
import 'package:enterprise_crm/features/approvals/presentation/cubit/approval_inbox_state.dart';
import 'package:enterprise_crm/features/approvals/presentation/cubit/approval_inbox_tab.dart';

void main() {
  group('ApprovalInboxCubit', () {
    late MockApprovalStore store;
    late MockApprovalRepository repository;
    late ApprovalInboxCubit cubit;

    setUp(() {
      store = MockApprovalStore();
      repository = MockApprovalRepository(store);
      cubit = ApprovalInboxCubit(repository, currentUserId: 'usr_buyer');
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is ApprovalInboxInitial', () {
      expect(cubit.state, const ApprovalInboxInitial());
    });

    test('loadApprovals emits Loading then Loaded with seeded requests', () async {
      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<ApprovalInboxLoading>(),
          isA<ApprovalInboxLoaded>(),
        ]),
      );

      await cubit.loadApprovals();
      await expectation;

      final loaded = cubit.state as ApprovalInboxLoaded;
      expect(loaded.allRequests.length, greaterThanOrEqualTo(6));
      expect(loaded.selectedTab, ApprovalInboxTab.pending);
      expect(loaded.currentUserId, 'usr_buyer');
    });

    test('tab switching filters requests accurately', () async {
      await cubit.loadApprovals();
      final loaded = cubit.state as ApprovalInboxLoaded;

      // Pending tab: requests with pending or revisionRequested
      expect(
        loaded.filteredRequests.every(
          (r) =>
              r.status == ApprovalStatus.pending ||
              r.status == ApprovalStatus.revisionRequested,
        ),
        isTrue,
      );

      // Approved tab
      cubit.setTab(ApprovalInboxTab.approved);
      final approvedState = cubit.state as ApprovalInboxLoaded;
      expect(approvedState.selectedTab, ApprovalInboxTab.approved);
      expect(
        approvedState.filteredRequests.every((r) => r.status == ApprovalStatus.approved),
        isTrue,
      );
      expect(approvedState.filteredRequests.isNotEmpty, isTrue);

      // Rejected tab
      cubit.setTab(ApprovalInboxTab.rejected);
      final rejectedState = cubit.state as ApprovalInboxLoaded;
      expect(rejectedState.selectedTab, ApprovalInboxTab.rejected);
      expect(
        rejectedState.filteredRequests.every(
          (r) =>
              r.status == ApprovalStatus.rejected ||
              r.status == ApprovalStatus.cancelled,
        ),
        isTrue,
      );

      // My Submissions tab
      cubit.setTab(ApprovalInboxTab.mySubmissions);
      final mySubmissionsState = cubit.state as ApprovalInboxLoaded;
      expect(mySubmissionsState.selectedTab, ApprovalInboxTab.mySubmissions);
      expect(
        mySubmissionsState.filteredRequests.every((r) => r.requesterId == 'usr_buyer'),
        isTrue,
      );
      expect(mySubmissionsState.filteredRequests.isNotEmpty, isTrue);
    });

    test('tab counts match state items', () async {
      await cubit.loadApprovals();
      final loaded = cubit.state as ApprovalInboxLoaded;

      expect(loaded.pendingCount, 3);
      expect(loaded.approvedCount, 2);
      expect(loaded.rejectedCount, 1);
      expect(loaded.mySubmissionsCount, 1);
    });

    test('module filtering restricts filteredRequests', () async {
      await cubit.loadApprovals();

      cubit.setModuleFilter(CrmModule.purchase);
      final state = cubit.state as ApprovalInboxLoaded;
      expect(state.selectedModule, CrmModule.purchase);
      expect(state.filteredRequests.every((r) => r.module == CrmModule.purchase), isTrue);
    });

    test('priority filtering restricts filteredRequests', () async {
      await cubit.loadApprovals();

      cubit.setPriorityFilter(ApprovalPriority.urgent);
      final state = cubit.state as ApprovalInboxLoaded;
      expect(state.selectedPriority, ApprovalPriority.urgent);
      expect(state.filteredRequests.length, 1);
      expect(state.filteredRequests.first.id, 'appr-001');
    });

    test('search query matches title, request number, or requester name', () async {
      await cubit.loadApprovals();

      cubit.setSearchQuery('REQ-2026-0001');
      var state = cubit.state as ApprovalInboxLoaded;
      expect(state.filteredRequests.length, 1);
      expect(state.filteredRequests.first.id, 'appr-001');

      cubit.setSearchQuery('John Doe');
      state = cubit.state as ApprovalInboxLoaded;
      expect(state.filteredRequests.length, 1);
      expect(state.filteredRequests.first.id, 'appr-002');
    });

    test('clearFilters resets module, priority, and search query', () async {
      await cubit.loadApprovals();
      cubit.setModuleFilter(CrmModule.purchase);
      cubit.setPriorityFilter(ApprovalPriority.urgent);
      cubit.setSearchQuery('Steel');

      cubit.clearFilters();
      final state = cubit.state as ApprovalInboxLoaded;
      expect(state.selectedModule, isNull);
      expect(state.selectedPriority, isNull);
      expect(state.searchQuery, isEmpty);
    });

    test('setCurrentUserId updates current user and filters for submissions', () async {
      await cubit.loadApprovals();
      cubit.setTab(ApprovalInboxTab.mySubmissions);
      expect((cubit.state as ApprovalInboxLoaded).filteredRequests.length, 1);

      cubit.setCurrentUserId('usr_jdoe');
      final state = cubit.state as ApprovalInboxLoaded;
      expect(state.currentUserId, 'usr_jdoe');
      expect(state.filteredRequests.first.id, 'appr-002');
    });
  });
}
