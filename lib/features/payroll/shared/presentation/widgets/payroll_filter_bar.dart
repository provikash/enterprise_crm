import 'dart:async';

import 'package:flutter/material.dart';

class PayrollFilterBar extends StatefulWidget {
  final String initialSearch;
  final ValueChanged<String> onSearchChanged;
  final List<Widget> filters;
  final VoidCallback? onClear;
  final Duration debounce;

  const PayrollFilterBar({
    super.key,
    this.initialSearch = '',
    required this.onSearchChanged,
    this.filters = const [],
    this.onClear,
    this.debounce = const Duration(milliseconds: 400),
  });

  @override
  State<PayrollFilterBar> createState() => _PayrollFilterBarState();
}

class _PayrollFilterBarState extends State<PayrollFilterBar> {
  late final TextEditingController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialSearch);
  }

  @override
  void didUpdateWidget(covariant PayrollFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSearch != oldWidget.initialSearch &&
        widget.initialSearch != _controller.text) {
      _controller.text = widget.initialSearch;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => widget.onSearchChanged(value.trim()));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final search = TextField(
        controller: _controller,
        onChanged: _changed,
        decoration: InputDecoration(
          labelText: 'Search',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _timer?.cancel();
                    _controller.clear();
                    widget.onSearchChanged('');
                    setState(() {});
                  },
                  icon: const Icon(Icons.clear),
                ),
          border: const OutlineInputBorder(),
        ),
      );
      final children = [
        search,
        ...widget.filters,
        if (widget.onClear != null)
          TextButton.icon(
            onPressed: widget.onClear,
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('Clear filters'),
          ),
      ];
      if (constraints.maxWidth < 680) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final child in children) ...[child, const SizedBox(height: 8)],
          ],
        );
      }
      return Row(
        children: [
          Expanded(flex: 2, child: search),
          for (final child in children.skip(1)) ...[
            const SizedBox(width: 8),
            Flexible(child: child),
          ],
        ],
      );
    },
  );
}
