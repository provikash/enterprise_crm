import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_item.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_record.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_status.dart';
import 'package:enterprise_crm/features/purchase/domain/inputs/create_purchase_order_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Purchase Order Domain Entities Tests', () {
    test('PurchaseOrderItem calculates totalPriceInr and pendingQuantity correctly', () {
      const item = PurchaseOrderItem(
        id: 'poi_1',
        itemName: '4K Monitors',
        sku: 'INV-005',
        orderedQuantity: 10,
        receivedQuantity: 3,
        unitPriceInr: 9000.0,
      );

      expect(item.totalPriceInr, equals(90000.0));
      expect(item.pendingQuantity, equals(7));
      expect(item.isFullyReceived, isFalse);

      final fullyReceived = item.copyWith(receivedQuantity: 10);
      expect(fullyReceived.pendingQuantity, equals(0));
      expect(fullyReceived.isFullyReceived, isTrue);
    });

    test('PurchaseOrderRecord calculates total quantities and receipt progress', () {
      final now = DateTime.now();
      final record = PurchaseOrderRecord(
        id: 'po_001',
        poNumber: 'PO-2026-001',
        vendorName: 'Apex Tech',
        orderDate: now,
        status: PurchaseOrderStatus.ordered,
        items: const [
          PurchaseOrderItem(
            id: 'poi_1',
            itemName: 'Item 1',
            sku: 'SKU-1',
            orderedQuantity: 20,
            receivedQuantity: 10,
            unitPriceInr: 100.0,
          ),
          PurchaseOrderItem(
            id: 'poi_2',
            itemName: 'Item 2',
            sku: 'SKU-2',
            orderedQuantity: 30,
            receivedQuantity: 15,
            unitPriceInr: 200.0,
          ),
        ],
        subtotalAmount: 8000.0,
        taxAmount: 1440.0,
        totalAmount: 9440.0,
        createdAt: now,
      );

      expect(record.totalOrderedQuantity, equals(50));
      expect(record.totalReceivedQuantity, equals(25));
      expect(record.receiptProgressPercentage, equals(50.0));
    });

    test('CreatePurchaseOrderInput calculates tax and total correctly', () {
      const input = CreatePurchaseOrderInput(
        vendorName: 'Apex Tech Supplies',
        items: [
          PurchaseOrderItem(
            id: 'i1',
            itemName: 'Monitors',
            sku: 'INV-005',
            orderedQuantity: 2,
            unitPriceInr: 10000.0,
          ),
        ],
      );

      expect(input.subtotalAmount, equals(20000.0));
      expect(input.taxAmount, equals(3600.0));
      expect(input.totalAmount, equals(23600.0));
      expect(input.validate(), isNull);
    });

    test('CreatePurchaseOrderInput rejects missing vendor name and zero items', () {
      const emptyVendor = CreatePurchaseOrderInput(
        vendorName: '',
        items: [
          PurchaseOrderItem(
            id: 'i1',
            itemName: 'Item',
            sku: 'S1',
            orderedQuantity: 1,
            unitPriceInr: 100.0,
          ),
        ],
      );
      expect(emptyVendor.validate(), contains('Vendor name is required'));

      const noItems = CreatePurchaseOrderInput(
        vendorName: 'Vendor',
        items: [],
      );
      expect(noItems.validate(), contains('At least one purchase line item'));

      const invalidItemQty = CreatePurchaseOrderInput(
        vendorName: 'Vendor',
        items: [
          PurchaseOrderItem(
            id: 'i1',
            itemName: 'Item',
            sku: 'S1',
            orderedQuantity: 0,
            unitPriceInr: 100.0,
          ),
        ],
      );
      expect(invalidItemQty.validate(), contains('ordered quantity must be greater than zero'));
    });
  });
}
