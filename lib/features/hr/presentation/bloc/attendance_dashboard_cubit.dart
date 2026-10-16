import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/attendance_repository.dart';
import 'attendance_dashboard_state.dart';

/// Loads only the selected day's authoritative Attendance records.
class AttendanceDashboardCubit extends Cubit<AttendanceDashboardState> {
  final AttendanceRepository _repository;
  int _requestId = 0;

  AttendanceDashboardCubit({
    required AttendanceRepository repository,
    required DateTime initialDate,
  }) : _repository = repository,
       super(AttendanceDashboardState(selectedDate: initialDate));

  Future<void> loadDate(DateTime date) async {
    final normalized = DateTime.utc(date.year, date.month, date.day);
    final requestId = ++_requestId;
    emit(
      state.copyWith(
        status: AttendanceDashboardStatus.loading,
        selectedDate: normalized,
        errorMessage: () => null,
      ),
    );

    try {
      final records = await _repository.getAttendanceForDate(normalized);
      if (isClosed || requestId != _requestId) return;
      emit(
        state.copyWith(
          status: AttendanceDashboardStatus.loaded,
          records: List.unmodifiable(records),
          errorMessage: () => null,
        ),
      );
    } on AttendanceException catch (error) {
      if (isClosed || requestId != _requestId) return;
      emit(
        state.copyWith(
          status: AttendanceDashboardStatus.failure,
          records: const [],
          errorMessage: () => error.message,
        ),
      );
    } catch (_) {
      if (isClosed || requestId != _requestId) return;
      emit(
        state.copyWith(
          status: AttendanceDashboardStatus.failure,
          records: const [],
          errorMessage: () => 'Unable to load attendance for this date.',
        ),
      );
    }
  }

  Future<void> refresh() => loadDate(state.selectedDate);
}
