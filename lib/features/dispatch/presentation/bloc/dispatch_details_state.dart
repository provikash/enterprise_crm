import 'package:flutter/foundation.dart';
import '../../domain/entities/dispatch_record.dart';

/// States for the dispatch details and status progression view.
@immutable
sealed class DispatchDetailsState {
  const DispatchDetailsState();
}

/// Initial state before dispatch data is loaded.
final class DispatchDetailsInitial extends DispatchDetailsState {
  const DispatchDetailsInitial();
}

/// State emitted while loading record details.
final class DispatchDetailsLoading extends DispatchDetailsState {
  const DispatchDetailsLoading();
}

/// State emitted when dispatch record is loaded and visible.
final class DispatchDetailsLoaded extends DispatchDetailsState {
  final DispatchRecord record;
  final bool isUpdating;
  final String? updateError;

  const DispatchDetailsLoaded(
    this.record, {
    this.isUpdating = false,
    this.updateError,
  });

  DispatchDetailsLoaded copyWith({
    DispatchRecord? record,
    bool? isUpdating,
    String? updateError,
  }) {
    return DispatchDetailsLoaded(
      record ?? this.record,
      isUpdating: isUpdating ?? this.isUpdating,
      updateError: updateError,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DispatchDetailsLoaded &&
          runtimeType == other.runtimeType &&
          record == other.record &&
          isUpdating == other.isUpdating &&
          updateError == other.updateError;

  @override
  int get hashCode => Object.hash(record, isUpdating, updateError);
}

/// State emitted when loading dispatch record encounters an error.
final class DispatchDetailsFailure extends DispatchDetailsState {
  final String message;

  const DispatchDetailsFailure(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DispatchDetailsFailure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
