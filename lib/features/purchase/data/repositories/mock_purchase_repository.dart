import '../../domain/entities/purchase_filter_query.dart';
import '../../domain/entities/purchase_order_record.dart';
import '../../domain/entities/purchase_order_status.dart';
import '../../domain/entities/purchase_summary.dart';
import '../../domain/inputs/create_purchase_order_input.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../datasources/mock_purchase_data_source.dart';

/// In-memory mock implementation of [PurchaseRepository] for development and testing.
class MockPurchaseRepository implements PurchaseRepository {
  final List<PurchaseOrderRecord> _orders;

  MockPurchaseRepository([List<PurchaseOrderRecord>? initialData])
      : _orders = initialData ?? MockPurchaseDataSource.generateSeedPurchaseOrders();

  List<PurchaseOrderRecord> _filter(PurchaseFilterQuery? query) {
    var result = List<PurchaseOrderRecord>.from(_orders);

    if (query == null) return result;

    if (query.searchText != null && query.searchText!.trim().isNotEmpty) {
      final term = query.searchText!.trim().toLowerCase();
      result = result.where((po) {
        return po.poNumber.toLowerCase().contains(term) ||
            po.vendorName.toLowerCase().contains(term) ||
            po.vendorGst.toLowerCase().contains(term) ||
            po.vendorContact.toLowerCase().contains(term) ||
            po.items.any((item) =>
                item.itemName.toLowerCase().contains(term) ||
                item.sku.toLowerCase().contains(term));
      }).toList();
    }

    if (query.status != null) {
      result = result.where((po) => po.status == query.status).toList();
    }

    if (query.vendorName != null && query.vendorName!.trim().isNotEmpty) {
      final term = query.vendorName!.trim().toLowerCase();
      result = result
          .where((po) => po.vendorName.toLowerCase().contains(term))
          .toList();
    }

    if (query.startDate != null) {
      result = result.where((po) => po.orderDate.isAfter(query.startDate!)).toList();
    }

    if (query.endDate != null) {
      result = result.where((po) => po.orderDate.isBefore(query.endDate!)).toList();
    }

    // Sort newest first
    result.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return result;
  }

  @override
  Future<List<PurchaseOrderRecord>> getPurchaseOrders({
    PurchaseFilterQuery? query,
  }) async {
    final filtered = _filter(query);
    if (query == null) return filtered;

    final startIndex = (query.page - 1) * query.pageSize;
    if (startIndex >= filtered.length) return [];

    final endIndex = (startIndex + query.pageSize).clamp(0, filtered.length);
    return filtered.sublist(startIndex, endIndex);
  }

  @override
  Future<int> getPurchaseOrdersCount({PurchaseFilterQuery? query}) async {
    return _filter(query).length;
  }

  @override
  Future<PurchaseOrderRecord?> getPurchaseOrderById(String id) async {
    try {
      return _orders.firstWhere((po) => po.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PurchaseOrderRecord> createPurchaseOrder(
    CreatePurchaseOrderInput input,
  ) async {
    final error = input.validate();
    if (error != null) {
      throw ArgumentError(error);
    }

    final now = DateTime.now();
    final newId = 'po_${now.millisecondsSinceEpoch}';
    final sequence = (_orders.length + 1).toString().padLeft(3, '0');
    final poNumber = 'PO-${now.year}-$sequence';

    final record = PurchaseOrderRecord(
      id: newId,
      poNumber: poNumber,
      vendorName: input.vendorName.trim(),
      vendorGst: input.vendorGst.trim(),
      vendorContact: input.vendorContact.trim(),
      orderDate: input.orderDate ?? now,
      expectedDeliveryDate: input.expectedDeliveryDate,
      status: PurchaseOrderStatus.draft,
      items: input.items,
      subtotalAmount: input.subtotalAmount,
      taxAmount: input.taxAmount,
      totalAmount: input.totalAmount,
      paymentTerms: input.paymentTerms.trim(),
      shippingAddress: input.shippingAddress.trim(),
      notes: input.notes.trim(),
      createdAt: now,
    );

    _orders.insert(0, record);
    return record;
  }

  @override
  Future<PurchaseOrderRecord> updatePurchaseOrderStatus(
    String id,
    PurchaseOrderStatus newStatus, {
    String? notes,
    String? approvedBy,
  }) async {
    final index = _orders.indexWhere((po) => po.id == id);
    if (index == -1) {
      throw StateError('Purchase order not found: $id');
    }

    final current = _orders[index];
    final now = DateTime.now();

    DateTime? approvedAt = current.approvedAt;
    if (newStatus == PurchaseOrderStatus.approved && approvedAt == null) {
      approvedAt = now;
    }

    DateTime? receivedAt = current.receivedAt;
    if (newStatus == PurchaseOrderStatus.received && receivedAt == null) {
      receivedAt = now;
    }

    final updated = current.copyWith(
      status: newStatus,
      approvedBy: approvedBy ?? current.approvedBy,
      approvedAt: approvedAt,
      receivedAt: receivedAt,
      notes: notes != null && notes.trim().isNotEmpty
          ? '${current.notes}\n[${now.toIso8601String()}] ${notes.trim()}'
          : current.notes,
    );

    _orders[index] = updated;
    return updated;
  }

  @override
  Future<PurchaseOrderRecord> receiveItems(
    String id,
    Map<String, int> receivedQuantities,
  ) async {
    final index = _orders.indexWhere((po) => po.id == id);
    if (index == -1) {
      throw StateError('Purchase order not found: $id');
    }

    final current = _orders[index];
    final now = DateTime.now();

    final updatedItems = current.items.map((item) {
      if (receivedQuantities.containsKey(item.id)) {
        final additional = receivedQuantities[item.id] ?? 0;
        final newReceived = (item.receivedQuantity + additional).clamp(
          0,
          item.orderedQuantity,
        );
        return item.copyWith(receivedQuantity: newReceived);
      }
      return item;
    }).toList();

    final allFullyReceived = updatedItems.every((item) => item.isFullyReceived);
    final newStatus = allFullyReceived
        ? PurchaseOrderStatus.received
        : current.status;

    final updated = current.copyWith(
      items: updatedItems,
      status: newStatus,
      receivedAt: allFullyReceived ? now : current.receivedAt,
    );

    _orders[index] = updated;
    return updated;
  }

  @override
  Future<PurchaseSummary> getSummary() async {
    final total = _orders.length;
    final draft = _orders.where((po) => po.status == PurchaseOrderStatus.draft).length;
    final pending = _orders.where((po) => po.status == PurchaseOrderStatus.pendingApproval).length;
    final approved = _orders.where((po) => po.status == PurchaseOrderStatus.approved).length;
    final ordered = _orders.where((po) => po.status == PurchaseOrderStatus.ordered).length;
    final received = _orders.where((po) => po.status == PurchaseOrderStatus.received).length;
    final spend = _orders
        .where((po) => po.status != PurchaseOrderStatus.cancelled)
        .fold(0.0, (sum, po) => sum + po.totalAmount);

    return PurchaseSummary(
      totalOrders: total,
      draftCount: draft,
      pendingApprovalCount: pending,
      approvedCount: approved,
      orderedCount: ordered,
      receivedCount: received,
      totalSpendAmount: spend,
    );
  }
}
