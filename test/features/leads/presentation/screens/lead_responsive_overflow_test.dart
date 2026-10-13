import 'package:enterprise_crm/features/leads/data/repositories/mock_lead_repository.dart';
import 'package:enterprise_crm/features/leads/presentation/screens/lead_dashboard_screen.dart';
import 'package:enterprise_crm/features/leads/presentation/screens/lead_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final viewports = <String, Size>{
    'Size(510, 230)': const Size(510, 230),
    'Size(400, 445)': const Size(400, 445),
    'Size(400, 800)': const Size(400, 800),
    'Size(320, 568)': const Size(320, 568),
    'Size(600, 350)': const Size(600, 350),
    'Size(700, 400)': const Size(700, 400),
    'Size(800, 400)': const Size(800, 400),
    'Size(1200, 800)': const Size(1200, 800),
  };

  group('LeadListScreen Responsive Overflow Tests', () {
    for (final entry in viewports.entries) {
      testWidgets('LeadListScreen renders without overflow at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = MockLeadRepository();
        await tester.pumpWidget(
          MaterialApp(
            home: LeadListScreen(repository: repo),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed at size ${entry.key}');
      });
    }
  });

  group('LeadDashboardScreen Responsive Overflow Tests', () {
    for (final entry in viewports.entries) {
      testWidgets('LeadDashboardScreen renders without overflow at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = MockLeadRepository();
        await tester.pumpWidget(
          MaterialApp(
            home: LeadDashboardScreen(repository: repo),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed at size ${entry.key}');
      });
    }
  });
}
