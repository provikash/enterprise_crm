import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PurchaseOrderStatus Tests', () {
    test('all 6 statuses have valid display names and colors', () {
      for (final status in PurchaseOrderStatus.values) {
        expect(status.displayName.isNotEmpty, isTrue);
        expect(status.color, isNotNull);
        expect(status.icon, isNotNull);
      }
    });

    test('isTerminal is true only for received and cancelled', () {
      expect(PurchaseOrderStatus.received.isTerminal, isTrue);
      expect(PurchaseOrderStatus.cancelled.isTerminal, isTrue);
      expect(PurchaseOrderStatus.draft.isTerminal, isFalse);
      expect(PurchaseOrderStatus.pendingApproval.isTerminal, isFalse);
      expect(PurchaseOrderStatus.approved.isTerminal, isFalse);
      expect(PurchaseOrderStatus.ordered.isTerminal, isFalse);
    });

    test('state flags are accurate for each milestone', () {
      expect(PurchaseOrderStatus.draft.isDraft, isTrue);
      expect(PurchaseOrderStatus.pendingApproval.isPendingApproval, isTrue);
      expect(PurchaseOrderStatus.approved.isApproved, isTrue);
      expect(PurchaseOrderStatus.ordered.canReceiveGoods, isTrue);
    });
  });
}
