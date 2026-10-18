import '../../domain/entities/dispatch_filter_query.dart';
import '../../domain/entities/dispatch_record.dart';
import '../../domain/entities/dispatch_status.dart';
import '../../domain/entities/dispatch_summary.dart';
import '../../domain/inputs/create_dispatch_input.dart';
import '../../domain/repositories/dispatch_repository.dart';
import '../datasources/mock_dispatch_data_source.dart';

class MockDispatchRepository implements DispatchRepository {
  final List<DispatchRecord> _dispatches;

  MockDispatchRepository([List<DispatchRecord>? initialData])
      : _dispatches = initialData ?? MockDispatchDataSource.generateSeedDispatches();

  List<DispatchRecord> _filter(DispatchFilterQuery? query) {
    var result = List<DispatchRecord>.from(_dispatches);

    if (query == null) return result;

    if (query.searchText != null && query.searchText!.trim().isNotEmpty) {
      final term = query.searchText!.trim().toLowerCase();
      result = result.where((d) {
        return d.dispatchCode.toLowerCase().contains(term) ||
            d.orderNumber.toLowerCase().contains(term) ||
            d.customerName.toLowerCase().contains(term) ||
            d.customerPhone.toLowerCase().contains(term) ||
            d.vehicleNumber.toLowerCase().contains(term) ||
            d.driverName.toLowerCase().contains(term) ||
            d.builtyNumber.toLowerCase().contains(term) ||
            d.invoiceNumber.toLowerCase().contains(term);
      }).toList();
    }

    if (query.status != null) {
      result = result.where((d) => d.status == query.status).toList();
    }

    if (query.transporter != null && query.transporter!.trim().isNotEmpty) {
      final term = query.transporter!.trim().toLowerCase();
      result = result
          .where((d) => d.transporterName.toLowerCase().contains(term))
          .toList();
    }

    if (query.startDate != null) {
      result = result.where((d) => d.createdAt.isAfter(query.startDate!)).toList();
    }

    if (query.endDate != null) {
      result = result.where((d) => d.createdAt.isBefore(query.endDate!)).toList();
    }

    // Sort newest first
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<List<DispatchRecord>> getDispatches({DispatchFilterQuery? query}) async {
    final filtered = _filter(query);
    if (query == null) return filtered;

    final startIndex = (query.page - 1) * query.pageSize;
    if (startIndex >= filtered.length) return [];

    final endIndex = (startIndex + query.pageSize).clamp(0, filtered.length);
    return filtered.sublist(startIndex, endIndex);
  }

  @override
  Future<int> getDispatchesCount({DispatchFilterQuery? query}) async {
    return _filter(query).length;
  }

  @override
  Future<DispatchRecord?> getDispatchById(String id) async {
    try {
      return _dispatches.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DispatchRecord> createDispatch(CreateDispatchInput input) async {
    final error = input.validate();
    if (error != null) {
      throw ArgumentError(error);
    }

    final id = 'dsp_${DateTime.now().millisecondsSinceEpoch}';
    final sequence = (_dispatches.length + 1).toString().padLeft(3, '0');
    final code = 'DSP-2026-$sequence';
    final now = DateTime.now();

    final record = DispatchRecord(
      id: id,
      dispatchCode: code,
      orderNumber: input.orderNumber,
      customerName: input.customerName.trim(),
      customerPhone: input.customerPhone.trim(),
      deliveryAddress: input.deliveryAddress.trim(),
      invoiceNumber: input.invoiceNumber.trim(),
      invoiceDate: input.invoiceDate ?? now,
      invoiceAmount: input.invoiceAmount,
      transporterName: input.transporterName.trim(),
      vehicleNumber: input.vehicleNumber.trim(),
      vehicleType: input.vehicleType,
      driverName: input.driverName.trim(),
      driverPhone: input.driverPhone.trim(),
      builtyNumber: input.builtyNumber.trim(),
      builtyDate: input.builtyDate ?? now,
      notes: input.notes.trim(),
      status: DispatchStatus.pending,
      items: input.items,
      createdAt: now,
    );

    _dispatches.insert(0, record);
    return record;
  }

  @override
  Future<DispatchRecord> updateDispatchStatus(
    String id,
    DispatchStatus newStatus, {
    String? remarks,
  }) async {
    final index = _dispatches.indexWhere((d) => d.id == id);
    if (index == -1) {
      throw StateError('Dispatch record not found: $id');
    }

    final current = _dispatches[index];
    final now = DateTime.now();

    DateTime? dispatchedAt = current.dispatchedAt;
    if (newStatus == DispatchStatus.inTransit && dispatchedAt == null) {
      dispatchedAt = now;
    }

    DateTime? deliveredAt = current.deliveredAt;
    if (newStatus == DispatchStatus.delivered && deliveredAt == null) {
      deliveredAt = now;
    }

    final updated = current.copyWith(
      status: newStatus,
      dispatchedAt: dispatchedAt,
      deliveredAt: deliveredAt,
      notes: remarks != null && remarks.trim().isNotEmpty
          ? '${current.notes}\n[${now.toIso8601String()}] Status updated to ${newStatus.displayName}: ${remarks.trim()}'
          : current.notes,
    );

    _dispatches[index] = updated;
    return updated;
  }

  @override
  Future<DispatchSummary> getSummary() async {
    final total = _dispatches.length;
    final pending = _dispatches.where((d) => d.status == DispatchStatus.pending || d.status == DispatchStatus.packed).length;
    final inTransit = _dispatches.where((d) => d.status == DispatchStatus.inTransit).length;
    final outForDelivery = _dispatches.where((d) => d.status == DispatchStatus.outForDelivery).length;
    final delivered = _dispatches.where((d) => d.status == DispatchStatus.delivered).length;

    final now = DateTime.now();
    final today = _dispatches.where((d) {
      return d.createdAt.year == now.year &&
          d.createdAt.month == now.month &&
          d.createdAt.day == now.day;
    }).length;

    return DispatchSummary(
      totalDispatches: total,
      pendingCount: pending,
      inTransitCount: inTransit,
      outForDeliveryCount: outForDelivery,
      deliveredCount: delivered,
      todayDispatchesCount: today,
    );
  }
}
