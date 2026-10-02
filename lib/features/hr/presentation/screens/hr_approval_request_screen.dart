import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/crm_module.dart';
import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../domain/entities/hr_approval_target.dart';
import '../../domain/entities/hr_approval_workflow_type.dart';
import '../../domain/policies/hr_access_policy.dart';
import '../../domain/repositories/hr_approval_repository.dart';
import '../bloc/hr_approval_request_cubit.dart';
import '../bloc/hr_approval_request_state.dart';
import '../widgets/hr_approval_status_badge.dart';
import 'hr_approval_request_details_screen.dart';

/// Screen allowing authorized HR users to initiate and submit an approval request.
///
/// Invariants:
/// 1. Route access guarded by [HrAccessPolicy.canAccessModule].
/// 2. Preserves stable requester identity from [user.id].
/// 3. Validates required target entity identifier and workflow type.
/// 4. Does not invent arbitrary fields (no approver picker, priority, or deadline).
/// 5. Strictly displays repository-confirmed submission status (e.g. Pending).
class HrApprovalRequestScreen extends StatefulWidget {
  final CurrentUser user;
  final HrApprovalRepository repository;
  final HrApprovalWorkflowType? initialWorkflowType;
  final String? initialTargetEntityType;
  final String? initialTargetId;
  final String? initialRemarks;
  final VoidCallback? onRequestSubmitted;

  const HrApprovalRequestScreen({
    super.key,
    required this.user,
    required this.repository,
    this.initialWorkflowType,
    this.initialTargetEntityType,
    this.initialTargetId,
    this.initialRemarks,
    this.onRequestSubmitted,
  });

  @override
  State<HrApprovalRequestScreen> createState() =>
      _HrApprovalRequestScreenState();
}

class _HrApprovalRequestScreenState extends State<HrApprovalRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  late HrApprovalWorkflowType _selectedWorkflow;
  late String _selectedTargetEntityType;
  late final TextEditingController _targetIdController;
  late final TextEditingController _remarksController;

  static const _availableTargetTypes = <String, String>{
    'payroll_period': 'Payroll Period',
    'attendance_record': 'Attendance Record',
    'employee_document': 'Employee Document',
  };

  @override
  void initState() {
    super.initState();
    _selectedWorkflow =
        widget.initialWorkflowType ?? HrApprovalWorkflowType.payrollFinalization;
    _selectedTargetEntityType = widget.initialTargetEntityType ??
        _defaultTargetEntityTypeFor(_selectedWorkflow);
    _targetIdController =
        TextEditingController(text: widget.initialTargetId ?? '');
    _remarksController =
        TextEditingController(text: widget.initialRemarks ?? '');
  }

  @override
  void dispose() {
    _targetIdController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  static String _defaultTargetEntityTypeFor(HrApprovalWorkflowType workflow) {
    return switch (workflow) {
      HrApprovalWorkflowType.payrollFinalization => 'payroll_period',
      HrApprovalWorkflowType.attendanceCorrection => 'attendance_record',
      HrApprovalWorkflowType.documentVerification => 'employee_document',
    };
  }

  void _onWorkflowChanged(HrApprovalWorkflowType? workflow) {
    if (workflow == null) return;
    setState(() {
      _selectedWorkflow = workflow;
      _selectedTargetEntityType = _defaultTargetEntityTypeFor(workflow);
    });
  }

  void _submitForm(HrApprovalRequestCubit cubit) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final target = HrApprovalTarget(
      targetModule: CrmModule.hrPayroll,
      targetEntityType: _selectedTargetEntityType,
      targetEntityId: _targetIdController.text.trim(),
    );

    final remarks = _remarksController.text.trim().isEmpty
        ? null
        : _remarksController.text.trim();

    cubit.submitRequest(
      workflowType: _selectedWorkflow,
      target: target,
      requester: widget.user,
      remarks: remarks,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!HrAccessPolicy.canAccessModule(widget.user)) {
      return const AccessRestrictedScreen();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocProvider<HrApprovalRequestCubit>(
      create: (_) => HrApprovalRequestCubit(repository: widget.repository),
      child: Scaffold(
        key: const Key('hr_approval_request_scaffold'),
        appBar: AppBar(
          title: const Text('New Approval Request'),
        ),
        body: BlocConsumer<HrApprovalRequestCubit, HrApprovalRequestState>(
          listener: (context, state) {
            if (state is HrApprovalRequestSuccess) {
              widget.onRequestSubmitted?.call();
            }
          },
          builder: (context, state) {
            if (state is HrApprovalRequestSuccess) {
              return _buildSuccessView(context, state);
            }

            final isSubmitting = state is HrApprovalRequestSubmitting;
            final errorMessage =
                state is HrApprovalRequestFailure ? state.message : null;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Request Details',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Submit an authorized HR approval request. Requests will be submitted in Pending status.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),

                            if (errorMessage != null) ...[
                              Container(
                                key: const Key('approval_request_error_banner'),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: colorScheme.onErrorContainer,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        errorMessage,
                                        style: TextStyle(
                                          color: colorScheme.onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Workflow Type dropdown
                            DropdownButtonFormField<HrApprovalWorkflowType>(
                              key: const Key(
                                  'approval_request_workflow_type_dropdown'),
                              isExpanded: true,
                              initialValue: _selectedWorkflow,
                              decoration: const InputDecoration(
                                labelText: 'Workflow Type *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.rule),
                              ),
                              items: HrApprovalWorkflowType.values
                                  .map((workflow) => DropdownMenuItem(
                                        value: workflow,
                                        child: Text(
                                          workflow.displayName,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                              onChanged:
                                  isSubmitting ? null : _onWorkflowChanged,
                            ),
                            const SizedBox(height: 16),

                            // Target Entity Type dropdown
                            DropdownButtonFormField<String>(
                              key: const Key(
                                  'approval_request_target_type_dropdown'),
                              isExpanded: true,
                              initialValue: _selectedTargetEntityType,
                              decoration: const InputDecoration(
                                labelText: 'Target Entity Type *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.category),
                              ),
                              items: _availableTargetTypes.entries
                                  .map((entry) => DropdownMenuItem(
                                        value: entry.key,
                                        child: Text(entry.value),
                                      ))
                                  .toList(),
                              onChanged: isSubmitting
                                  ? null
                                  : (targetType) {
                                      if (targetType != null) {
                                        setState(() {
                                          _selectedTargetEntityType =
                                              targetType;
                                        });
                                      }
                                    },
                            ),
                            const SizedBox(height: 16),

                            // Target Entity ID field
                            TextFormField(
                              key: const Key(
                                  'approval_request_target_id_field'),
                              controller: _targetIdController,
                              enabled: !isSubmitting,
                              decoration: const InputDecoration(
                                labelText: 'Target Entity ID *',
                                hintText:
                                    'e.g. period_2026_01, att_001, doc_001',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.tag),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Target Entity ID is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Remarks field (optional)
                            TextFormField(
                              key:
                                  const Key('approval_request_remarks_field'),
                              controller: _remarksController,
                              enabled: !isSubmitting,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Justification / Remarks (Optional)',
                                hintText:
                                    'Provide reason or context for this request',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.notes),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                key: const Key(
                                    'approval_request_submit_button'),
                                onPressed: isSubmitting
                                    ? null
                                    : () => _submitForm(
                                          context
                                              .read<HrApprovalRequestCubit>(),
                                        ),
                                icon: isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.send),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    isSubmitting
                                        ? 'Submitting...'
                                        : 'Submit Approval Request',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSuccessView(
      BuildContext context, HrApprovalRequestSuccess state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final request = state.request;

    return Center(
      key: const Key('approval_request_success_view'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 40,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Approval Request Submitted',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your request has been successfully created and queued for review.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  _buildInfoRow(
                    label: 'Request ID',
                    valueWidget: Text(
                      request.id,
                      key: const Key('approval_request_success_id'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    label: 'Workflow',
                    valueWidget: Text(
                      request.workflowType.displayName,
                      key: const Key('approval_request_success_workflow'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    label: 'Target',
                    valueWidget: Text(
                      '${request.target.targetEntityType} #${request.target.targetEntityId}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    label: 'Status',
                    valueWidget: HrApprovalStatusBadge(
                      key: const Key('approval_request_success_status'),
                      status: request.status,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const Key('approval_request_done_button'),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Done'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          key: const Key('approval_request_view_details_button'),
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => HrApprovalRequestDetailsScreen(
                                  requestId: request.id,
                                  initialRequest: request,
                                  user: widget.user,
                                  repository: widget.repository,
                                ),
                              ),
                            );
                          },
                          child: const Text('View Details'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required Widget valueWidget,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: valueWidget,
          ),
        ),
      ],
    );
  }
}
