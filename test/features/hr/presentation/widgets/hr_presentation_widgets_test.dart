import 'package:enterprise_crm/features/hr/presentation/widgets/hr_empty_state.dart';
import 'package:enterprise_crm/features/hr/presentation/widgets/hr_error_state.dart';
import 'package:enterprise_crm/features/hr/presentation/widgets/hr_feature_card.dart';
import 'package:enterprise_crm/features/hr/presentation/widgets/hr_info_row.dart';
import 'package:enterprise_crm/features/hr/presentation/widgets/hr_page_header.dart';
import 'package:enterprise_crm/features/hr/presentation/widgets/hr_responsive_grid.dart';
import 'package:enterprise_crm/features/hr/presentation/widgets/hr_section_card.dart';
import 'package:enterprise_crm/features/hr/presentation/widgets/hr_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child, {Size size = const Size(800, 600)}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  group('HR Presentation Widgets Tests', () {
    testWidgets('HrFeatureCard renders title, description, and triggers onTap', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        wrap(
          HrFeatureCard(
            title: 'Employees',
            description: 'Manage workforce directory',
            icon: Icons.people,
            metric: '12 active',
            badge: 'Core',
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Employees'), findsOneWidget);
      expect(find.text('Manage workforce directory'), findsOneWidget);
      expect(find.text('12 active'), findsOneWidget);
      expect(find.text('Core'), findsOneWidget);

      await tester.tap(find.text('Employees'));
      expect(tapped, isTrue);
    });

    testWidgets('HrResponsiveGrid renders children and respects width', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const HrResponsiveGrid(
            children: [
              Text('Item 1'),
              Text('Item 2'),
              Text('Item 3'),
            ],
          ),
          size: const Size(1000, 600),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('HrSectionCard renders title, icon, and children', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const HrSectionCard(
            title: 'Organization',
            icon: Icons.business,
            children: [
              Text('Engineering Dept'),
            ],
          ),
        ),
      );

      expect(find.text('Organization'), findsOneWidget);
      expect(find.text('Engineering Dept'), findsOneWidget);
    });

    testWidgets('HrSummaryCard renders label, value, and triggers onTap', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrap(
          HrSummaryCard(
            label: 'Present',
            value: '42',
            icon: Icons.check,
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Present'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);

      await tester.tap(find.text('Present'));
      expect(tapped, isTrue);
    });

    testWidgets('HrInfoRow renders label and value with responsive layout', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const HrInfoRow(
            label: 'Email',
            value: 'alice@enterprise.com',
            icon: Icons.email,
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('alice@enterprise.com'), findsOneWidget);
    });

    testWidgets('HrPageHeader renders title, subtitle, and action', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          HrPageHeader(
            title: 'Workforce',
            subtitle: 'Manage all employees',
            primaryAction: ElevatedButton(
              onPressed: () {},
              child: const Text('Add'),
            ),
          ),
        ),
      );

      expect(find.text('Workforce'), findsOneWidget);
      expect(find.text('Manage all employees'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('HrEmptyState renders title and action', (tester) async {
      await tester.pumpWidget(
        wrap(
          const HrEmptyState(
            title: 'No Data',
            description: 'Please add items',
          ),
        ),
      );

      expect(find.text('No Data'), findsOneWidget);
      expect(find.text('Please add items'), findsOneWidget);
    });

    testWidgets('HrErrorState renders error and retry button', (
      tester,
    ) async {
      bool retried = false;
      await tester.pumpWidget(
        wrap(
          HrErrorState(
            message: 'Network issue',
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Network issue'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });
}
