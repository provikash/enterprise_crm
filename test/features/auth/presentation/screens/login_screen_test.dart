import 'package:enterprise_crm/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/login_screen.dart';
import 'package:enterprise_crm/features/user_management/data/mock/mock_account_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildLoginTestApp({
  required AuthCubit cubit,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
    themeMode: themeMode,
    home: BlocProvider<AuthCubit>.value(
      value: cubit,
      child: const LoginScreen(),
    ),
  );
}

void main() {
  group('LoginScreen Widget Tests', () {
    late MockAccountStore accountStore;
    late MockAuthRepository repository;
    late AuthCubit cubit;

    setUp(() {
      accountStore = MockAccountStore.seeded();
      repository = MockAuthRepository(accountStore: accountStore);
      cubit = AuthCubit(repository);
    });

    tearDown(() {
      cubit.close();
    });

    testWidgets('renders all expected login elements and branding', (
      tester,
    ) async {
      await tester.pumpWidget(_buildLoginTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.text('Vinay Enterprise CRM'), findsOneWidget);
      expect(
        find.text('Sign in to access your business workspace'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('login_user_id_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(
        find.byKey(const Key('login_password_visibility_toggle')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('login_forgot_password_button')), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.text('LOGIN'), findsOneWidget);

      // Explicit absence of unneeded auth features
      expect(find.text('Sign Up'), findsNothing);
      expect(find.text('Create Account'), findsNothing);
      expect(find.text('Google'), findsNothing);
    });

    testWidgets('password visibility toggle works', (tester) async {
      await tester.pumpWidget(_buildLoginTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      final passwordFieldFinder = find.byKey(const Key('login_password_field'));
      final toggleFinder = find.byKey(
        const Key('login_password_visibility_toggle'),
      );

      // Initially obscured
      TextField textField = tester.widget<TextField>(
        find.descendant(
          of: passwordFieldFinder,
          matching: find.byType(TextField),
        ),
      );
      expect(textField.obscureText, isTrue);

      // Tap toggle to show password
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      textField = tester.widget<TextField>(
        find.descendant(
          of: passwordFieldFinder,
          matching: find.byType(TextField),
        ),
      );
      expect(textField.obscureText, isFalse);

      // Tap toggle again to re-obscure
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      textField = tester.widget<TextField>(
        find.descendant(
          of: passwordFieldFinder,
          matching: find.byType(TextField),
        ),
      );
      expect(textField.obscureText, isTrue);
    });

    testWidgets('empty fields show validation error messages', (tester) async {
      await tester.pumpWidget(_buildLoginTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      // Tap LOGIN with empty inputs
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('User ID is required.'), findsOneWidget);
      expect(find.text('Password is required.'), findsOneWidget);
      expect(repository.currentUser, isNull);
    });

    testWidgets('invalid credentials display user-safe error message', (
      tester,
    ) async {
      await tester.pumpWidget(_buildLoginTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('login_user_id_field')),
        'admin',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'wrongpassword',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_error_banner')), findsOneWidget);
      expect(find.text('Invalid User ID or password.'), findsOneWidget);

      // User ID text remains preserved
      expect(find.text('admin'), findsOneWidget);
    });

    testWidgets('busy state disables inputs and button, showing progress', (
      tester,
    ) async {
      final slowRepo = _DelayedMockAuthRepository();
      final slowCubit = AuthCubit(slowRepo);

      await tester.pumpWidget(_buildLoginTestApp(cubit: slowCubit));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('login_user_id_field')),
        'admin',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'admin123',
      );

      // Tap login button
      await tester.tap(find.byKey(const Key('login_submit_button')));
      // Pump once to enter authenticating state without finishing future
      await tester.pump();

      // Progress indicator should be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Text fields disabled
      final userIdField = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('login_user_id_field')),
          matching: find.byType(TextField),
        ),
      );
      expect(userIdField.enabled, isFalse);

      final passwordField = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('login_password_field')),
          matching: find.byType(TextField),
        ),
      );
      expect(passwordField.enabled, isFalse);

      // Finish the future
      await tester.pumpAndSettle();
      slowCubit.close();
    });

    testWidgets('renders cleanly in dark theme', (tester) async {
      await tester.pumpWidget(
        _buildLoginTestApp(cubit: cubit, themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vinay Enterprise CRM'), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
    });

    testWidgets('tapping Forgot Password? opens EmailOtpResetDialog with prefilled User ID', (
      tester,
    ) async {
      await tester.pumpWidget(_buildLoginTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      // Enter user ID on login screen
      await tester.enterText(
        find.byKey(const Key('login_user_id_field')),
        'admin',
      );
      await tester.pumpAndSettle();

      // Tap Forgot Password?
      await tester.tap(find.byKey(const Key('login_forgot_password_button')));
      await tester.pumpAndSettle();

      // Dialog opens and has 'admin' pre-filled in identifier field
      expect(find.byKey(const Key('email_otp_reset_dialog')), findsOneWidget);
      final field = tester.widget<TextFormField>(
        find.byKey(const Key('otp_identifier_field')),
      );
      expect(field.controller?.text, equals('admin'));

      // Close dialog
      await tester.tap(find.byKey(const Key('otp_close_dialog_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('email_otp_reset_dialog')), findsNothing);
    });

    testWidgets('completing reset in dialog displays success SnackBar on LoginScreen', (
      tester,
    ) async {
      await tester.pumpWidget(_buildLoginTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('login_forgot_password_button')));
      await tester.pumpAndSettle();

      // Step 1: Send Code for user
      await tester.enterText(
        find.byKey(const Key('otp_identifier_field')),
        'user',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('otp_send_code_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Step 2: Enter code "123456"
      const code = '123456';
      for (int i = 0; i < 6; i++) {
        await tester.enterText(find.byKey(Key('otp_digit_$i')), code[i]);
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byKey(const Key('otp_verify_code_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Step 3: Enter new password
      await tester.enterText(
        find.byKey(const Key('otp_new_password_field')),
        'UpdatedPass123!',
      );
      await tester.enterText(
        find.byKey(const Key('otp_confirm_password_field')),
        'UpdatedPass123!',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byKey(const Key('otp_submit_new_password_button')));
      await tester.pumpAndSettle();

      // Verify LoginScreen is back and shows the green success snackbar
      expect(find.byKey(const Key('email_otp_reset_dialog')), findsNothing);
      expect(
        find.byKey(const Key('login_password_reset_success_snackbar')),
        findsOneWidget,
      );
      expect(find.text('Password updated successfully! Please sign in with your new password.'), findsOneWidget);

      // Verify login user ID field is updated
      final idField = tester.widget<TextFormField>(
        find.byKey(const Key('login_user_id_field')),
      );
      expect(idField.controller?.text, equals('user'));
    });
  });
}

class _DelayedMockAuthRepository extends MockAuthRepository {
  _DelayedMockAuthRepository() : super(accountStore: MockAccountStore.seeded());

  @override
  Future<CurrentUser> login({
    required String userId,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return super.login(userId: userId, password: password);
  }
}
