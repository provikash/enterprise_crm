import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/timeline_entry.dart';

class ApprovalTimeline extends StatelessWidget {
  final List<ApprovalTimelineEntry> entries;
  const ApprovalTimeline({super.key, required this.entries});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final entry in entries)
        ListTile(
          leading: Icon(
            entry.occurredAt != null
                ? Icons.check_circle_outline
                : entry.isCurrent
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
          ),
          title: Text(entry.label),
          subtitle: Text(
            [
              entry.actorName,
              if (entry.occurredAt != null)
                DateFormat('dd MMM yyyy, HH:mm').format(entry.occurredAt!),
              if (entry.comment?.trim().isNotEmpty == true) entry.comment!,
            ].join(' • '),
          ),
        ),
    ],
  );
}

class AuditTimeline extends StatelessWidget {
  final List<AuditTimelineEntry> entries;
  final bool revealSensitive;

  const AuditTimeline({
    super.key,
    required this.entries,
    this.revealSensitive = false,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final entry in entries)
        ExpansionTile(
          leading: const Icon(Icons.history),
          title: Text(entry.action),
          subtitle: Text(
            '${entry.actorName} • ${DateFormat('dd MMM yyyy, HH:mm').format(entry.occurredAt)}',
          ),
          childrenPadding: const EdgeInsets.fromLTRB(56, 0, 16, 12),
          children: [
            if (entry.reason != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Reason: ${entry.reason}'),
              ),
            for (final change in entry.changes)
              Row(
                children: [
                  Expanded(child: Text(change.fieldLabel)),
                  Flexible(
                    child: Text(_value(change.before, change.sensitive)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, size: 16),
                  ),
                  Flexible(child: Text(_value(change.after, change.sensitive))),
                ],
              ),
          ],
        ),
    ],
  );

  String _value(String? value, bool sensitive) =>
      sensitive && !revealSensitive ? '••••••' : (value ?? '—');
}
