import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/purchase/data/repositories/mock_purchase_repository.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_filter_query.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_record.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_status.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_summary.dart';
import 'package:enterprise_crm/features/purchase/domain/inputs/create_purchase_order_input.dart';
import 'package:enterprise_crm/features/purchase/domain/repositories/purchase_repository.dart';
import 'package:enterprise_crm/features/purchase/presentation/bloc/purchase_list_cubit.dart';
import 'package:enterprise_crm/features/purchase/presentation/bloc/purchase_list_state.dart';

class _FailingPurchaseRepository implements PurchaseRepository {
  @override
  Future<List<PurchaseOrderRecord>> getPurchaseOrders({PurchaseFilterQuery? query}) {
    throw Exception('Database query failure');
  }

  @override
  Future<int> getPurchaseOrdersCount({PurchaseFilterQuery? query}) {
    throw Exception('Database count failure');
  }

  @override
  Future<PurchaseOrderRecord?> getPurchaseOrderById(String id) async => null;

  @override
  Future<PurchaseOrderRecord> createPurchaseOrder(CreatePurchaseOrderInput input) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrderRecord> updatePurchaseOrderStatus(
    String id,
    PurchaseOrderStatus newStatus, {
    String? notes,
    String? approvedBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrderRecord> receiveItems(
    String id,
    Map<String, int> receivedQuantities,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseSummary> getSummary() {
    throw Exception('Summary calculation failed');
  }
}

void main() {
  group('PurchaseListCubit Tests', () {
    late MockPurchaseRepository repository;
    late PurchaseListCubit cubit;

    setUp(() {
      repository = MockPurchaseRepository();
      cubit = PurchaseListCubit(repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is PurchaseListInitial', () {
      expect(cubit.state, isA<PurchaseListInitial>());
      expect(cubit.state.query, const PurchaseFilterQuery());
    });

    test('loadOrders emits [PurchaseListLoading, PurchaseListLoaded] on success', () async {
      final states = <PurchaseListState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.loadOrders();
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<PurchaseListLoading>());
      expect(states[1], isA<PurchaseListLoaded>());

      final loaded = states[1] as PurchaseListLoaded;
      expect(loaded.orders.isNotEmpty, true);
      expect(loaded.totalCount, 6);
      expect(loaded.summary.totalOrders, 6);

      await subscription.cancel();
    });

    test('updateSearch filters records and resets page to 1', () async {
      await cubit.loadOrders();

      cubit.updateSearch('Apex');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<PurchaseListLoaded>());
      final loaded = cubit.state as PurchaseListLoaded;
      expect(loaded.query.searchText, 'Apex');
      expect(loaded.query.page, 1);
      expect(loaded.orders.isNotEmpty, true);
      for (final po in loaded.orders) {
        expect(po.vendorName.toLowerCase().contains('apex'), true);
      }
    });

    test('updateStatusFilter filters records by PurchaseOrderStatus', () async {
      await cubit.loadOrders();

      cubit.updateStatusFilter(PurchaseOrderStatus.pendingApproval);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<PurchaseListLoaded>());
      final loaded = cubit.state as PurchaseListLoaded;
      expect(loaded.query.status, PurchaseOrderStatus.pendingApproval);
      expect(loaded.query.page, 1);
      for (final po in loaded.orders) {
        expect(po.status, PurchaseOrderStatus.pendingApproval);
      }
    });

    test('updatePage advances page and triggers re-fetch', () async {
      await cubit.loadOrders();

      cubit.updatePage(2);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.query.page, 2);
    });

    test('clearFilters resets search text and status to null', () async {
      cubit.updateSearch('Supplies');
      cubit.updateStatusFilter(PurchaseOrderStatus.ordered);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.query.searchText, 'Supplies');
      expect(cubit.state.query.status, PurchaseOrderStatus.ordered);

      cubit.clearFilters();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.query.searchText, isNull);
      expect(cubit.state.query.status, isNull);
      expect(cubit.state.query.page, 1);
    });

    test('loadOrders emits PurchaseListFailure when repository throws', () async {
      final failingRepo = _FailingPurchaseRepository();
      final failingCubit = PurchaseListCubit(failingRepo);

      final states = <PurchaseListState>[];
      final subscription = failingCubit.stream.listen(states.add);

      await failingCubit.loadOrders();
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<PurchaseListLoading>());
      expect(states[1], isA<PurchaseListFailure>());
      expect(
        (states[1] as PurchaseListFailure).message,
        contains('Summary calculation failed'),
      );

      await subscription.cancel();
      await failingCubit.close();
    });
  });
}
