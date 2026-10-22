import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enterprise_crm/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:enterprise_crm/features/auth/presentation/widgets/email_otp_reset_dialog.dart';
import 'package:enterprise_crm/features/user_management/data/mock/mock_account_store.dart';

Widget _buildDialogTestApp({
  required MockAuthRepository repository,
  String initialIdentifier = '',
  void Function(String?)? onResult,
}) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(
      body: Builder(
        builder: (context) {
          return Center(
            child: ElevatedButton(
              key: const Key('open_dialog_test_button'),
              onPressed: () async {
                final result = await EmailOtpResetDialog.show(
                  context,
                  repository: repository,
                  initialIdentifier: initialIdentifier,
                );
                onResult?.call(result);
              },
              child: const Text('Open Dialog'),
            ),
          );
        },
      ),
    ),
  );
}

void main() {
  group('EmailOtpResetDialog Widget Tests (Phase 3 & 5)', () {
    late MockAccountStore store;
    late MockAuthRepository repository;

    setUp(() {
      store = MockAccountStore.seeded();
      repository = MockAuthRepository(accountStore: store);
    });

    testWidgets('renders Step 1 with identifier field, cancel and send buttons', (
      tester,
    ) async {
      await tester.pumpWidget(_buildDialogTestApp(repository: repository));
      await tester.tap(find.byKey(const Key('open_dialog_test_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('email_otp_reset_dialog')), findsOneWidget);
      expect(find.text('Account Recovery'), findsOneWidget);
      expect(find.text('Email OTP Verification'), findsOneWidget);
      expect(find.byKey(const Key('otp_identifier_field')), findsOneWidget);
      expect(find.byKey(const Key('otp_cancel_button')), findsOneWidget);
      expect(find.byKey(const Key('otp_send_code_button')), findsOneWidget);
    });

    testWidgets('shows validation error when identifier is submitted empty', (
      tester,
    ) async {
      await tester.pumpWidget(_buildDialogTestApp(repository: repository));
      await tester.tap(find.byKey(const Key('open_dialog_test_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('otp_send_code_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('otp_error_banner')), findsOneWidget);
      expect(find.text('Please enter your User ID or corporate email.'), findsOneWidget);
    });

    testWidgets('submitting valid identifier moves to Step 2 with 6 digit boxes and demo badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildDialogTestApp(repository: repository, initialIdentifier: 'admin'),
      );
      await tester.tap(find.byKey(const Key('open_dialog_test_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('otp_send_code_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('otp_step_2_container')), findsOneWidget);
      expect(find.text('Verification Code Sent'), findsOneWidget);
      expect(find.textContaining('ad***@enterprise-crm.internal'), findsOneWidget);
      expect(find.byKey(const Key('otp_demo_badge')), findsOneWidget);

      // Verify all 6 digit input boxes
      for (int i = 0; i < 6; i++) {
        expect(find.byKey(Key('otp_digit_$i')), findsOneWidget);
      }
    });

    testWidgets('tapping Change ID returns to Step 1 preserving identifier', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildDialogTestApp(repository: repository, initialIdentifier: 'admin'),
      );
      await tester.tap(find.byKey(const Key('open_dialog_test_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('otp_send_code_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('otp_change_account_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('otp_step_1_container')), findsOneWidget);
      final field = tester.widget<TextFormField>(find.byKey(const Key('otp_identifier_field')));
      expect(field.controller?.text, equals('admin'));
    });

    testWidgets('entering invalid OTP displays error banner and attempts remaining', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildDialogTestApp(repository: repository, initialIdentifier: 'admin'),
      );
      await tester.tap(find.byKey(const Key('open_dialog_test_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('otp_send_code_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Enter 6 wrong digits
      for (int i = 0; i < 6; i++) {
        await tester.enterText(find.byKey(Key('otp_digit_$i')), '9');
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byKey(const Key('otp_verify_code_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('otp_error_banner')), findsOneWidget);
      expect(find.textContaining('2 attempts remaining'), findsOneWidget);
    });

    testWidgets('end-to-end: enters OTP -> sets new password -> dialog returns identifier', (
      tester,
    ) async {
      String? returnedUserId;
      await tester.pumpWidget(
        _buildDialogTestApp(
          repository: repository,
          initialIdentifier: 'user',
          onResult: (val) => returnedUserId = val,
        ),
      );
      await tester.tap(find.byKey(const Key('open_dialog_test_button')));
      await tester.pumpAndSettle();

      // Step 1: Send Code
      await tester.tap(find.byKey(const Key('otp_send_code_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Step 2: Enter "123456"
      const code = '123456';
      for (int i = 0; i < 6; i++) {
        await tester.enterText(find.byKey(Key('otp_digit_$i')), code[i]);
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Step 2 -> Step 3: verify code cancels the cooldown timer
      await tester.tap(find.byKey(const Key('otp_verify_code_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Step 3: Enter new password and confirm
      expect(find.byKey(const Key('otp_step_3_container')), findsOneWidget);
      expect(find.text('Set New Password'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('otp_new_password_field')),
        'BrandNewPassword123!',
      );
      await tester.enterText(
        find.byKey(const Key('otp_confirm_password_field')),
        'BrandNewPassword123!',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byKey(const Key('otp_submit_new_password_button')));
      await tester.pumpAndSettle();

      // Dialog closed and returned the resolved user ID
      expect(find.byKey(const Key('email_otp_reset_dialog')), findsNothing);
      expect(returnedUserId, equals('user'));

      // Verify that user can immediately authenticate with new password
      final authenticated = await tester.runAsync(
        () => repository.login(
          userId: 'user',
          password: 'BrandNewPassword123!',
        ),
      );
      expect(authenticated?.id, equals('user'));
    });
  });
}
