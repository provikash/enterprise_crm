import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/crm_module.dart';
import '../../../auth/domain/entities/current_user.dart';
import '../../../notifications/domain/entities/notification_priority.dart';
import '../../../notifications/domain/services/notification_dispatcher.dart';
import '../../domain/inputs/create_dispatch_input.dart';
import '../../domain/repositories/dispatch_repository.dart';
import 'create_dispatch_state.dart';

/// Cubit managing creation and validation of new dispatch orders.
class CreateDispatchCubit extends Cubit<CreateDispatchState> {
  final DispatchRepository repository;
  final NotificationDispatcher? notificationDispatcher;
  final CurrentUser? currentUser;

  CreateDispatchCubit(
    this.repository, {
    this.notificationDispatcher,
    this.currentUser,
  }) : super(const CreateDispatchInitial());

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

      if (notificationDispatcher != null && currentUser != null) {
        try {
          await notificationDispatcher!.notifySystemAlert(
            recipientUserId: currentUser!.id,
            title: 'Dispatch Order Created: ${record.dispatchCode}',
            message: 'Dispatch to ${record.customerName} via ${record.transporterName} scheduled.',
            priority: NotificationPriority.info,
            module: CrmModule.dispatch,
          );
        } catch (_) {
          // Non-blocking notification dispatch
        }
      }

      emit(CreateDispatchSuccess(record));
    } catch (e) {
      final message = e is ArgumentError ? e.message.toString() : e.toString();
      emit(CreateDispatchFailure(message));
    }
  }
}
