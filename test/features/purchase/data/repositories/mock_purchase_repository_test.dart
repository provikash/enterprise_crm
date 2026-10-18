import 'package:enterprise_crm/features/purchase/data/repositories/mock_purchase_repository.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_filter_query.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_item.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_status.dart';
import 'package:enterprise_crm/features/purchase/domain/inputs/create_purchase_order_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockPurchaseRepository Tests', () {
    late MockPurchaseRepository repository;

    setUp(() {
      repository = MockPurchaseRepository();
    });

    test('initial seed data loads and pagination works', () async {
      final page1 = await repository.getPurchaseOrders(
        query: const PurchaseFilterQuery(page: 1, pageSize: 4),
      );
      final count = await repository.getPurchaseOrdersCount();

      expect(count, equals(6));
      expect(page1.length, equals(4));

      final page2 = await repository.getPurchaseOrders(
        query: const PurchaseFilterQuery(page: 2, pageSize: 4),
      );
      expect(page2.length, equals(2));
    });

    test('getPurchaseOrderById returns correct record or null', () async {
      final po = await repository.getPurchaseOrderById('po_001');
      expect(po, isNotNull);
      expect(po!.poNumber, equals('PO-2026-001'));
      expect(po.vendorName, contains('Apex Tech'));

      final nonExistent = await repository.getPurchaseOrderById('non_existent');
      expect(nonExistent, isNull);
    });

    test('filtering by searchText matches PO number, vendor name, and SKU', () async {
      final poMatch = await repository.getPurchaseOrders(
        query: const PurchaseFilterQuery(searchText: 'PO-2026-002'),
      );
      expect(poMatch.length, equals(1));
      expect(poMatch.first.id, equals('po_002'));

      final vendorMatch = await repository.getPurchaseOrders(
        query: const PurchaseFilterQuery(searchText: 'Zenith'),
      );
      expect(vendorMatch.length, equals(1));
      expect(vendorMatch.first.id, equals('po_003'));

      final skuMatch = await repository.getPurchaseOrders(
        query: const PurchaseFilterQuery(searchText: 'INV-005'),
      );
      // po_001 and po_005 have INV-005
      expect(skuMatch.length, equals(2));
    });

    test('filtering by status returns only matching records', () async {
      final approvedOrders = await repository.getPurchaseOrders(
        query: const PurchaseFilterQuery(status: PurchaseOrderStatus.approved),
      );
      expect(approvedOrders.every((po) => po.status == PurchaseOrderStatus.approved), isTrue);
      expect(approvedOrders.length, equals(1));
      expect(approvedOrders.first.id, equals('po_002'));
    });

    test('createPurchaseOrder validates, prepends, and increments count', () async {
      const input = CreatePurchaseOrderInput(
        vendorName: 'Future Tech Logistics',
        vendorGst: '07FFFFF9999F9Z9',
        vendorContact: '+91 91234 56789',
        paymentTerms: 'Immediate',
        items: [
          PurchaseOrderItem(
            id: 'item_new',
            itemName: 'Ergonomic Keyboards',
            sku: 'INV-010',
            orderedQuantity: 25,
            unitPriceInr: 1200.0,
          ),
        ],
      );

      final created = await repository.createPurchaseOrder(input);

      expect(created.vendorName, equals('Future Tech Logistics'));
      expect(created.status, equals(PurchaseOrderStatus.draft));
      expect(created.subtotalAmount, equals(30000.0));
      expect(created.taxAmount, equals(5400.0));
      expect(created.totalAmount, equals(35400.0));

      final count = await repository.getPurchaseOrdersCount();
      expect(count, equals(7));

      final fetched = await repository.getPurchaseOrderById(created.id);
      expect(fetched, isNotNull);
      expect(fetched!.poNumber, equals(created.poNumber));
    });

    test('updatePurchaseOrderStatus transitions status and updates audit fields', () async {
      final updated = await repository.updatePurchaseOrderStatus(
        'po_004', // was draft
        PurchaseOrderStatus.pendingApproval,
        notes: 'Submitted for managerial review',
      );

      expect(updated.status, equals(PurchaseOrderStatus.pendingApproval));
      expect(updated.notes, contains('Submitted for managerial review'));

      final approved = await repository.updatePurchaseOrderStatus(
        'po_004',
        PurchaseOrderStatus.approved,
        approvedBy: 'Admin Boss',
      );
      expect(approved.status, equals(PurchaseOrderStatus.approved));
      expect(approved.approvedBy, equals('Admin Boss'));
      expect(approved.approvedAt, isNotNull);
    });

    test('receiveItems updates quantities and auto-transitions to received when complete', () async {
      // po_001 has poi_1 (ordered 20) and poi_2 (ordered 30), status ordered
      final partial = await repository.receiveItems('po_001', {
        'poi_1': 10,
        'poi_2': 15,
      });

      expect(partial.items[0].receivedQuantity, equals(10));
      expect(partial.items[1].receivedQuantity, equals(15));
      expect(partial.status, equals(PurchaseOrderStatus.ordered)); // still ordered

      // Now receive remaining units
      final full = await repository.receiveItems('po_001', {
        'poi_1': 10,
        'poi_2': 15,
      });

      expect(full.items[0].receivedQuantity, equals(20));
      expect(full.items[1].receivedQuantity, equals(30));
      expect(full.status, equals(PurchaseOrderStatus.received));
      expect(full.receivedAt, isNotNull);
    });

    test('getSummary calculates correct counts and total spend', () async {
      final summary = await repository.getSummary();

      expect(summary.totalOrders, equals(6));
      expect(summary.draftCount, equals(1));
      expect(summary.pendingApprovalCount, equals(1));
      expect(summary.approvedCount, equals(1));
      expect(summary.orderedCount, equals(1));
      expect(summary.receivedCount, equals(1));
      expect(summary.totalSpendAmount, greaterThan(0.0));
    });
  });
}
