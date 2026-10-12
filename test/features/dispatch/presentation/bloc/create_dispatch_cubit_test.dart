import 'package:enterprise_crm/features/dispatch/data/repositories/mock_dispatch_repository.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_filter_query.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_item.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_record.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_status.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_summary.dart';
import 'package:enterprise_crm/features/dispatch/domain/inputs/create_dispatch_input.dart';
import 'package:enterprise_crm/features/dispatch/domain/repositories/dispatch_repository.dart';
import 'package:enterprise_crm/features/dispatch/presentation/bloc/create_dispatch_cubit.dart';
import 'package:enterprise_crm/features/dispatch/presentation/bloc/create_dispatch_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingRepo implements DispatchRepository {
  @override
  Future<DispatchRecord> createDispatch(CreateDispatchInput input) {
    throw Exception('Database write failed');
  }

  @override
  Future<DispatchRecord?> getDispatchById(String id) async => null;

  @override
  Future<List<DispatchRecord>> getDispatches({DispatchFilterQuery? query}) async => [];

  @override
  Future<int> getDispatchesCount({DispatchFilterQuery? query}) async => 0;

  @override
  Future<DispatchSummary> getSummary() async => const DispatchSummary.empty();

  @override
  Future<DispatchRecord> updateDispatchStatus(String id, DispatchStatus newStatus, {String? remarks}) {
    throw UnimplementedError();
  }
}

void main() {
  group('CreateDispatchCubit Tests', () {
    late MockDispatchRepository repository;
    late CreateDispatchCubit cubit;

    setUp(() {
      repository = MockDispatchRepository();
      cubit = CreateDispatchCubit(repository);
    });

    tearDown(() {
      cubit.close();
    });

    final validInput = CreateDispatchInput(
      orderNumber: 'ORD-TEST-1',
      customerName: 'Bharat Electronics',
      customerPhone: '+91 98765 00000',
      deliveryAddress: 'Tech Zone 2, Noida',
      invoiceNumber: 'INV-TEST-001',
      invoiceAmount: 50000.0,
      transporterName: 'Blue Dart',
      vehicleNumber: 'UP-16-AB-9999',
      driverName: 'Ramesh Kumar',
      driverPhone: '+91 99999 11111',
      builtyNumber: 'BL-BD-12345',
      items: const [
        DispatchItem(
          id: 'item_test_1',
          name: 'Industrial Router',
          sku: 'RTR-01',
          quantity: 2,
          unit: 'Pcs',
          unitPrice: 25000.0,
        ),
      ],
    );

    test('initial state is CreateDispatchInitial', () {
      expect(cubit.state, isA<CreateDispatchInitial>());
    });

    test('submit valid input emits [CreateDispatchSubmitting, CreateDispatchSuccess]', () async {
      final states = <CreateDispatchState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.submit(validInput);
      await Future<void>.delayed(Duration.zero);

      expect(states.length, equals(2));
      expect(states[0], isA<CreateDispatchSubmitting>());
      expect(states[1], isA<CreateDispatchSuccess>());

      final success = states[1] as CreateDispatchSuccess;
      expect(success.record.customerName, equals('Bharat Electronics'));
      expect(success.record.invoiceNumber, equals('INV-TEST-001'));
      expect(success.record.builtyNumber, equals('BL-BD-12345'));
      expect(success.record.items.length, equals(1));

      // Verifies stored in repository
      final fetched = await repository.getDispatchById(success.record.id);
      expect(fetched, isNotNull);

      await subscription.cancel();
    });

    test('submit input with missing required customer name emits CreateDispatchFailure', () async {
      final invalidInput = CreateDispatchInput(
        orderNumber: 'ORD-TEST-1',
        customerName: '', // empty
        customerPhone: '+91 98765 00000',
        deliveryAddress: 'Tech Zone 2, Noida',
        invoiceNumber: 'INV-TEST-001',
        transporterName: 'Blue Dart',
        vehicleNumber: 'UP-16-AB-9999',
        driverName: 'Ramesh Kumar',
        driverPhone: '+91 99999 11111',
        builtyNumber: 'BL-BD-12345',
        items: const [
          DispatchItem(
            id: 'item_1',
            name: 'Item 1',
            sku: 'SKU-1',
            quantity: 1,
            unit: 'Pcs',
            unitPrice: 100.0,
          ),
        ],
      );

      final states = <CreateDispatchState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.submit(invalidInput);
      await Future<void>.delayed(Duration.zero);

      expect(states.length, equals(1));
      expect(states[0], isA<CreateDispatchFailure>());
      expect((states[0] as CreateDispatchFailure).message, contains('Customer name'));

      await subscription.cancel();
    });

    test('submit input with zero line items emits CreateDispatchFailure', () async {
      final noItemsInput = CreateDispatchInput(
        orderNumber: 'ORD-TEST-1',
        customerName: 'Customer',
        customerPhone: '+91 98765 00000',
        deliveryAddress: 'Tech Zone 2, Noida',
        invoiceNumber: 'INV-TEST-001',
        transporterName: 'Blue Dart',
        vehicleNumber: 'UP-16-AB-9999',
        driverName: 'Ramesh Kumar',
        driverPhone: '+91 99999 11111',
        builtyNumber: 'BL-BD-12345',
        items: const [], // empty
      );

      final states = <CreateDispatchState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.submit(noItemsInput);
      await Future<void>.delayed(Duration.zero);

      expect(states.length, equals(1));
      expect(states[0], isA<CreateDispatchFailure>());
      expect((states[0] as CreateDispatchFailure).message, contains('item is required'));

      await subscription.cancel();
    });

    test('submit emits CreateDispatchFailure when repository throws', () async {
      final failingRepo = _FailingRepo();
      final failingCubit = CreateDispatchCubit(failingRepo);

      final states = <CreateDispatchState>[];
      final subscription = failingCubit.stream.listen(states.add);

      await failingCubit.submit(validInput);
      await Future<void>.delayed(Duration.zero);

      expect(states.length, equals(2));
      expect(states[0], isA<CreateDispatchSubmitting>());
      expect(states[1], isA<CreateDispatchFailure>());
      expect((states[1] as CreateDispatchFailure).message, contains('Database write failed'));

      await subscription.cancel();
      await failingCubit.close();
    });
  });
}
