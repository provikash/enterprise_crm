import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/approvals/data/mock/mock_approval_store.dart';
import 'package:enterprise_crm/features/approvals/data/repositories/mock_approval_repository.dart';
import 'package:enterprise_crm/features/approvals/presentation/cubit/approval_detail_cubit.dart';
import 'package:enterprise_crm/features/approvals/presentation/cubit/approval_detail_state.dart';

void main() {
  group('ApprovalDetailCubit', () {
    late MockApprovalStore store;
    late MockApprovalRepository repository;
    late ApprovalDetailCubit cubit;

    setUp(() {
      store = MockApprovalStore();
      repository = MockApprovalRepository(store);
      cubit = ApprovalDetailCubit(repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is ApprovalDetailInitial', () {
      expect(cubit.state, const ApprovalDetailInitial());
    });

    test('loadDetail emits Loading then Loaded for existing request', () async {
      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<ApprovalDetailLoading>(),
          isA<ApprovalDetailLoaded>(),
        ]),
      );

      await cubit.loadDetail('appr-001');
      await expectation;

      final loaded = cubit.state as ApprovalDetailLoaded;
      expect(loaded.request.id, 'appr-001');
      expect(loaded.auditTrail.length, 2);
      expect(loaded.steps.length, 2);
      expect(loaded.steps.first.title, 'Procurement Lead Review');
    });

    test('loadDetail emits Failure when request is not found', () async {
      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<ApprovalDetailLoading>(),
          isA<ApprovalDetailFailure>(),
        ]),
      );

      await cubit.loadDetail('non-existent-id');
      await expectation;

      final failure = cubit.state as ApprovalDetailFailure;
      expect(failure.message, contains('not found'));
    });

    test('refresh reloads active request details', () async {
      await cubit.loadDetail('appr-002');
      expect(cubit.state, isA<ApprovalDetailLoaded>());

      await cubit.refresh();
      expect(cubit.state, isA<ApprovalDetailLoaded>());
      final loaded = cubit.state as ApprovalDetailLoaded;
      expect(loaded.request.id, 'appr-002');
    });
  });
}
