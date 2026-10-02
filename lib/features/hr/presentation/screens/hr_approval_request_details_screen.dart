import 'package:flutter/material.dart';
import '../../../../features/auth/domain/entities/current_user.dart';
import '../../../../features/auth/presentation/screens/access_restricted_screen.dart';
import '../../domain/entities/hr_approval_request.dart';
import '../../domain/policies/hr_access_policy.dart';
import '../../domain/repositories/hr_approval_repository.dart';
import '../widgets/hr_approval_status_badge.dart';

/// Read-only details screen for an individual HR approval request.
///
/// Invariants:
/// - Route protected by [HrAccessPolicy.canAccessModule].
/// - Displays strictly approved domain metadata.
/// - Zero approve/reject decision actions (reserved for HR-9.5).
/// - Responsive card layouts across Android mobile and desktop Web.
class HrApprovalRequestDetailsScreen extends StatefulWidget {
  final String requestId;
  final CurrentUser user;
  final HrApprovalRepository repository;
  final HrApprovalRequest? initialRequest;

  const HrApprovalRequestDetailsScreen({
    super.key,
    required this.requestId,
    required this.user,
    required this.repository,
    this.initialRequest,
  });

  @override
  State<HrApprovalRequestDetailsScreen> createState() =>
      _HrApprovalRequestDetailsScreenState();
}

class _HrApprovalRequestDetailsScreenState
    extends State<HrApprovalRequestDetailsScreen> {
  HrApprovalRequest? _request;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialRequest != null) {
      _request = widget.initialRequest;
    } else {
      _loadRequest();
    }
  }

  Future<void> _loadRequest() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final req = await widget.repository.getRequestById(widget.requestId);
      if (mounted) {
        setState(() {
          _request = req;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Route guard
    if (!HrAccessPolicy.canAccessModule(widget.user)) {
      return const AccessRestrictedScreen();
    }

    return Scaffold(
      key: const Key('hr_approval_details_scaffold'),
      appBar: AppBar(
        title: Text('Request ${widget.requestId}'),
        actions: [
          IconButton(
            key: const Key('hr_approval_details_refresh_button'),
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequest,
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('hr_approval_details_loading'),
        ),
      );
    }

    if (_error != null) {
      return Center(
        key: const Key('hr_approval_details_error'),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: _loadRequest,
              ),
            ],
          ),
        ),
      );
    }

    final req = _request;
    if (req == null) {
      return const Center(
        key: Key('hr_approval_details_not_found'),
        child: Text(
          'Approval request not found.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 600;
        final maxWidth = isDesktop ? 700.0 : double.infinity;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderCard(context, req),
                  const SizedBox(height: 12),
                  _buildWorkflowCard(context, req),
                  const SizedBox(height: 12),
                  _buildTargetCard(context, req),
                  const SizedBox(height: 12),
                  _buildRequesterCard(context, req),
                  if (req.remarks != null && req.remarks!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildRemarksCard(context, req),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(BuildContext context, HrApprovalRequest req) {
    return Card(
      key: const Key('hr_approval_details_header_card'),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.id,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  req.workflowType.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            HrApprovalStatusBadge(status: req.status),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowCard(BuildContext context, HrApprovalRequest req) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workflow Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildDetailRow('Workflow Type', req.workflowType.displayName),
            const SizedBox(height: 8),
            _buildDetailRow('Identifier', req.workflowType.identifier),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetCard(BuildContext context, HrApprovalRequest req) {
    return Card(
      key: const Key('hr_approval_details_target_card'),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Target Entity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildDetailRow('Target Module', req.target.targetModule.name),
            const SizedBox(height: 8),
            _buildDetailRow('Entity Type', req.target.targetEntityType),
            const SizedBox(height: 8),
            _buildDetailRow('Entity ID', req.target.targetEntityId),
          ],
        ),
      ),
    );
  }

  Widget _buildRequesterCard(BuildContext context, HrApprovalRequest req) {
    final createdStr = req.createdAt.toIso8601String().replaceFirst('T', ' ').split('.').first;
    final updatedStr = req.updatedAt
        ?.toIso8601String()
        .replaceFirst('T', ' ')
        .split('.')
        .first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submission & Audit Metadata',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildDetailRow('Requester User ID', req.requesterId),
            const SizedBox(height: 8),
            _buildDetailRow('Submitted At (UTC)', createdStr),
            if (updatedStr != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Updated At (UTC)', updatedStr),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRemarksCard(BuildContext context, HrApprovalRequest req) {
    return Card(
      key: const Key('hr_approval_details_remarks_card'),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submission Remarks',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Text(
              req.remarks!,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
