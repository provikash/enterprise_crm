import 'package:enterprise_crm/features/leads/domain/entities/lead.dart';
import 'package:enterprise_crm/features/leads/domain/entities/lead_assignee.dart';
import 'package:enterprise_crm/features/leads/domain/entities/lead_assignment_request.dart';
import 'package:enterprise_crm/features/leads/domain/entities/lead_draft.dart';
import 'package:enterprise_crm/features/leads/domain/entities/lead_export.dart';
import 'package:enterprise_crm/features/leads/domain/entities/lead_import.dart';
import 'package:enterprise_crm/features/leads/domain/entities/lead_page.dart';
import 'package:enterprise_crm/features/leads/domain/entities/lead_query.dart';
import 'package:enterprise_crm/features/leads/domain/entities/lead_source.dart';
import 'package:enterprise_crm/features/leads/domain/entities/lead_status.dart';
import 'package:enterprise_crm/features/leads/domain/entities/lead_summary.dart';
import 'package:enterprise_crm/features/leads/domain/repositories/lead_repository.dart';
import 'package:enterprise_crm/features/leads/presentation/widgets/inbound_lead_simulator_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSimulatorLeadRepository implements LeadRepository {
  List<Lead> leads = [];
  bool shouldThrow = false;
  int createLeadCount = 0;
  CreateLeadInput? lastCreateInput;

  @override
  Future<Lead> createLead(CreateLeadInput input) async {
    createLeadCount++;
    lastCreateInput = input;
    if (shouldThrow) {
      throw Exception('Simulated network ingestion error');
    }
    final lead = Lead(
      id: 'LEAD-${leads.length + 1}',
      name: input.draft.name,
      businessName: input.draft.businessName,
      phone: input.draft.phone,
      email: input.draft.email,
      city: input.draft.city,
      state: input.draft.state,
      source: input.draft.source ?? LeadSource.manual,
      status: const LeadStatus('New'),
      metadata: input.draft.metadata,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    leads.add(lead);
    return lead;
  }

  @override
  Future<LeadPage> getLeads([LeadQuery query = const LeadQuery()]) async =>
      LeadPage(
        items: leads,
        currentPage: 1,
        pageSize: 20,
        totalItems: leads.length,
        hasNext: false,
      );

  @override
  Future<Lead?> getLeadById(String leadId) async =>
      leads.where((l) => l.id == leadId).firstOrNull;

  @override
  Future<Lead> updateLead(UpdateLeadInput input) async =>
      const Lead(id: 'dummy');

  @override
  Future<void> assignLead({
    required String leadId,
    required String assigneeId,
  }) async {}

  @override
  Future<void> assignLeads(LeadAssignmentRequest request) async {}

  @override
  Future<void> reassignLead(LeadReassignmentRequest request) async {}

  @override
  Future<List<LeadAssignee>> getAssignableUsers() async => const [];

  @override
  Future<LeadImportResult> importLeads(LeadImportRequest request) async =>
      const LeadImportResult(
        totalRows: 0,
        importedRows: 0,
        skippedRows: 0,
        failedRows: 0,
        duplicateRows: 0,
      );

  @override
  Future<LeadExportResult> exportLeads(LeadExportRequest request) async =>
      const LeadExportResult(fileReference: '', fileName: '');

  @override
  Future<LeadSummary> getLeadSummary() async => const LeadSummary(
    totalLeads: 0,
    assignedLeads: 0,
    unassignedLeads: 0,
    manualLeads: 0,
    excelLeads: 0,
    csvLeads: 0,
  );
}

void main() {
  late _FakeSimulatorLeadRepository repository;

  setUp(() {
    repository = _FakeSimulatorLeadRepository();
  });

  Widget buildDialogWidget({void Function(Lead)? onLeadCreated}) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () {
                InboundLeadSimulatorDialog.show(
                  context,
                  repository: repository,
                  onLeadCreated: onLeadCreated,
                );
              },
              child: const Text('Open Simulator'),
            ),
          ),
        ),
      ),
    );
  }

  group('InboundLeadSimulatorDialog', () {
    testWidgets('renders dialog header and initial Meta Campaign tab', (
      tester,
    ) async {
      await tester.pumpWidget(buildDialogWidget());
      await tester.tap(find.text('Open Simulator'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('inbound_lead_simulator_dialog')), findsOneWidget);
      expect(find.text('Simulate Inbound Lead'), findsOneWidget);
      expect(find.text('Meta Campaign'), findsOneWidget);
      expect(find.text('Web Portal'), findsOneWidget);

      // Meta fields present by default
      expect(find.byKey(const Key('meta_name_input')), findsOneWidget);
      expect(find.byKey(const Key('meta_campaign_name_input')), findsOneWidget);
      expect(find.byKey(const Key('meta_ad_name_input')), findsOneWidget);
      expect(find.byKey(const Key('simulator_submit_button')), findsOneWidget);
      expect(find.text('Ingest Meta Lead'), findsOneWidget);
    });

    testWidgets('successfully ingests Meta Campaign lead', (tester) async {
      Lead? createdLead;
      await tester.pumpWidget(
        buildDialogWidget(onLeadCreated: (lead) => createdLead = lead),
      );
      await tester.tap(find.text('Open Simulator'));
      await tester.pumpAndSettle();

      // Submit pre-filled meta form
      await tester.tap(find.byKey(const Key('simulator_submit_button')));
      await tester.pumpAndSettle();

      // Dialog should close on success
      expect(find.byKey(const Key('inbound_lead_simulator_dialog')), findsNothing);
      expect(createdLead, isNotNull);
      expect(createdLead!.source, equals(LeadSource.metaCampaign));
      expect(createdLead!.name, equals('Suresh Raina'));
      expect(createdLead!.metadata?['campaignName'], equals('Diwali Festive B2B Acquisition'));
      expect(repository.createLeadCount, equals(1));
    });

    testWidgets('switches to Web Portal tab and ingests portal lead', (
      tester,
    ) async {
      Lead? createdLead;
      await tester.pumpWidget(
        buildDialogWidget(onLeadCreated: (lead) => createdLead = lead),
      );
      await tester.tap(find.text('Open Simulator'));
      await tester.pumpAndSettle();

      // Switch to Web Portal tab
      await tester.tap(find.text('Web Portal'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('portal_name_input')), findsOneWidget);
      expect(find.byKey(const Key('portal_site_name_input')), findsOneWidget);
      expect(find.byKey(const Key('portal_utm_source_input')), findsOneWidget);
      expect(find.text('Ingest Portal Lead'), findsOneWidget);

      // Submit portal form
      await tester.tap(find.byKey(const Key('simulator_submit_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('inbound_lead_simulator_dialog')), findsNothing);
      expect(createdLead, isNotNull);
      expect(createdLead!.source, equals(LeadSource.portal));
      expect(createdLead!.name, equals('Ananya Deshmukh'));
      expect(createdLead!.metadata?['utmSource'], equals('google_ads'));
      expect(repository.createLeadCount, equals(1));
    });

    testWidgets('displays error message when ingestion fails', (
      tester,
    ) async {
      repository.shouldThrow = true;
      await tester.pumpWidget(buildDialogWidget());
      await tester.tap(find.text('Open Simulator'));
      await tester.pumpAndSettle();

      // Submit meta form
      await tester.tap(find.byKey(const Key('simulator_submit_button')));
      await tester.pumpAndSettle();

      // Dialog remains open and shows error banner
      expect(find.byKey(const Key('inbound_lead_simulator_dialog')), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('dismisses dialog when cancel button tapped', (tester) async {
      await tester.pumpWidget(buildDialogWidget());
      await tester.tap(find.text('Open Simulator'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('inbound_lead_simulator_dialog')), findsNothing);
      expect(repository.createLeadCount, equals(0));
    });
  });
}
