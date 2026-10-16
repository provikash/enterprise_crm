import 'dart:async';

import 'package:flutter/material.dart';

class MaskedField extends StatefulWidget {
  final String label;
  final String? value;
  final bool canReveal;
  final Duration revealDuration;
  final Future<bool> Function()? onRevealRequested;

  const MaskedField({
    super.key,
    required this.label,
    required this.value,
    required this.canReveal,
    this.revealDuration = const Duration(seconds: 30),
    this.onRevealRequested,
  });

  @override
  State<MaskedField> createState() => _MaskedFieldState();
}

class _MaskedFieldState extends State<MaskedField> {
  bool _revealed = false;
  bool _authorizing = false;
  Timer? _timer;

  @override
  void didUpdateWidget(covariant MaskedField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.canReveal || widget.value != oldWidget.value) _mask();
  }

  @override
  void deactivate() {
    _mask(notify: false);
    super.deactivate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_revealed) {
      _mask();
      return;
    }
    if (!widget.canReveal || widget.value == null || _authorizing) return;
    setState(() => _authorizing = true);
    final allowed = await widget.onRevealRequested?.call() ?? true;
    if (!mounted) return;
    setState(() {
      _authorizing = false;
      _revealed = allowed;
    });
    if (allowed) {
      _timer?.cancel();
      _timer = Timer(widget.revealDuration, _mask);
    }
  }

  void _mask({bool notify = true}) {
    _timer?.cancel();
    if (!_revealed) return;
    if (notify && mounted) {
      setState(() => _revealed = false);
    } else {
      _revealed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final display = value == null
        ? 'Not available'
        : _revealed
        ? value
        : '••••••••';
    return Semantics(
      label: '${widget.label}: ${_revealed ? display : 'hidden'}',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(widget.label),
        subtitle: Text(display),
        trailing: value == null || !widget.canReveal
            ? null
            : IconButton(
                tooltip: _revealed
                    ? 'Hide ${widget.label}'
                    : 'Reveal ${widget.label}',
                onPressed: _authorizing ? null : _toggle,
                icon: _authorizing
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_revealed ? Icons.visibility_off : Icons.visibility),
              ),
      ),
    );
  }
}
