import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/dispatch_status.dart';
import '../../domain/repositories/dispatch_repository.dart';
import 'dispatch_details_state.dart';

/// Cubit managing dispatch record detail inspection and status progression.
class DispatchDetailsCubit extends Cubit<DispatchDetailsState> {
  final DispatchRepository repository;

  DispatchDetailsCubit(this.repository) : super(const DispatchDetailsInitial());

  Future<void> loadDispatch(String id) async {
    emit(const DispatchDetailsLoading());
    try {
      final record = await repository.getDispatchById(id);
      if (record == null) {
        emit(const DispatchDetailsFailure('Dispatch record not found.'));
        return;
      }
      emit(DispatchDetailsLoaded(record));
    } catch (e) {
      emit(DispatchDetailsFailure(e.toString()));
    }
  }

  Future<void> updateStatus(DispatchStatus newStatus, {String? remarks}) async {
    final currentState = state;
    if (currentState is! DispatchDetailsLoaded) return;
    if (currentState.isUpdating) return;

    emit(currentState.copyWith(isUpdating: true, updateError: null));

    try {
      final updated = await repository.updateDispatchStatus(
        currentState.record.id,
        newStatus,
        remarks: remarks,
      );
      emit(DispatchDetailsLoaded(updated));
    } catch (e) {
      emit(currentState.copyWith(isUpdating: false, updateError: e.toString()));
    }
  }
}
