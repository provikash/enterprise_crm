import 'package:flutter/material.dart';

/// A hybrid input field combining text box, search box, and dropdown list behaviors.
///
/// Features:
/// - Acts like a standard [TextFormField], allowing direct typing and arbitrary manual text.
/// - Acts like a search box: typing dynamically filters the suggestion list.
/// - Acts like a dropdown: tapping the trailing dropdown icon or tapping the field opens a scrollable menu of options.
/// - If the desired value is not available in [options], the user's manual text is accepted and preserved.
class HybridDropdownField extends StatefulWidget {
  final TextEditingController controller;
  final List<String> options;
  final String labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final TextInputAction textInputAction;
  final TextInputType keyboardType;
  final Key? fieldKey;
  final FocusNode? focusNode;
  final bool showAllOnFocus;

  const HybridDropdownField({
    super.key,
    required this.controller,
    required this.options,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.keyboardType = TextInputType.text,
    this.fieldKey,
    this.focusNode,
    this.showAllOnFocus = true,
  });

  @override
  State<HybridDropdownField> createState() => _HybridDropdownFieldState();
}

class _HybridDropdownFieldState extends State<HybridDropdownField> {
  final LayerLink _layerLink = LayerLink();
  final Object _regionGroupId = Object();
  late final FocusNode _focusNode;
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  bool _forceShowAll = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _focusNode.removeListener(_onFocusChange);
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    _isOpen = false;
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _toggleDropdown() {
    if (!widget.enabled) return;
    if (_isOpen) {
      _removeOverlay();
    } else {
      _forceShowAll = true;
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
      _showOverlay();
    }
  }

  List<String> _getFilteredOptions() {
    if (_forceShowAll) {
      return widget.options;
    }
    final query = widget.controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.options;
    }
    return widget.options
        .where((opt) => opt.toLowerCase().contains(query))
        .toList();
  }

  void _showOverlay() {
    final filtered = _getFilteredOptions();
    if (filtered.isEmpty) {
      _removeOverlay();
      return;
    }

    _removeOverlay();

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? const Size(300, 56);

    _overlayEntry = OverlayEntry(
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final currentText = widget.controller.text.trim();
        final currentOptions = _getFilteredOptions();

        if (currentOptions.isEmpty) {
          return const SizedBox.shrink();
        }

        return CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 4),
          child: TapRegion(
            groupId: _regionGroupId,
            onTapOutside: (_) => _removeOverlay(),
            child: Material(
              elevation: 4,
              color: theme.colorScheme.surface,
              surfaceTintColor: theme.colorScheme.surfaceTint,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withAlpha(120),
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 220,
                  maxWidth: size.width,
                  minWidth: size.width,
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shrinkWrap: true,
                  children: currentOptions.map((option) {
                    final isSelected =
                        option.toLowerCase() == currentText.toLowerCase();

                    return InkWell(
                      onTap: () {
                        widget.controller.text = option;
                        widget.onChanged?.call(option);
                        _removeOverlay();
                        _focusNode.unfocus();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        color: isSelected
                            ? theme.colorScheme.primaryContainer.withAlpha(80)
                            : null,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
    if (mounted) {
      setState(() {
        _isOpen = true;
      });
    }
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isOpen = false;
      if (mounted && !_isDisposed) {
        setState(() {});
      }
    }
  }

  void _updateOverlay() {
    if (_isOpen && _overlayEntry != null) {
      final filtered = _getFilteredOptions();
      if (filtered.isEmpty) {
        _removeOverlay();
      } else {
        _overlayEntry!.markNeedsBuild();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TapRegion(
        groupId: _regionGroupId,
        child: TextFormField(
          key: widget.fieldKey ?? widget.key,
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          textInputAction: widget.textInputAction,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onTap: () {
            if (!widget.enabled) return;
            _forceShowAll = true;
            _showOverlay();
          },
          onChanged: (value) {
            _forceShowAll = false;
            final trimmed = value.trim().toLowerCase();
            final isExactMatch =
                widget.options.any((o) => o.toLowerCase() == trimmed);

            if (isExactMatch) {
              _removeOverlay();
            } else {
              final matches = widget.options
                  .where((opt) => opt.toLowerCase().contains(trimmed))
                  .toList();
              if (matches.isEmpty) {
                _removeOverlay();
              } else {
                if (!_isOpen) {
                  _showOverlay();
                } else {
                  _updateOverlay();
                }
              }
            }
            widget.onChanged?.call(value);
          },
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: IconButton(
              icon: Icon(
                _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              ),
              tooltip: 'Show options',
              onPressed: widget.enabled ? _toggleDropdown : null,
            ),
            border: const OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}
