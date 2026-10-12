import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_status.dart';

void main() {
  group('DispatchStatus Enum Tests', () {
    test('displayName returns appropriate string for all enum values', () {
      expect(DispatchStatus.pending.displayName, 'Pending');
      expect(DispatchStatus.packed.displayName, 'Packed');
      expect(DispatchStatus.inTransit.displayName, 'In Transit');
      expect(DispatchStatus.outForDelivery.displayName, 'Out for Delivery');
      expect(DispatchStatus.delivered.displayName, 'Delivered');
      expect(DispatchStatus.cancelled.displayName, 'Cancelled');
    });

    test('isTerminal returns true only for delivered and cancelled', () {
      expect(DispatchStatus.delivered.isTerminal, isTrue);
      expect(DispatchStatus.cancelled.isTerminal, isTrue);
      expect(DispatchStatus.pending.isTerminal, isFalse);
      expect(DispatchStatus.inTransit.isTerminal, isFalse);
    });

    test('isInProgress returns true for intermediate progression states', () {
      expect(DispatchStatus.packed.isInProgress, isTrue);
      expect(DispatchStatus.inTransit.isInProgress, isTrue);
      expect(DispatchStatus.outForDelivery.isInProgress, isTrue);
      expect(DispatchStatus.pending.isInProgress, isFalse);
      expect(DispatchStatus.delivered.isInProgress, isFalse);
    });
  });
}
