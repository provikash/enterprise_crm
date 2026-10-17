import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/vendors/data/repositories/mock_vendor_repository.dart';
import 'package:enterprise_crm/features/vendors/presentation/screens/vendor_workspace_screen.dart';
import 'package:enterprise_crm/features/vendors/presentation/widgets/vendor_data_table.dart';
import 'package:enterprise_crm/features/vendors/presentation/widgets/vendor_mobile_card.dart';

void main() {
  group('VendorWorkspaceScreen Widget Tests', () {
    late MockVendorRepository repository;

    const adminUser = CurrentUser(
      id: 'admin_1',
      displayName: 'Admin User',
      accountType: AccountType.admin,
      modules: {CrmModule.vendorManagement},
      permissions: {},
    );

    const unauthorizedUser = CurrentUser(
      id: 'user_1',
      displayName: 'Standard User',
      accountType: AccountType.user,
      modules: {CrmModule.leadManagement},
      permissions: {},
    );

    setUp(() {
      repository = MockVendorRepository();
    });

    testWidgets('unauthorized user sees AccessRestrictedScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VendorWorkspaceScreen(
            user: unauthorizedUser,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsOneWidget);
    });

    testWidgets('authorized admin on desktop sees summary cards, filter bar, and data table', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: VendorWorkspaceScreen(
            user: adminUser,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vendor Management'), findsOneWidget);
      expect(find.byKey(const Key('vendor_summary_total')), findsOneWidget);
      expect(find.byKey(const Key('vendor_search_field')), findsOneWidget);
      expect(find.byType(VendorDataTable), findsOneWidget);
      expect(find.byKey(const Key('vendor_add_button')), findsOneWidget);
      expect(find.byKey(const Key('vendor_export_button')), findsOneWidget);
    });

    testWidgets('authorized user on mobile sees mobile cards', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: VendorWorkspaceScreen(
            user: adminUser,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VendorMobileCard), findsWidgets);
      expect(find.byType(VendorDataTable), findsNothing);
    });

    testWidgets('typing in search field filters vendors', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: VendorWorkspaceScreen(
            user: adminUser,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('vendor_search_field')), 'Apex');
      await tester.pumpAndSettle();

      expect(find.text('Apex Tech Supplies Pvt Ltd'), findsOneWidget);
      expect(find.text('Global Office Furnishings'), findsNothing);
    });
  });
}
