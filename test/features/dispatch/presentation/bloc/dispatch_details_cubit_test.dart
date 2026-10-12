import 'package:enterprise_crm/features/dispatch/data/repositories/mock_dispatch_repository.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_record.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_status.dart';
import 'package:enterprise_crm/features/dispatch/presentation/bloc/dispatch_details_cubit.dart';
import 'package:enterprise_crm/features/dispatch/presentation/bloc/dispatch_details_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingUpdateRepo extends MockDispatchRepository {
  @override
  Future<DispatchRecord> updateDispatchStatus(
    String id,
    DispatchStatus newStatus, {
    String? remarks,
  }) {
    throw Exception('Failed to update status on server');
  }
}

void main() {
  group('DispatchDetailsCubit Tests', () {
    late MockDispatchRepository repository;
    late DispatchDetailsCubit cubit;

    setUp(() {
      repository = MockDispatchRepository();
      cubit = DispatchDetailsCubit(repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is DispatchDetailsInitial', () {
      expect(cubit.state, isA<DispatchDetailsInitial>());
    });

    test('loadDispatch with existing ID emits [DispatchDetailsLoading, DispatchDetailsLoaded]', () async {
      final states = <DispatchDetailsState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.loadDispatch('dsp_001');
      await Future<void>.delayed(Duration.zero);

      expect(states.length, equals(2));
      expect(states[0], isA<DispatchDetailsLoading>());
      expect(states[1], isA<DispatchDetailsLoaded>());

      final loaded = states[1] as DispatchDetailsLoaded;
      expect(loaded.record.id, equals('dsp_001'));
      expect(loaded.record.dispatchCode, equals('DSP-2026-001'));
      expect(loaded.isUpdating, isFalse);

      await subscription.cancel();
    });

    test('loadDispatch with non-existent ID emits [DispatchDetailsLoading, DispatchDetailsFailure]', () async {
      final states = <DispatchDetailsState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.loadDispatch('dsp_non_existent');
      await Future<void>.delayed(Duration.zero);

      expect(states.length, equals(2));
      expect(states[0], isA<DispatchDetailsLoading>());
      expect(states[1], isA<DispatchDetailsFailure>());
      expect((states[1] as DispatchDetailsFailure).message, contains('not found'));

      await subscription.cancel();
    });

    test('updateStatus updates record and emits updated DispatchDetailsLoaded', () async {
      await cubit.loadDispatch('dsp_001');

      final states = <DispatchDetailsState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.updateStatus(
        DispatchStatus.delivered,
        remarks: 'Delivered successfully at destination warehouse',
      );
      await Future<void>.delayed(Duration.zero);

      expect(states.length, equals(2));
      expect((states[0] as DispatchDetailsLoaded).isUpdating, isTrue);
      expect((states[1] as DispatchDetailsLoaded).isUpdating, isFalse);

      final updated = states[1] as DispatchDetailsLoaded;
      expect(updated.record.status, equals(DispatchStatus.delivered));
      expect(updated.record.deliveredAt, isNotNull);

      await subscription.cancel();
    });

    test('updateStatus handles failure gracefully without discarding current record', () async {
      final failingRepo = _FailingUpdateRepo();
      final failingCubit = DispatchDetailsCubit(failingRepo);

      await failingCubit.loadDispatch('dsp_001');
      expect(failingCubit.state, isA<DispatchDetailsLoaded>());

      final states = <DispatchDetailsState>[];
      final subscription = failingCubit.stream.listen(states.add);

      await failingCubit.updateStatus(DispatchStatus.delivered);
      await Future<void>.delayed(Duration.zero);

      expect(states.length, equals(2));
      expect((states[0] as DispatchDetailsLoaded).isUpdating, isTrue);
      expect((states[1] as DispatchDetailsLoaded).isUpdating, isFalse);

      final errorState = states[1] as DispatchDetailsLoaded;
      expect(errorState.updateError, contains('Failed to update status'));
      expect(errorState.record.id, equals('dsp_001'));

      await subscription.cancel();
      await failingCubit.close();
    });
  });
}
