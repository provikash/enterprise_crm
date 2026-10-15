import 'package:flutter/material.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/employee_document.dart';
import '../../domain/policies/hr_access_policy.dart';
import '../../domain/repositories/employee_document_repository.dart';
import '../../domain/repositories/employee_repository.dart';
import 'employee_documents_screen.dart';

enum _DocumentComplianceFilter { all, actionRequired, expiring, complete }

class HrDocumentsDashboardScreen extends StatefulWidget {
  final CurrentUser user;
  final EmployeeRepository employeeRepository;
  final EmployeeDocumentRepository documentRepository;

  const HrDocumentsDashboardScreen({
    super.key,
    required this.user,
    required this.employeeRepository,
    required this.documentRepository,
  });

  @override
  State<HrDocumentsDashboardScreen> createState() =>
      _HrDocumentsDashboardScreenState();
}

class _HrDocumentsDashboardScreenState
    extends State<HrDocumentsDashboardScreen> {
  final _searchController = TextEditingController();
  late Future<List<_EmployeeDocumentRecord>> _records;
  var _filter = _DocumentComplianceFilter.all;

  @override
  void initState() {
    super.initState();
    _records = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<_EmployeeDocumentRecord>> _load() async {
    final employees = await widget.employeeRepository.getEmployees();
    return Future.wait([
      for (final employee in employees)
        widget.documentRepository
            .getDocumentsForEmployee(employee.id)
            .then((documents) => _EmployeeDocumentRecord(employee, documents)),
    ]);
  }

  void _refresh() => setState(() => _records = _load());

  @override
  Widget build(BuildContext context) {
    if (!HrAccessPolicy.canViewDocuments(widget.user)) {
      return const AccessRestrictedScreen();
    }
    return Scaffold(
      key: const Key('hr_documents_dashboard'),
      appBar: AppBar(
        title: const Text('Document management'),
        actions: [
          IconButton(
            tooltip: 'Refresh documents',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<_EmployeeDocumentRecord>>(
        future: _records,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _DocumentsFailure(onRetry: _refresh);
          }
          return _buildDashboard(snapshot.data ?? const []);
        },
      ),
    );
  }

  Widget _buildDashboard(List<_EmployeeDocumentRecord> records) {
    final now = DateTime.now();
    final expiringThreshold = now.add(const Duration(days: 60));
    final totalDocuments = records.fold<int>(
      0,
      (total, record) => total + record.documents.length,
    );
    final expired = records.fold<int>(
      0,
      (total, record) =>
          total +
          record.documents.where((doc) => doc.isExpired(now: now)).length,
    );
    final expiring = records.fold<int>(
      0,
      (total, record) =>
          total +
          record.documents
              .where(
                (doc) =>
                    doc.expiryDate != null &&
                    !doc.isExpired(now: now) &&
                    !doc.expiryDate!.isAfter(expiringThreshold),
              )
              .length,
    );
    final missing = records.where((record) => record.documents.isEmpty).length;
    final query = _searchController.text.trim().toLowerCase();
    final filtered = records.where((record) {
      final matchesSearch =
          query.isEmpty ||
          record.employee.fullName.toLowerCase().contains(query) ||
          (record.employee.employeeCode ?? '').toLowerCase().contains(query) ||
          record.documents.any(
            (doc) =>
                doc.title.toLowerCase().contains(query) ||
                doc.documentType.toLowerCase().contains(query),
          );
      if (!matchesSearch) return false;
      return switch (_filter) {
        _DocumentComplianceFilter.all => true,
        _DocumentComplianceFilter.actionRequired =>
          record.documents.isEmpty ||
              record.documents.any((doc) => doc.isExpired(now: now)),
        _DocumentComplianceFilter.expiring => record.documents.any(
          (doc) =>
              doc.expiryDate != null &&
              !doc.isExpired(now: now) &&
              !doc.expiryDate!.isAfter(expiringThreshold),
        ),
        _DocumentComplianceFilter.complete =>
          record.documents.isNotEmpty &&
              !record.documents.any((doc) => doc.isExpired(now: now)),
      };
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        _refresh();
        await _records;
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Workforce document control',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          const Text(
            'Monitor employee files, identity records, agreements, certificates and expiry compliance from one workspace.',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SummaryCard(
                'Employees',
                '${records.length}',
                Icons.people_outline,
              ),
              _SummaryCard(
                'Documents',
                '$totalDocuments',
                Icons.folder_outlined,
              ),
              _SummaryCard(
                'Expiring in 60 days',
                '$expiring',
                Icons.schedule_outlined,
              ),
              _SummaryCard(
                'Expired',
                '$expired',
                Icons.error_outline,
                warning: expired > 0,
              ),
              _SummaryCard(
                'Missing documents',
                '$missing',
                Icons.folder_off_outlined,
                warning: missing > 0,
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('hr_documents_search'),
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search employees or documents',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<_DocumentComplianceFilter>(
              segments: const [
                ButtonSegment(
                  value: _DocumentComplianceFilter.all,
                  label: Text('All'),
                ),
                ButtonSegment(
                  value: _DocumentComplianceFilter.actionRequired,
                  label: Text('Action required'),
                ),
                ButtonSegment(
                  value: _DocumentComplianceFilter.expiring,
                  label: Text('Expiring'),
                ),
                ButtonSegment(
                  value: _DocumentComplianceFilter.complete,
                  label: Text('Compliant'),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (value) =>
                  setState(() => _filter = value.single),
            ),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No employees match this document filter.'),
                ),
              ),
            ),
          for (final record in filtered)
            _EmployeeDocumentTile(
              record: record,
              now: now,
              onOpen: () => _openEmployeeDocuments(record.employee),
            ),
        ],
      ),
    );
  }

  Future<void> _openEmployeeDocuments(Employee employee) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EmployeeDocumentsScreen(
          user: widget.user,
          employee: employee,
          repository: widget.documentRepository,
        ),
      ),
    );
    if (mounted) _refresh();
  }
}

class _EmployeeDocumentRecord {
  final Employee employee;
  final List<EmployeeDocument> documents;
  const _EmployeeDocumentRecord(this.employee, this.documents);
}

class _EmployeeDocumentTile extends StatelessWidget {
  final _EmployeeDocumentRecord record;
  final DateTime now;
  final VoidCallback onOpen;
  const _EmployeeDocumentTile({
    required this.record,
    required this.now,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final expired = record.documents
        .where((doc) => doc.isExpired(now: now))
        .length;
    final status = record.documents.isEmpty
        ? 'Missing documents'
        : expired > 0
        ? '$expired expired'
        : 'Compliant';
    final warning = record.documents.isEmpty || expired > 0;
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(record.employee.fullName[0])),
        title: Text(record.employee.fullName),
        subtitle: Text(
          '${record.employee.employeeCode ?? 'No employee code'} · ${record.employee.department ?? 'No department'} · ${record.documents.length} files',
        ),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Chip(
              avatar: Icon(
                warning ? Icons.warning_amber : Icons.verified_outlined,
                size: 17,
              ),
              label: Text(status),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onOpen,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool warning;
  const _SummaryCard(this.label, this.value, this.icon, {this.warning = false});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 210,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: warning ? Theme.of(context).colorScheme.error : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.headlineSmall),
                  Text(label),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DocumentsFailure extends StatelessWidget {
  final VoidCallback onRetry;
  const _DocumentsFailure({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 44),
        const SizedBox(height: 8),
        const Text('Employee documents could not be loaded.'),
        const SizedBox(height: 12),
        FilledButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
