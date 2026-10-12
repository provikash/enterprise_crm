import 'package:enterprise_crm/features/dispatch/data/repositories/mock_dispatch_repository.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_filter_query.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_record.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_status.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_summary.dart';
import 'package:enterprise_crm/features/dispatch/domain/inputs/create_dispatch_input.dart';
import 'package:enterprise_crm/features/dispatch/domain/repositories/dispatch_repository.dart';
import 'package:enterprise_crm/features/dispatch/presentation/bloc/dispatch_list_cubit.dart';
import 'package:enterprise_crm/features/dispatch/presentation/bloc/dispatch_list_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingDispatchRepository implements DispatchRepository {
  @override
  Future<List<DispatchRecord>> getDispatches({DispatchFilterQuery? query}) {
    throw Exception('Database connection failure');
  }

  @override
  Future<int> getDispatchesCount({DispatchFilterQuery? query}) {
    throw Exception('Database connection failure');
  }

  @override
  Future<DispatchRecord?> getDispatchById(String id) async => null;

  @override
  Future<DispatchRecord> createDispatch(CreateDispatchInput input) {
    throw UnimplementedError();
  }

  @override
  Future<DispatchRecord> updateDispatchStatus(
    String id,
    DispatchStatus newStatus, {
    String? remarks,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<DispatchSummary> getSummary() {
    throw Exception('Summary calculation failed');
  }
}

void main() {
  group('DispatchListCubit Tests', () {
    late MockDispatchRepository repository;
    late DispatchListCubit cubit;

    setUp(() {
      repository = MockDispatchRepository();
      cubit = DispatchListCubit(repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is DispatchListInitial', () {
      expect(cubit.state, isA<DispatchListInitial>());
      expect(cubit.state.query.page, equals(1));
    });

    test('loadDispatches emits [DispatchListLoading, DispatchListLoaded] on success', () async {
      final states = <DispatchListState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.loadDispatches();
      await Future<void>.delayed(Duration.zero);

      expect(states.length, equals(2));
      expect(states[0], isA<DispatchListLoading>());
      expect(states[1], isA<DispatchListLoaded>());

      final loaded = states[1] as DispatchListLoaded;
      expect(loaded.dispatches.isNotEmpty, isTrue);
      expect(loaded.totalCount, greaterThan(0));
      expect(loaded.summary.totalDispatches, equals(loaded.totalCount));

      await subscription.cancel();
    });

    test('updateSearch filters records and resets page to 1', () async {
      await cubit.loadDispatches();

      cubit.updateSearch('DSP-2026-001');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<DispatchListLoaded>());
      final loaded = cubit.state as DispatchListLoaded;
      expect(loaded.query.searchText, equals('DSP-2026-001'));
      expect(loaded.query.page, equals(1));
      expect(loaded.dispatches.length, equals(1));
      expect(loaded.dispatches.first.dispatchCode, equals('DSP-2026-001'));
    });

    test('updateStatusFilter filters records by DispatchStatus', () async {
      await cubit.loadDispatches();

      cubit.updateStatusFilter(DispatchStatus.delivered);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<DispatchListLoaded>());
      final loaded = cubit.state as DispatchListLoaded;
      expect(loaded.query.status, equals(DispatchStatus.delivered));
      for (final dispatch in loaded.dispatches) {
        expect(dispatch.status, equals(DispatchStatus.delivered));
      }
    });

    test('updatePage advances page and triggers re-fetch', () async {
      await cubit.loadDispatches();

      cubit.updatePage(2);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.query.page, equals(2));
    });

    test('loadDispatches emits DispatchListFailure when repository throws', () async {
      final failingRepo = _FailingDispatchRepository();
      final failingCubit = DispatchListCubit(failingRepo);

      final states = <DispatchListState>[];
      final subscription = failingCubit.stream.listen(states.add);

      await failingCubit.loadDispatches();
      await Future<void>.delayed(Duration.zero);

      expect(states.length, equals(2));
      expect(states[0], isA<DispatchListLoading>());
      expect(states[1], isA<DispatchListFailure>());
      expect(
        (states[1] as DispatchListFailure).message,
        contains('Summary calculation failed'),
      );

      await subscription.cancel();
      await failingCubit.close();
    });
  });
}
