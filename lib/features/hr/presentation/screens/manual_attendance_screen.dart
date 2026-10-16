import 'package:flutter/material.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../domain/entities/attendance_daily.dart';
import '../../domain/entities/employee.dart';
import '../../domain/inputs/manual_attendance_input.dart';
import '../../domain/policies/hr_access_policy.dart';
import '../../domain/repositories/attendance_management_repository.dart';
import '../../domain/repositories/employee_repository.dart';

class ManualAttendanceScreen extends StatefulWidget {
  final CurrentUser user;
  final AttendanceManagementRepository repository;
  final EmployeeRepository employeeRepository;
  final DateTime? initialDate;

  const ManualAttendanceScreen({
    super.key,
    required this.user,
    required this.repository,
    required this.employeeRepository,
    this.initialDate,
  });

  @override
  State<ManualAttendanceScreen> createState() => _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState extends State<ManualAttendanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  late final Future<List<Employee>> _employees;
  late DateTime _date;
  String? _employeeId;
  TimeOfDay? _checkIn;
  TimeOfDay? _checkOut;
  AttendanceDailyStatus _status = AttendanceDailyStatus.present;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    _date = DateTime(initial.year, initial.month, initial.day);
    _employees = widget.employeeRepository.getEmployees();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!HrAccessPolicy.canManageAttendance(widget.user)) {
      return const AccessRestrictedScreen();
    }
    return Scaffold(
      key: const Key('manual_attendance_scaffold'),
      appBar: AppBar(title: const Text('Add Manual Attendance')),
      body: FutureBuilder<List<Employee>>(
        future: _employees,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load employees: ${snapshot.error}'),
            );
          }
          final employees = snapshot.data!
              .where((employee) => employee.isActive)
              .toList();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Manual changes require a reason. IN/OUT punches are saved as append-only raw logs and the daily record is refreshed. Production recalculation and payroll locking remain server-authoritative.',
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          key: const Key('manual_attendance_error'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        key: const Key('manual_attendance_employee'),
                        initialValue: _employeeId,
                        decoration: const InputDecoration(
                          labelText: 'Employee *',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final employee in employees)
                            DropdownMenuItem(
                              value: employee.id,
                              child: Text(
                                '${employee.fullName} · ${employee.department ?? 'No department'}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _employeeId = value),
                        validator: (value) =>
                            value == null ? 'Please select an employee' : null,
                      ),
                      const SizedBox(height: 16),
                      _DateField(
                        date: _date,
                        onChanged: (value) => setState(() => _date = value),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<AttendanceDailyStatus>(
                        key: const Key('manual_attendance_status'),
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: 'Daily status *',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final status in AttendanceDailyStatus.values)
                            DropdownMenuItem(
                              value: status,
                              child: Text(_statusLabel(status)),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _status = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final fields = [
                            Expanded(
                              child: _TimeField(
                                fieldKey: const Key('manual_attendance_in'),
                                label: 'Check-in',
                                value: _checkIn,
                                onChanged: (value) =>
                                    setState(() => _checkIn = value),
                              ),
                            ),
                            Expanded(
                              child: _TimeField(
                                fieldKey: const Key('manual_attendance_out'),
                                label: 'Check-out',
                                value: _checkOut,
                                onChanged: (value) =>
                                    setState(() => _checkOut = value),
                              ),
                            ),
                          ];
                          if (constraints.maxWidth < 520) {
                            return Column(
                              children: [
                                fields[0],
                                const SizedBox(height: 12),
                                fields[1],
                              ],
                            );
                          }
                          return Row(
                            children: [
                              fields[0],
                              const SizedBox(width: 12),
                              fields[1],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('manual_attendance_reason'),
                        controller: _reasonController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Reason *',
                          hintText: 'Explain why this manual entry is required',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'A reason is required for audit history'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        key: const Key('manual_attendance_submit'),
                        onPressed: _saving ? null : _submit,
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Save manual attendance'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final checkIn = _combine(_checkIn);
    final checkOut = _combine(_checkOut);
    if ({
          AttendanceDailyStatus.present,
          AttendanceDailyStatus.halfDay,
          AttendanceDailyStatus.onDuty,
        }.contains(_status) &&
        checkIn == null) {
      setState(() => _error = 'Check-in is required for this status.');
      return;
    }
    if (checkIn != null && checkOut != null && !checkOut.isAfter(checkIn)) {
      setState(() => _error = 'Check-out must be later than check-in.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.recordManualAttendance(
        ManualAttendanceInput(
          employeeId: _employeeId!,
          date: _date,
          checkIn: checkIn,
          checkOut: checkOut,
          status: _status,
          reason: _reasonController.text.trim(),
          recordedBy: widget.user.id,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString().replaceFirst('AttendanceException: ', '');
        });
      }
    }
  }

  DateTime? _combine(TimeOfDay? value) => value == null
      ? null
      : DateTime(_date.year, _date.month, _date.day, value.hour, value.minute);

  static String _statusLabel(AttendanceDailyStatus value) => switch (value) {
    AttendanceDailyStatus.present => 'Present',
    AttendanceDailyStatus.absent => 'Absent',
    AttendanceDailyStatus.halfDay => 'Half-day',
    AttendanceDailyStatus.leave => 'Leave',
    AttendanceDailyStatus.holiday => 'Holiday',
    AttendanceDailyStatus.weekOff => 'Week off',
    AttendanceDailyStatus.onDuty => 'On duty',
  };
}

class _DateField extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  const _DateField({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    key: const Key('manual_attendance_date'),
    onPressed: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 1)),
      );
      if (picked != null) onChanged(picked);
    },
    icon: const Icon(Icons.event_outlined),
    label: Text(
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    ),
  );
}

class _TimeField extends StatelessWidget {
  final Key fieldKey;
  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?> onChanged;
  const _TimeField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    key: fieldKey,
    onPressed: () async {
      final picked = await showTimePicker(
        context: context,
        initialTime: value ?? const TimeOfDay(hour: 9, minute: 0),
      );
      if (picked != null) onChanged(picked);
    },
    icon: const Icon(Icons.schedule_outlined),
    label: Text(value == null ? label : '$label: ${value!.format(context)}'),
  );
}
