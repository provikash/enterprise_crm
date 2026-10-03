import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import 'attendance_list_state.dart';

/// Cubit managing attendance listing, calendar view, filtering, and search.
class AttendanceListCubit extends Cubit<AttendanceListState> {
  final AttendanceRepository _repository;
  final String? initialEmployeeId;
  int _requestId = 0;

  AttendanceListCubit(this._repository, {this.initialEmployeeId})
    : super(AttendanceListState(selectedEmployeeId: initialEmployeeId));

  /// Loads attendance records from the repository.
  Future<void> loadAttendance() async {
    final currentRequestId = ++_requestId;
    emit(state.copyWith(status: AttendanceListStatus.loading));
    try {
      final records = await _repository.getAttendanceRecords(
        employeeId: state.selectedEmployeeId,
        startDate: state.selectedDate,
        endDate: state.selectedDate,
        status: state.selectedStatus,
      );
      if (currentRequestId != _requestId) return;

      final filtered = _applyFilters(
        records,
        state.searchQuery,
        state.selectedStatus,
        state.selectedDate,
        state.selectedEmployeeId,
      );

      emit(
        state.copyWith(
          status: AttendanceListStatus.loaded,
          records: records,
          calendarRecords: state.selectedDate == null ? records : state.calendarRecords,
          filteredRecords: filtered,
          errorMessage: () => null,
        ),
      );
    } on AttendanceException catch (e) {
      if (currentRequestId != _requestId) return;
      emit(
        state.copyWith(
          status: AttendanceListStatus.failure,
          errorMessage: () => e.message,
        ),
      );
    } catch (_) {
      if (currentRequestId != _requestId) return;
      emit(
        state.copyWith(
          status: AttendanceListStatus.failure,
          errorMessage: () =>
              'Failed to load attendance records. Please try again.',
        ),
      );
    }
  }

  /// Sets the search query and filters records locally.
  void setSearchQuery(String query) {
    final baseList = state.calendarRecords.isNotEmpty ? state.calendarRecords : state.records;
    final filtered = _applyFilters(
      baseList,
      query,
      state.selectedStatus,
      state.selectedDate,
      state.selectedEmployeeId,
    );
    emit(state.copyWith(searchQuery: query, filteredRecords: filtered));
  }

  /// Sets the status filter (e.g. 'Present', 'Absent', 'Half-day', 'On Leave').
  Future<void> setStatusFilter(String? status, {bool queryRepository = false}) async {
    final normalizedStatus = (status == null || status.trim().toLowerCase() == 'all')
        ? null
        : status.trim();

    final baseList = state.calendarRecords.isNotEmpty ? state.calendarRecords : state.records;
    final filtered = _applyFilters(
      baseList,
      state.searchQuery,
      normalizedStatus,
      state.selectedDate,
      state.selectedEmployeeId,
    );
    emit(
      state.copyWith(
        selectedStatus: () => normalizedStatus,
        filteredRecords: filtered,
      ),
    );

    if (!queryRepository) return;

    final currentRequestId = ++_requestId;
    try {
      final records = await _repository.getAttendanceRecords(
        employeeId: state.selectedEmployeeId,
        startDate: state.selectedDate,
        endDate: state.selectedDate,
        status: normalizedStatus,
      );
      if (currentRequestId != _requestId) return;

      final updatedFiltered = _applyFilters(
        records,
        state.searchQuery,
        normalizedStatus,
        state.selectedDate,
        state.selectedEmployeeId,
      );
      emit(
        state.copyWith(
          status: AttendanceListStatus.loaded,
          records: records,
          filteredRecords: updatedFiltered,
          errorMessage: () => null,
        ),
      );
    } on AttendanceException catch (e) {
      if (currentRequestId != _requestId) return;
      emit(state.copyWith(
        status: AttendanceListStatus.failure,
        errorMessage: () => e.message,
      ));
    } catch (_) {
      if (currentRequestId != _requestId) return;
      emit(state.copyWith(
        status: AttendanceListStatus.failure,
        errorMessage: () => 'Failed to load attendance records.',
      ));
    }
  }

  /// Sets the selected calendar/filter date with stale-response protection.
  Future<void> setSelectedDate(DateTime? date, {bool queryRepository = true}) async {
    final normalized = date != null
        ? DateTime.utc(date.year, date.month, date.day)
        : null;
    final currentRequestId = ++_requestId;

    final baseList = state.calendarRecords.isNotEmpty ? state.calendarRecords : state.records;
    final filtered = _applyFilters(
      baseList,
      state.searchQuery,
      state.selectedStatus,
      normalized,
      state.selectedEmployeeId,
    );
    emit(
      state.copyWith(
        selectedDate: () => normalized,
        filteredRecords: filtered,
      ),
    );

    if (!queryRepository) return;

    try {
      final records = await _repository.getAttendanceRecords(
        employeeId: state.selectedEmployeeId,
        startDate: normalized,
        endDate: normalized,
        status: state.selectedStatus,
      );
      if (currentRequestId != _requestId) return; // Discard stale response!

      final updatedFiltered = _applyFilters(
        records,
        state.searchQuery,
        state.selectedStatus,
        normalized,
        state.selectedEmployeeId,
      );
      emit(
        state.copyWith(
          status: AttendanceListStatus.loaded,
          records: records,
          calendarRecords: state.calendarRecords.isEmpty && normalized == null
              ? records
              : state.calendarRecords,
          filteredRecords: updatedFiltered,
          errorMessage: () => null,
        ),
      );
    } on AttendanceException catch (e) {
      if (currentRequestId != _requestId) return;
      emit(state.copyWith(
        status: AttendanceListStatus.failure,
        errorMessage: () => e.message,
      ));
    } catch (_) {
      if (currentRequestId != _requestId) return;
      emit(state.copyWith(
        status: AttendanceListStatus.failure,
        errorMessage: () => 'Failed to load attendance for selected date.',
      ));
    }
  }

  /// Sets employee filter with stale-response protection.
  Future<void> setSelectedEmployeeId(String? employeeId, {bool queryRepository = true}) async {
    final normalizedId = (employeeId != null && employeeId.trim().isNotEmpty)
        ? employeeId.trim()
        : null;
    final currentRequestId = ++_requestId;

    final baseList = state.calendarRecords.isNotEmpty ? state.calendarRecords : state.records;
    final filtered = _applyFilters(
      baseList,
      state.searchQuery,
      state.selectedStatus,
      state.selectedDate,
      normalizedId,
    );
    emit(
      state.copyWith(
        selectedEmployeeId: () => normalizedId,
        filteredRecords: filtered,
      ),
    );

    if (!queryRepository) return;

    try {
      final records = await _repository.getAttendanceRecords(
        employeeId: normalizedId,
        startDate: state.selectedDate,
        endDate: state.selectedDate,
        status: state.selectedStatus,
      );
      if (currentRequestId != _requestId) return; // Discard stale response!

      final updatedFiltered = _applyFilters(
        records,
        state.searchQuery,
        state.selectedStatus,
        state.selectedDate,
        normalizedId,
      );
      emit(
        state.copyWith(
          status: AttendanceListStatus.loaded,
          records: records,
          calendarRecords: state.selectedDate == null ? records : state.calendarRecords,
          filteredRecords: updatedFiltered,
          errorMessage: () => null,
        ),
      );
    } on AttendanceException catch (e) {
      if (currentRequestId != _requestId) return;
      emit(state.copyWith(
        status: AttendanceListStatus.failure,
        errorMessage: () => e.message,
      ));
    } catch (_) {
      if (currentRequestId != _requestId) return;
      emit(state.copyWith(
        status: AttendanceListStatus.failure,
        errorMessage: () => 'Failed to load attendance records.',
      ));
    }
  }

  /// Switches between list and calendar views.
  void setViewMode(AttendanceViewMode mode) {
    emit(state.copyWith(viewMode: mode));
  }

  /// Clears active search and filter constraints and restores default scope.
  Future<void> resetFilters({bool reload = true}) async {
    final currentRequestId = ++_requestId;
    final baseList = state.calendarRecords.isNotEmpty ? state.calendarRecords : state.records;
    final filtered = _applyFilters(
      baseList,
      '',
      null,
      null,
      initialEmployeeId,
    );
    emit(
      state.copyWith(
        searchQuery: '',
        selectedStatus: () => null,
        selectedDate: () => null,
        selectedEmployeeId: () => initialEmployeeId,
        filteredRecords: filtered,
      ),
    );

    if (!reload) return;

    try {
      final records = await _repository.getAttendanceRecords(
        employeeId: initialEmployeeId,
      );
      if (currentRequestId != _requestId) return;
      final updatedFiltered = _applyFilters(
        records,
        '',
        null,
        null,
        initialEmployeeId,
      );
      emit(
        state.copyWith(
          status: AttendanceListStatus.loaded,
          records: records,
          calendarRecords: records,
          filteredRecords: updatedFiltered,
          errorMessage: () => null,
        ),
      );
    } catch (_) {
      // Retain filtered state if reload fails
    }
  }

  /// Refreshes attendance from repository while preserving current filters.
  Future<void> refresh() async {
    await loadAttendance();
  }

  List<AttendanceRecord> _applyFilters(
    List<AttendanceRecord> all,
    String query,
    String? status,
    DateTime? date,
    String? employeeId,
  ) {
    return all.where((r) {
      if (employeeId != null && employeeId.trim().isNotEmpty) {
        if (r.employeeId != employeeId.trim()) return false;
      }

      if (status != null &&
          status.trim().isNotEmpty &&
          status.trim().toLowerCase() != 'all') {
        if (r.attendanceStatus.trim().toLowerCase() !=
            status.trim().toLowerCase()) {
          return false;
        }
      }

      if (date != null) {
        if (!r.isSameDay(date)) return false;
      }

      if (query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchesEmployee = r.employeeId.toLowerCase().contains(q);
        final matchesStatus = r.attendanceStatus.toLowerCase().contains(q);
        final matchesRemarks = r.remarks?.toLowerCase().contains(q) ?? false;
        final matchesDate = r.formattedDate.contains(q);

        if (!matchesEmployee &&
            !matchesStatus &&
            !matchesRemarks &&
            !matchesDate) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}
