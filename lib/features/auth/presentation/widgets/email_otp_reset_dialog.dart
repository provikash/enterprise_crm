import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';
import '../bloc/forgot_password_cubit.dart';
import '../bloc/forgot_password_state.dart';

/// Modal dialog providing the complete 3-step Email OTP password recovery wizard:
/// 1. Identity Input (User ID or corporate email)
/// 2. 6-Digit OTP Verification with live cooldown timer & resend
/// 3. New Password creation and confirmation
class EmailOtpResetDialog extends StatefulWidget {
  final AuthRepository? repository;
  final String initialIdentifier;

  const EmailOtpResetDialog({
    super.key,
    this.repository,
    this.initialIdentifier = '',
  });

  /// Displays the [EmailOtpResetDialog] and returns the reset user identifier on success.
  static Future<String?> show(
    BuildContext context, {
    required AuthRepository repository,
    String initialIdentifier = '',
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider(
        create: (_) => ForgotPasswordCubit(
          repository: repository,
          initialIdentifier: initialIdentifier,
        ),
        child: EmailOtpResetDialog(
          repository: repository,
          initialIdentifier: initialIdentifier,
        ),
      ),
    );
  }

  @override
  State<EmailOtpResetDialog> createState() => _EmailOtpResetDialogState();
}

class _EmailOtpResetDialogState extends State<EmailOtpResetDialog> {
  // Step 1 controller
  late final TextEditingController _identifierController;

  // Step 2 controllers for 6 digit boxes
  late final List<TextEditingController> _digitControllers;
  late final List<FocusNode> _digitFocusNodes;

  // Step 3 controllers
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    final cubitState = context.read<ForgotPasswordCubit>().state;
    final initial = widget.initialIdentifier.isNotEmpty
        ? widget.initialIdentifier
        : (cubitState is ForgotPasswordIdentifyState
            ? cubitState.identifier
            : '');
    _identifierController = TextEditingController(text: initial);
    _digitControllers = List.generate(6, (_) => TextEditingController());
    _digitFocusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    _identifierController.dispose();
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _digitFocusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _syncOtpDigitsToCubit() {
    final code = _digitControllers.map((c) => c.text).join();
    context.read<ForgotPasswordCubit>().updateOtpCode(code);
  }

  void _handleDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Handles pasting a multi-digit code (e.g. "123456")
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < 6; i++) {
        if (i < digits.length) {
          _digitControllers[i].text = digits[i];
        }
      }
      final nextIndex = digits.length < 6 ? digits.length : 5;
      _digitFocusNodes[nextIndex].requestFocus();
      _syncOtpDigitsToCubit();
      return;
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        _digitFocusNodes[index + 1].requestFocus();
      } else {
        _digitFocusNodes[index].unfocus();
      }
    }
    _syncOtpDigitsToCubit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
      listener: (context, state) {
        if (state is ForgotPasswordSuccessState) {
          Navigator.of(context).pop(state.identifier);
        } else if (state is ForgotPasswordIdentifyState) {
          if (_identifierController.text != state.identifier &&
              state.identifier.isNotEmpty) {
            _identifierController.text = state.identifier;
          }
        } else if (state is ForgotPasswordVerifyOtpState &&
            _digitControllers.every((c) => c.text.isEmpty) &&
            state.otpCode.isNotEmpty &&
            state.otpCode.length == 6) {
          // Pre-populate digit boxes if cubit already holds otp code
          for (int i = 0; i < 6; i++) {
            _digitControllers[i].text = state.otpCode[i];
          }
        }
      },
      builder: (context, state) {
        final currentStep = _resolveStepIndex(state);

        return Dialog(
          key: const Key('email_otp_reset_dialog'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: colorScheme.surface,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Top Bar
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_reset_rounded,
                          size: 22,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Recovery',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Email OTP Verification',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('otp_close_dialog_button'),
                        icon: const Icon(Icons.close, size: 20),
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3-Step Progress Indicator
                  _buildStepTracker(context, currentStep),
                  const SizedBox(height: 16),

                  // Error Banner (if present)
                  if (_extractErrorMessage(state) != null) ...[
                    Container(
                      key: const Key('otp_error_banner'),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 18,
                            color: colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _extractErrorMessage(state)!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Dynamic Step Content
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildStepContent(context, state),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int _resolveStepIndex(ForgotPasswordState state) {
    return switch (state) {
      ForgotPasswordIdentifyState() => 1,
      ForgotPasswordVerifyOtpState() => 2,
      ForgotPasswordSetNewPasswordState() => 3,
      ForgotPasswordSuccessState() => 3,
    };
  }

  String? _extractErrorMessage(ForgotPasswordState state) {
    return switch (state) {
      ForgotPasswordIdentifyState(:final errorMessage) => errorMessage,
      ForgotPasswordVerifyOtpState(:final errorMessage) => errorMessage,
      ForgotPasswordSetNewPasswordState(:final errorMessage) => errorMessage,
      ForgotPasswordSuccessState() => null,
    };
  }

  Widget _buildStepTracker(BuildContext context, int currentStep) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget buildPill(int step, String label) {
      final isDone = currentStep > step;
      final isActive = currentStep == step;

      final bg = isActive
          ? colorScheme.primaryContainer
          : (isDone
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surfaceContainerLow);
      final fg = isActive
          ? colorScheme.onPrimaryContainer
          : (isDone ? colorScheme.primary : colorScheme.onSurfaceVariant);

      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? colorScheme.primary.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isDone)
                Icon(Icons.check_circle_rounded, size: 14, color: fg)
              else
                CircleAvatar(
                  radius: 7,
                  backgroundColor: fg.withValues(alpha: 0.2),
                  child: Text(
                    '$step',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: fg,
                    ),
                  ),
                ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        buildPill(1, 'Account'),
        const SizedBox(width: 6),
        buildPill(2, 'Verify OTP'),
        const SizedBox(width: 6),
        buildPill(3, 'Password'),
      ],
    );
  }

  Widget _buildStepContent(BuildContext context, ForgotPasswordState state) {
    return switch (state) {
      ForgotPasswordIdentifyState() => _buildIdentifyStep(context, state),
      ForgotPasswordVerifyOtpState() => _buildVerifyOtpStep(context, state),
      ForgotPasswordSetNewPasswordState() =>
        _buildSetNewPasswordStep(context, state),
      ForgotPasswordSuccessState() => const SizedBox.shrink(),
    };
  }

  // ---------------------------------------------------------------------------
  // STEP 1: Account Identifier
  // ---------------------------------------------------------------------------
  Widget _buildIdentifyStep(
    BuildContext context,
    ForgotPasswordIdentifyState state,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cubit = context.read<ForgotPasswordCubit>();

    return Column(
      key: const Key('otp_step_1_container'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter your registered User ID or corporate email address to receive a single-use verification code.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const Key('otp_identifier_field'),
          controller: _identifierController,
          enabled: !state.isSubmitting,
          decoration: const InputDecoration(
            labelText: 'User ID or Corporate Email',
            hintText: 'e.g., admin or admin@enterprise-crm.internal',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onChanged: cubit.updateIdentifier,
          onFieldSubmitted: (_) => cubit.sendOtp(),
        ),
        const SizedBox(height: 8),
        Text(
          'A 6-digit OTP code will be dispatched to your corporate inbox.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              key: const Key('otp_cancel_button'),
              onPressed:
                  state.isSubmitting ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              key: const Key('otp_send_code_button'),
              onPressed: state.isSubmitting ? null : cubit.sendOtp,
              icon: state.isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Send Code'),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: 6-Digit OTP Verification
  // ---------------------------------------------------------------------------
  Widget _buildVerifyOtpStep(
    BuildContext context,
    ForgotPasswordVerifyOtpState state,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cubit = context.read<ForgotPasswordCubit>();

    return Column(
      key: const Key('otp_step_2_container'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Verification Code Sent',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'We dispatched a 6-digit code to ${state.maskedEmail}. It expires in 5 minutes.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (state.debugOtpCode != null) ...[
          const SizedBox(height: 8),
          Container(
            key: const Key('otp_demo_badge'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb_outline, size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Demo Verification Code: ${state.debugOtpCode}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),

        // 6-Box OTP Code Input
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 44,
              height: 52,
              child: TextFormField(
                key: Key('otp_digit_$index'),
                controller: _digitControllers[index],
                focusNode: _digitFocusNodes[index],
                enabled: !state.isSubmitting,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6), // permits paste
                ],
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                ),
                onChanged: (val) => _handleDigitChanged(index, val),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),

        // Cooldown timer & Resend button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              key: const Key('otp_change_account_button'),
              onPressed: state.isSubmitting ? null : cubit.goToIdentifyStep,
              icon: const Icon(Icons.arrow_back, size: 14),
              label: const Text('Change ID'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
            if (state.canResend)
              TextButton.icon(
                key: const Key('otp_resend_button'),
                onPressed: cubit.resendOtp,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Resend Code'),
              )
            else
              Text(
                'Resend in ${state.cooldownSecondsRemaining}s',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Verify button
        FilledButton.icon(
          key: const Key('otp_verify_code_button'),
          onPressed: state.isSubmitting
              ? null
              : () {
                  _syncOtpDigitsToCubit();
                  cubit.verifyOtp();
                },
          icon: state.isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.verified_user_outlined, size: 18),
          label: const Text('Verify Code'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: Set New Password
  // ---------------------------------------------------------------------------
  Widget _buildSetNewPasswordStep(
    BuildContext context,
    ForgotPasswordSetNewPasswordState state,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cubit = context.read<ForgotPasswordCubit>();

    return Column(
      key: const Key('otp_step_3_container'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Set New Password',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Create a new password for @${state.identifier}. Minimum 6 characters.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // New Password
        TextFormField(
          key: const Key('otp_new_password_field'),
          controller: _newPasswordController,
          enabled: !state.isSubmitting,
          obscureText: _obscureNewPassword,
          decoration: InputDecoration(
            labelText: 'New Password',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              key: const Key('otp_new_password_visibility_toggle'),
              icon: Icon(
                _obscureNewPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscureNewPassword = !_obscureNewPassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Confirm Password
        TextFormField(
          key: const Key('otp_confirm_password_field'),
          controller: _confirmPasswordController,
          enabled: !state.isSubmitting,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_reset_outlined),
            suffixIcon: IconButton(
              key: const Key('otp_confirm_password_visibility_toggle'),
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
          onFieldSubmitted: (_) => cubit.completeReset(
            newPassword: _newPasswordController.text,
            confirmPassword: _confirmPasswordController.text,
          ),
        ),
        const SizedBox(height: 22),

        // Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              key: const Key('otp_new_password_cancel_button'),
              onPressed:
                  state.isSubmitting ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              key: const Key('otp_submit_new_password_button'),
              onPressed: state.isSubmitting
                  ? null
                  : () => cubit.completeReset(
                      newPassword: _newPasswordController.text,
                      confirmPassword: _confirmPasswordController.text,
                    ),
              icon: state.isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Reset Password'),
            ),
          ],
        ),
      ],
    );
  }
}
