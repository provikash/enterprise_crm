import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/dashboard/presentation/widgets/crm_app_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_auth_test_fixtures.dart';

Widget _buildHeaderTestApp({
  required CurrentUser user,
  VoidCallback? onLogout,
  ThemeMode themeMode = ThemeMode.light,
  double? width,
}) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
    themeMode: themeMode,
    home: Scaffold(
      body: SizedBox(
        width: width,
        child: CrmAppHeader(user: user, onLogout: onLogout ?? () {}),
      ),
    ),
  );
}

void main() {
  group('CrmAppHeader Tests (Account Avatar in Top Right Corner)', () {
    testWidgets(
      'absent application branding (no Enterprise CRM and no briefcase icon)',
      (tester) async {
        await tester.pumpWidget(
          _buildHeaderTestApp(user: MockAuthTestFixtures.admin),
        );
        await tester.pumpAndSettle();

        expect(find.text('Enterprise CRM'), findsNothing);
        expect(find.byIcon(Icons.business_center), findsNothing);
      },
    );

    testWidgets(
      'Admin layout: avatar [A] and logout are on the top right side',
      (tester) async {
        await tester.pumpWidget(
          _buildHeaderTestApp(user: MockAuthTestFixtures.admin),
        );
        await tester.pumpAndSettle();

        final headerBox = find.byType(CrmAppHeader);
        final headerLeft = tester.getTopLeft(headerBox).dx;
        final headerRight = tester.getTopRight(headerBox).dx;
        final headerCenter = (headerLeft + headerRight) / 2;

        // Display name appears
        expect(find.text('Administrator'), findsOneWidget);

        // Avatar with initial 'A'
        final avatarFinder = find.byKey(const Key('home_account_avatar'));
        expect(avatarFinder, findsOneWidget);
        expect(find.text('A'), findsOneWidget);

        // Avatar is on the right half of the header
        final avatarLeft = tester.getTopLeft(avatarFinder).dx;
        expect(avatarLeft, greaterThan(headerCenter));

        // Logout is also on the far right
        final logoutButton = find.byKey(const Key('crm_header_logout_button'));
        expect(logoutButton, findsOneWidget);
        expect(find.byTooltip('Logout'), findsOneWidget);

        final logoutRight = tester.getTopRight(logoutButton).dx;
        expect(logoutRight, greaterThan(headerRight - 60.0));
      },
    );

    testWidgets(
      'tapping account avatar opens AccountProfileDialog with uneditable User ID, name edit, password reset, and logout',
      (tester) async {
        bool loggedOut = false;
        await tester.pumpWidget(
          _buildHeaderTestApp(
            user: MockAuthTestFixtures.admin,
            onLogout: () {
              loggedOut = true;
            },
          ),
        );
        await tester.pumpAndSettle();

        // Tap the account avatar
        await tester.tap(find.byKey(const Key('home_account_avatar')));
        await tester.pumpAndSettle();

        // Account Profile dialog is open
        expect(find.byKey(const Key('home_account_dialog')), findsOneWidget);

        // User ID is displayed and uneditable
        final userIdFieldFinder = find.byKey(const Key('account_user_id_field'));
        expect(userIdFieldFinder, findsOneWidget);
        final textField = tester.widget<TextField>(userIdFieldFinder);
        expect(textField.enabled, isFalse);
        expect(textField.readOnly, isTrue);
        expect(find.text('User ID cannot be changed'), findsOneWidget);

        // Display Name is editable
        expect(find.byKey(const Key('account_display_name_field')), findsOneWidget);

        // Password reset button is available
        expect(find.byKey(const Key('account_reset_password_button')), findsOneWidget);

        // Tap dialog logout button
        await tester.ensureVisible(find.byKey(const Key('account_logout_button')));
        await tester.tap(find.byKey(const Key('account_logout_button')));
        await tester.pumpAndSettle();

        expect(loggedOut, isTrue);
        expect(find.byKey(const Key('home_account_dialog')), findsNothing);
      },
    );

    testWidgets('tapping header logout triggers onLogout callback', (
      tester,
    ) async {
      bool loggedOut = false;
      await tester.pumpWidget(
        _buildHeaderTestApp(
          user: MockAuthTestFixtures.admin,
          onLogout: () {
            loggedOut = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('crm_header_logout_button')));
      await tester.pumpAndSettle();

      expect(loggedOut, isTrue);
    });

    testWidgets(
      'mobile narrow viewport (< 420px) shows avatar and logout on right without overflow',
      (tester) async {
        const mobileWidth = 360.0;
        await tester.pumpWidget(
          _buildHeaderTestApp(
            user: MockAuthTestFixtures.admin,
            width: mobileWidth,
          ),
        );
        await tester.pumpAndSettle();

        final headerBox = find.byType(CrmAppHeader);
        final headerRight = tester.getTopRight(headerBox).dx;

        expect(find.text('Administrator'), findsNothing);
        expect(find.byKey(const Key('home_account_avatar')), findsOneWidget);

        final logoutRight = tester
            .getTopRight(find.byKey(const Key('crm_header_logout_button')))
            .dx;
        expect(logoutRight, greaterThan(headerRight - 60.0));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('renders cleanly in dark mode', (tester) async {
      await tester.pumpWidget(
        _buildHeaderTestApp(
          user: MockAuthTestFixtures.admin,
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Administrator'), findsOneWidget);
      expect(find.byKey(const Key('home_account_avatar')), findsOneWidget);
      expect(find.byKey(const Key('crm_header_logout_button')), findsOneWidget);
    });
  });
}
