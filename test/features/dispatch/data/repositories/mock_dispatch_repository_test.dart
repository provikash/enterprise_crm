import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/dispatch/data/repositories/mock_dispatch_repository.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_filter_query.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_item.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_status.dart';
import 'package:enterprise_crm/features/dispatch/domain/inputs/create_dispatch_input.dart';

void main() {
  group('MockDispatchRepository Tests', () {
    late MockDispatchRepository repository;

    setUp(() {
      repository = MockDispatchRepository();
    });

    test('getDispatches returns all seed dispatches by default', () async {
      final dispatches = await repository.getDispatches();
      expect(dispatches.isNotEmpty, isTrue);
      expect(dispatches.length, greaterThanOrEqualTo(7));
    });

    test('getDispatches filters correctly by searchText', () async {
      // Search by customer name
      final byCustomer = await repository.getDispatches(
        query: const DispatchFilterQuery(searchText: 'Acme'),
      );
      expect(byCustomer.length, 1);
      expect(byCustomer.first.dispatchCode, 'DSP-2026-001');

      // Search by vehicle number
      final byVehicle = await repository.getDispatches(
        query: const DispatchFilterQuery(searchText: 'MH-12-PQ-9082'),
      );
      expect(byVehicle.length, 1);
      expect(byVehicle.first.customerName, 'Global Infra Corp');

      // Search by builty number
      final byBuilty = await repository.getDispatches(
        query: const DispatchFilterQuery(searchText: 'BL-VRL-44910'),
      );
      expect(byBuilty.length, 1);
    });

    test('getDispatches filters by DispatchStatus', () async {
      final delivered = await repository.getDispatches(
        query: const DispatchFilterQuery(status: DispatchStatus.delivered),
      );
      expect(delivered.every((d) => d.status == DispatchStatus.delivered), isTrue);

      final inTransit = await repository.getDispatches(
        query: const DispatchFilterQuery(status: DispatchStatus.inTransit),
      );
      expect(inTransit.every((d) => d.status == DispatchStatus.inTransit), isTrue);
    });

    test('pagination correctly partitions results', () async {
      final page1 = await repository.getDispatches(
        query: const DispatchFilterQuery(page: 1, pageSize: 3),
      );
      final page2 = await repository.getDispatches(
        query: const DispatchFilterQuery(page: 2, pageSize: 3),
      );

      expect(page1.length, 3);
      expect(page2.length, 3);
      expect(page1.first.id, isNot(equals(page2.first.id)));
    });

    test('getDispatchById returns item when found and null when absent', () async {
      final item = await repository.getDispatchById('dsp_001');
      expect(item, isNotNull);
      expect(item!.dispatchCode, 'DSP-2026-001');

      final absent = await repository.getDispatchById('non_existent');
      expect(absent, isNull);
    });

    test('createDispatch creates, validates, and stores a new dispatch order', () async {
      const input = CreateDispatchInput(
        orderNumber: 'ORD-TEST-1',
        customerName: 'Test Technologies',
        customerPhone: '+91 99999 88888',
        deliveryAddress: 'Sector 62, Noida',
        invoiceNumber: 'INV-TEST-01',
        invoiceAmount: 50000.0,
        transporterName: 'FedEx',
        vehicleNumber: 'DL-01-ZZ-9999',
        driverName: 'Kishore Kumar',
        driverPhone: '+91 91111 22222',
        builtyNumber: 'BL-FDX-101',
        items: [
          DispatchItem(
            id: 't_item_1',
            name: 'Office Headset',
            sku: 'SKU-01',
            quantity: 5,
            unit: 'Pcs',
            unitPrice: 2000.0,
          ),
        ],
      );

      final created = await repository.createDispatch(input);
      expect(created.id, isNotEmpty);
      expect(created.dispatchCode, startsWith('DSP-2026-'));
      expect(created.status, DispatchStatus.pending);
      expect(created.items.length, 1);
      expect(created.items.first.totalPrice, 10000.0);

      final fetched = await repository.getDispatchById(created.id);
      expect(fetched, isNotNull);
      expect(fetched!.customerName, 'Test Technologies');
    });

    test('createDispatch throws ArgumentError on validation failure', () async {
      const invalid = CreateDispatchInput(
        orderNumber: 'ORD-INVALID',
        customerName: '', // empty
        customerPhone: '',
        deliveryAddress: '',
        invoiceNumber: '',
        transporterName: '',
        vehicleNumber: '',
        driverName: '',
        driverPhone: '',
        builtyNumber: '',
        items: [],
      );

      expect(() => repository.createDispatch(invalid), throwsArgumentError);
    });

    test('updateDispatchStatus updates status and records timestamps', () async {
      final updated = await repository.updateDispatchStatus(
        'dsp_003',
        DispatchStatus.inTransit,
        remarks: 'Vehicle departed from warehouse',
      );

      expect(updated.status, DispatchStatus.inTransit);
      expect(updated.dispatchedAt, isNotNull);
      expect(updated.notes, contains('Vehicle departed from warehouse'));

      final delivered = await repository.updateDispatchStatus(
        'dsp_003',
        DispatchStatus.delivered,
        remarks: 'Delivered to gate 2',
      );

      expect(delivered.status, DispatchStatus.delivered);
      expect(delivered.deliveredAt, isNotNull);
    });

    test('getSummary computes accurate metrics', () async {
      final summary = await repository.getSummary();
      expect(summary.totalDispatches, greaterThanOrEqualTo(7));
      expect(summary.pendingCount, greaterThanOrEqualTo(1));
      expect(summary.inTransitCount, greaterThanOrEqualTo(1));
      expect(summary.deliveredCount, greaterThanOrEqualTo(2));
    });
  });
}
