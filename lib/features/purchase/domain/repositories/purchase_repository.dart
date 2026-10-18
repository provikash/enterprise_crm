import '../entities/purchase_filter_query.dart';
import '../entities/purchase_order_record.dart';
import '../entities/purchase_order_status.dart';
import '../entities/purchase_summary.dart';
import '../inputs/create_purchase_order_input.dart';

/// Contract defining all data operations for Purchase Order management.
abstract class PurchaseRepository {
  /// Retrieves a paginated and filtered list of purchase orders.
  Future<List<PurchaseOrderRecord>> getPurchaseOrders({PurchaseFilterQuery? query});

  /// Counts the total matching purchase orders for a query.
  Future<int> getPurchaseOrdersCount({PurchaseFilterQuery? query});

  /// Retrieves a specific purchase order by its unique [id].
  Future<PurchaseOrderRecord?> getPurchaseOrderById(String id);

  /// Creates and persists a new purchase order.
  Future<PurchaseOrderRecord> createPurchaseOrder(CreatePurchaseOrderInput input);

  /// Transitions a PO to a new status (e.g. submit for approval, approve, order, cancel).
  Future<PurchaseOrderRecord> updatePurchaseOrderStatus(
    String id,
    PurchaseOrderStatus newStatus, {
    String? notes,
    String? approvedBy,
  });

  /// Records received goods quantities for line items in an ordered PO.
  Future<PurchaseOrderRecord> receiveItems(
    String id,
    Map<String, int> receivedQuantities,
  );

  /// Computes top-level KPI metrics across all purchase orders.
  Future<PurchaseSummary> getSummary();
}
