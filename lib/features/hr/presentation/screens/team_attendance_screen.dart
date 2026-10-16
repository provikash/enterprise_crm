import 'package:flutter/material.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/employee.dart';
import '../../domain/policies/hr_access_policy.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/repositories/employee_repository.dart';
import '../widgets/attendance_status_badge.dart';

class TeamAttendanceScreen extends StatefulWidget {
  final CurrentUser user;
  final AttendanceRepository attendanceRepository;
  final EmployeeRepository employeeRepository;
  final DateTime? initialDate;

  const TeamAttendanceScreen({
    super.key,
    required this.user,
    required this.attendanceRepository,
    required this.employeeRepository,
    this.initialDate,
  });

  @override
  State<TeamAttendanceScreen> createState() => _TeamAttendanceScreenState();
}

class _TeamAttendanceScreenState extends State<TeamAttendanceScreen> {
  late DateTime _date;
  String? _department;
  late Future<(List<Employee>, List<AttendanceRecord>)> _data;

  @override
  void initState() {
    super.initState();
    final date = widget.initialDate ?? DateTime.now();
    _date = DateTime(date.year, date.month, date.day);
    _load();
  }

  void _load() {
    _data = (
      widget.employeeRepository.getEmployees(),
      widget.attendanceRepository.getAttendanceForDate(_date),
    ).wait;
  }

  @override
  Widget build(BuildContext context) {
    if (!HrAccessPolicy.canViewHrRecords(widget.user)) {
      return const AccessRestrictedScreen();
    }
    return Scaffold(
      key: const Key('team_attendance_scaffold'),
      appBar: AppBar(
        title: const Text('Team / Company Attendance'),
        actions: [
          IconButton(
            onPressed: () => setState(_load),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<(List<Employee>, List<AttendanceRecord>)>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load team attendance: ${snapshot.error}'),
            );
          }
          final employees = snapshot.data!.$1.where((e) => e.isActive).toList();
          final records = snapshot.data!.$2;
          final departments =
              employees
                  .map((e) => e.department)
                  .whereType<String>()
                  .toSet()
                  .toList()
                ..sort();
          final filtered = _department == null
              ? employees
              : employees.where((e) => e.department == _department).toList();
          final byEmployee = {
            for (final record in records) record.employeeId: record,
          };
          final missing = filtered
              .where((e) => !byEmployee.containsKey(e.id))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    key: const Key('team_attendance_date'),
                    icon: const Icon(Icons.event_outlined),
                    label: Text(_formatDate(_date)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setState(() {
                          _date = picked;
                          _load();
                        });
                      }
                    },
                  ),
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<String?>(
                      initialValue: _department,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All departments'),
                        ),
                        for (final department in departments)
                          DropdownMenuItem(
                            value: department,
                            child: Text(department),
                          ),
                      ],
                      onChanged: (value) => setState(() => _department = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _Metric(label: 'Employees', value: filtered.length),
                  _Metric(
                    label: 'Recorded',
                    value: filtered.length - missing.length,
                  ),
                  _Metric(
                    label: 'Not yet checked in',
                    value: missing.length,
                    warning: missing.isNotEmpty,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Attendance records',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Employee')),
                      DataColumn(label: Text('Department')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('First in')),
                      DataColumn(label: Text('Last out')),
                    ],
                    rows: [
                      for (final employee in filtered)
                        DataRow(
                          cells: [
                            DataCell(Text(employee.fullName)),
                            DataCell(Text(employee.department ?? '—')),
                            DataCell(
                              byEmployee[employee.id] == null
                                  ? const Text('Not checked in')
                                  : AttendanceStatusBadge(
                                      status: byEmployee[employee.id]!
                                          .attendanceStatus,
                                    ),
                            ),
                            DataCell(
                              Text(
                                byEmployee[employee.id]?.formattedCheckIn ??
                                    '—',
                              ),
                            ),
                            DataCell(
                              Text(
                                byEmployee[employee.id]?.formattedCheckOut ??
                                    '—',
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              if (missing.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Not yet checked in',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      for (final employee in missing)
                        ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(employee.fullName),
                          subtitle: Text(
                            '${employee.department ?? 'No department'} · ${employee.designation ?? 'No designation'}',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class _Metric extends StatelessWidget {
  final String label;
  final int value;
  final bool warning;
  const _Metric({
    required this.label,
    required this.value,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: Card(
      color: warning ? Theme.of(context).colorScheme.errorContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value', style: Theme.of(context).textTheme.headlineSmall),
            Text(label),
          ],
        ),
      ),
    ),
  );
}
