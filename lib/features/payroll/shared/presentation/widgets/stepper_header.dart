import 'package:flutter/material.dart';

class StepperHeader extends StatelessWidget {
  final List<String> steps;
  final int currentIndex;

  const StepperHeader({
    super.key,
    required this.steps,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label:
          'Step ${currentIndex + 1} of ${steps.length}: ${steps[currentIndex]}',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < steps.length; index++) ...[
              _Step(
                label: steps[index],
                completed: index < currentIndex,
                current: index == currentIndex,
              ),
              if (index < steps.length - 1)
                Container(
                  width: 32,
                  height: 2,
                  color: index < currentIndex
                      ? scheme.primary
                      : scheme.outlineVariant,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String label;
  final bool completed;
  final bool current;

  const _Step({
    required this.label,
    required this.completed,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = completed || current;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: active
              ? scheme.primary
              : scheme.surfaceContainerHighest,
          foregroundColor: active ? scheme.onPrimary : scheme.onSurfaceVariant,
          child: completed
              ? const Icon(Icons.check, size: 17)
              : Text(current ? '•' : ''),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: current ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
}
