import 'package:flutter_test/flutter_test.dart';

import 'package:enterprise_crm/features/purchase/data/repositories/mock_purchase_repository.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_filter_query.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_item.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_record.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_status.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_summary.dart';
import 'package:enterprise_crm/features/purchase/domain/inputs/create_purchase_order_input.dart';
import 'package:enterprise_crm/features/purchase/domain/repositories/purchase_repository.dart';
import 'package:enterprise_crm/features/purchase/presentation/bloc/create_purchase_order_cubit.dart';
import 'package:enterprise_crm/features/purchase/presentation/bloc/create_purchase_order_state.dart';

class _FailingCreatePurchaseRepository implements PurchaseRepository {
  @override
  Future<PurchaseOrderRecord> createPurchaseOrder(CreatePurchaseOrderInput input) {
    throw Exception('Storage write failed');
  }

  @override
  Future<List<PurchaseOrderRecord>> getPurchaseOrders({PurchaseFilterQuery? query}) {
    throw UnimplementedError();
  }

  @override
  Future<int> getPurchaseOrdersCount({PurchaseFilterQuery? query}) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrderRecord?> getPurchaseOrderById(String id) async => null;

  @override
  Future<PurchaseSummary> getSummary() {
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
}

void main() {
  group('CreatePurchaseOrderCubit Tests', () {
    late MockPurchaseRepository repository;
    late CreatePurchaseOrderCubit cubit;

    setUp(() {
      repository = MockPurchaseRepository();
      cubit = CreatePurchaseOrderCubit(repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is CreatePurchaseOrderInitial', () {
      expect(cubit.state, isA<CreatePurchaseOrderInitial>());
    });

    test('validation failure emits CreatePurchaseOrderFailure without calling repository', () async {
      const invalidInput = CreatePurchaseOrderInput(
        vendorName: '',
        items: [],
      );

      await cubit.submit(invalidInput);

      expect(cubit.state, isA<CreatePurchaseOrderFailure>());
      final failure = cubit.state as CreatePurchaseOrderFailure;
      expect(failure.message, contains('Vendor name is required'));
    });

    test('valid input emits [Submitting, Success] and adds order to repository', () async {
      final states = <CreatePurchaseOrderState>[];
      final subscription = cubit.stream.listen(states.add);

      const validInput = CreatePurchaseOrderInput(
        vendorName: 'Bharat Electronics Ltd',
        vendorGst: '06DDDDD3333D4Z8',
        vendorContact: '+91 97444 55667',
        paymentTerms: 'Net 30 Days',
        shippingAddress: 'Sector 18 Hub',
        notes: 'Priority procurement for Q1',
        items: [
          PurchaseOrderItem(
            id: 'item_1',
            itemName: 'Ergonomic Keyboards',
            sku: 'INV-KEY-01',
            orderedQuantity: 25,
            receivedQuantity: 0,
            unit: 'Pcs',
            unitPriceInr: 1200.0,
          ),
        ],
      );

      await cubit.submit(validInput);
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<CreatePurchaseOrderSubmitting>());
      expect(states[1], isA<CreatePurchaseOrderSuccess>());

      final success = states[1] as CreatePurchaseOrderSuccess;
      expect(success.record.vendorName, 'Bharat Electronics Ltd');
      expect(success.record.status, PurchaseOrderStatus.draft);
      expect(success.record.subtotalAmount, 30000.0);
      expect(success.record.taxAmount, 5400.0);
      expect(success.record.totalAmount, 35400.0);

      // Verify repository contains new order
      final saved = await repository.getPurchaseOrderById(success.record.id);
      expect(saved, isNotNull);
      expect(saved!.vendorName, 'Bharat Electronics Ltd');

      await subscription.cancel();
    });

    test('repository exception emits CreatePurchaseOrderFailure', () async {
      final failingRepo = _FailingCreatePurchaseRepository();
      final failingCubit = CreatePurchaseOrderCubit(failingRepo);

      const validInput = CreatePurchaseOrderInput(
        vendorName: 'Acme Test',
        items: [
          PurchaseOrderItem(
            id: 'it_1',
            itemName: 'Test Item',
            sku: 'TEST-SKU',
            orderedQuantity: 1,
            unitPriceInr: 100.0,
          ),
        ],
      );

      final states = <CreatePurchaseOrderState>[];
      final subscription = failingCubit.stream.listen(states.add);

      await failingCubit.submit(validInput);
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<CreatePurchaseOrderSubmitting>());
      expect(states[1], isA<CreatePurchaseOrderFailure>());

      final failure = states[1] as CreatePurchaseOrderFailure;
      expect(failure.message, contains('Storage write failed'));

      await subscription.cancel();
      await failingCubit.close();
    });
  });
}
