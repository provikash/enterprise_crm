import 'package:flutter/material.dart';

enum ReauthMethod { password, otp }

class ReauthRequest {
  final ReauthMethod method;
  final String credential;
  const ReauthRequest({required this.method, required this.credential});
}

class ReauthDialog extends StatefulWidget {
  final String consequence;
  const ReauthDialog({super.key, required this.consequence});

  static Future<ReauthRequest?> show(
    BuildContext context, {
    required String consequence,
  }) => showDialog<ReauthRequest>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ReauthDialog(consequence: consequence),
  );

  @override
  State<ReauthDialog> createState() => _ReauthDialogState();
}

class _ReauthDialogState extends State<ReauthDialog> {
  final _credential = TextEditingController();
  ReauthMethod _method = ReauthMethod.password;

  @override
  void dispose() {
    _credential.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Verify your identity'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.consequence),
        const SizedBox(height: 12),
        SegmentedButton<ReauthMethod>(
          segments: const [
            ButtonSegment(
              value: ReauthMethod.password,
              label: Text('Password'),
            ),
            ButtonSegment(value: ReauthMethod.otp, label: Text('OTP')),
          ],
          selected: {_method},
          onSelectionChanged: (selection) {
            setState(() {
              _method = selection.single;
              _credential.clear();
            });
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _credential,
          autofocus: true,
          obscureText: _method == ReauthMethod.password,
          keyboardType: _method == ReauthMethod.otp
              ? TextInputType.number
              : null,
          decoration: InputDecoration(
            labelText: _method == ReauthMethod.password
                ? 'Password'
                : 'One-time code',
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _credential.text.trim().isEmpty ? null : _submit,
        child: const Text('Continue'),
      ),
    ],
  );

  void _submit() {
    final value = _credential.text.trim();
    if (value.isEmpty) return;
    Navigator.pop(context, ReauthRequest(method: _method, credential: value));
  }
}
