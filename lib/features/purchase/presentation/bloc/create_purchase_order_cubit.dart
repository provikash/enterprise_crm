import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/inputs/create_purchase_order_input.dart';
import '../../domain/repositories/purchase_repository.dart';
import 'create_purchase_order_state.dart';

/// Cubit managing creation and validation of new purchase orders.
class CreatePurchaseOrderCubit extends Cubit<CreatePurchaseOrderState> {
  final PurchaseRepository repository;

  CreatePurchaseOrderCubit(this.repository)
      : super(const CreatePurchaseOrderInitial());

  Future<void> submit(CreatePurchaseOrderInput input) async {
    if (state is CreatePurchaseOrderSubmitting) return;

    final error = input.validate();
    if (error != null) {
      emit(CreatePurchaseOrderFailure(error));
      return;
    }

    emit(const CreatePurchaseOrderSubmitting());

    try {
      final record = await repository.createPurchaseOrder(input);
      emit(CreatePurchaseOrderSuccess(record));
    } catch (e) {
      final message = e is ArgumentError ? e.message.toString() : e.toString();
      emit(CreatePurchaseOrderFailure(message));
    }
  }
}
