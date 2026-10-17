import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/vendors/data/repositories/mock_vendor_repository.dart';
import 'package:enterprise_crm/features/vendors/presentation/screens/create_edit_vendor_screen.dart';
import 'package:enterprise_crm/features/vendors/presentation/screens/vendor_details_screen.dart';
import 'package:enterprise_crm/features/vendors/presentation/screens/vendor_workspace_screen.dart';

void main() {
  group('Vendor Module Responsive Overflow Tests', () {
    late MockVendorRepository repository;

    const adminUser = CurrentUser(
      id: 'admin_1',
      displayName: 'Admin User',
      accountType: AccountType.admin,
      modules: {CrmModule.vendorManagement},
      permissions: {},
    );

    const testSizes = [
      Size(320, 568),
      Size(360, 640),
      Size(412, 915),
      Size(600, 960),
      Size(800, 1280),
      Size(1024, 768),
      Size(1920, 1080),
    ];

    setUp(() {
      repository = MockVendorRepository();
    });

    for (final size in testSizes) {
      testWidgets('VendorWorkspaceScreen renders cleanly with 0 overflow at $size', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        FlutterErrorDetails? errorDetails;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('overflowed')) {
            errorDetails = details;
          }
          originalOnError?.call(details);
        };

        await tester.pumpWidget(
          MaterialApp(
            home: VendorWorkspaceScreen(
              user: adminUser,
              repository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        FlutterError.onError = originalOnError;
        expect(errorDetails, isNull, reason: 'RenderFlex overflow detected at $size');
      });

      testWidgets('CreateEditVendorScreen renders cleanly with 0 overflow at $size', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        FlutterErrorDetails? errorDetails;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('overflowed')) {
            errorDetails = details;
          }
          originalOnError?.call(details);
        };

        await tester.pumpWidget(
          MaterialApp(
            home: CreateEditVendorScreen(repository: repository),
          ),
        );
        await tester.pumpAndSettle();

        FlutterError.onError = originalOnError;
        expect(errorDetails, isNull, reason: 'RenderFlex overflow detected at $size');
      });

      testWidgets('VendorDetailsScreen renders cleanly with 0 overflow at $size', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final vendor = (await repository.getVendors()).first;

        FlutterErrorDetails? errorDetails;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('overflowed')) {
            errorDetails = details;
          }
          originalOnError?.call(details);
        };

        await tester.pumpWidget(
          MaterialApp(
            home: VendorDetailsScreen(
              initialVendor: vendor,
              repository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        FlutterError.onError = originalOnError;
        expect(errorDetails, isNull, reason: 'RenderFlex overflow detected at $size');
      });
    }
  });
}
