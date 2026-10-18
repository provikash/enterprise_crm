import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/purchase_order_status.dart';
import '../../domain/repositories/purchase_repository.dart';
import 'purchase_details_state.dart';

/// Cubit managing purchase order inspection, status progression, and stock receipt.
class PurchaseDetailsCubit extends Cubit<PurchaseDetailsState> {
  final PurchaseRepository repository;

  PurchaseDetailsCubit(this.repository) : super(const PurchaseDetailsInitial());

  Future<void> loadPurchaseOrder(String id) async {
    emit(const PurchaseDetailsLoading());
    try {
      final record = await repository.getPurchaseOrderById(id);
      if (record == null) {
        emit(const PurchaseDetailsFailure('Purchase order not found.'));
        return;
      }
      emit(PurchaseDetailsLoaded(record));
    } catch (e) {
      emit(PurchaseDetailsFailure(e.toString()));
    }
  }

  Future<void> updateStatus(
    PurchaseOrderStatus newStatus, {
    String? notes,
    String? approvedBy,
  }) async {
    final currentState = state;
    if (currentState is! PurchaseDetailsLoaded) return;
    if (currentState.isUpdating) return;

    emit(currentState.copyWith(isUpdating: true, updateError: null));

    try {
      final updated = await repository.updatePurchaseOrderStatus(
        currentState.record.id,
        newStatus,
        notes: notes,
        approvedBy: approvedBy,
      );
      emit(PurchaseDetailsLoaded(updated));
    } catch (e) {
      emit(currentState.copyWith(isUpdating: false, updateError: e.toString()));
    }
  }

  Future<void> receiveItems(Map<String, int> receivedQuantities) async {
    final currentState = state;
    if (currentState is! PurchaseDetailsLoaded) return;
    if (currentState.isUpdating) return;

    emit(currentState.copyWith(isUpdating: true, updateError: null));

    try {
      final updated = await repository.receiveItems(
        currentState.record.id,
        receivedQuantities,
      );
      emit(PurchaseDetailsLoaded(updated));
    } catch (e) {
      emit(currentState.copyWith(isUpdating: false, updateError: e.toString()));
    }
  }
}
