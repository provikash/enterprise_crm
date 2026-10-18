import 'package:flutter_test/flutter_test.dart';

import 'package:enterprise_crm/features/purchase/data/repositories/mock_purchase_repository.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_status.dart';
import 'package:enterprise_crm/features/purchase/presentation/bloc/purchase_details_cubit.dart';
import 'package:enterprise_crm/features/purchase/presentation/bloc/purchase_details_state.dart';

void main() {
  group('PurchaseDetailsCubit Tests', () {
    late MockPurchaseRepository repository;
    late PurchaseDetailsCubit cubit;

    setUp(() {
      repository = MockPurchaseRepository();
      cubit = PurchaseDetailsCubit(repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is PurchaseDetailsInitial', () {
      expect(cubit.state, isA<PurchaseDetailsInitial>());
    });

    test('loadPurchaseOrder emits [Loading, Loaded] for existing order', () async {
      final states = <PurchaseDetailsState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.loadPurchaseOrder('po_001');
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<PurchaseDetailsLoading>());
      expect(states[1], isA<PurchaseDetailsLoaded>());

      final loaded = states[1] as PurchaseDetailsLoaded;
      expect(loaded.record.id, 'po_001');
      expect(loaded.record.poNumber, 'PO-2026-001');

      await subscription.cancel();
    });

    test('loadPurchaseOrder emits [Loading, Failure] when record not found', () async {
      final states = <PurchaseDetailsState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.loadPurchaseOrder('non_existent_id');
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<PurchaseDetailsLoading>());
      expect(states[1], isA<PurchaseDetailsFailure>());

      final failure = states[1] as PurchaseDetailsFailure;
      expect(failure.message, contains('Purchase order not found'));

      await subscription.cancel();
    });

    test('updateStatus updates purchase order status and approves by user', () async {
      await cubit.loadPurchaseOrder('po_003'); // pending approval

      await cubit.updateStatus(
        PurchaseOrderStatus.approved,
        approvedBy: 'Admin Test',
        notes: 'Approved for manufacturing requirement.',
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<PurchaseDetailsLoaded>());
      final loaded = cubit.state as PurchaseDetailsLoaded;
      expect(loaded.record.status, PurchaseOrderStatus.approved);
      expect(loaded.record.approvedBy, 'Admin Test');
      expect(loaded.record.approvedAt, isNotNull);
      expect(loaded.record.notes, contains('Approved for manufacturing requirement'));
    });

    test('receiveItems updates quantities and auto-transitions to received when complete', () async {
      await cubit.loadPurchaseOrder('po_001'); // ordered status, items poi_1 (20) & poi_2 (30)

      // Receive 20 of poi_1, and 30 of poi_2
      await cubit.receiveItems({
        'poi_1': 20,
        'poi_2': 30,
      });
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<PurchaseDetailsLoaded>());
      final loaded = cubit.state as PurchaseDetailsLoaded;
      expect(loaded.record.status, PurchaseOrderStatus.received);
      expect(loaded.record.receivedAt, isNotNull);
      expect(loaded.record.items[0].isFullyReceived, true);
      expect(loaded.record.items[1].isFullyReceived, true);
    });
  });
}
