import 'package:flutter/foundation.dart';
import '../../domain/entities/dispatch_record.dart';

/// States for the dispatch creation flow.
@immutable
sealed class CreateDispatchState {
  const CreateDispatchState();
}

/// Initial form state ready for user input.
final class CreateDispatchInitial extends CreateDispatchState {
  const CreateDispatchInitial();
}

/// State emitted while creation request is being processed.
final class CreateDispatchSubmitting extends CreateDispatchState {
  const CreateDispatchSubmitting();
}

/// State emitted when a dispatch is successfully created.
final class CreateDispatchSuccess extends CreateDispatchState {
  final DispatchRecord record;

  const CreateDispatchSuccess(this.record);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateDispatchSuccess &&
          runtimeType == other.runtimeType &&
          record == other.record;

  @override
  int get hashCode => record.hashCode;
}

/// State emitted when dispatch creation fails validation or submission.
final class CreateDispatchFailure extends CreateDispatchState {
  final String message;

  const CreateDispatchFailure(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateDispatchFailure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
