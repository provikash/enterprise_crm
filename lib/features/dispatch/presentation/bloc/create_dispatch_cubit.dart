import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/inputs/create_dispatch_input.dart';
import '../../domain/repositories/dispatch_repository.dart';
import 'create_dispatch_state.dart';

/// Cubit managing creation and validation of new dispatch orders.
class CreateDispatchCubit extends Cubit<CreateDispatchState> {
  final DispatchRepository repository;

  CreateDispatchCubit(this.repository) : super(const CreateDispatchInitial());

  Future<void> submit(CreateDispatchInput input) async {
    if (state is CreateDispatchSubmitting) return;

    final error = input.validate();
    if (error != null) {
      emit(CreateDispatchFailure(error));
      return;
    }

    emit(const CreateDispatchSubmitting());

    try {
      final record = await repository.createDispatch(input);
      emit(CreateDispatchSuccess(record));
    } catch (e) {
      final message = e is ArgumentError ? e.message.toString() : e.toString();
      emit(CreateDispatchFailure(message));
    }
  }
}
