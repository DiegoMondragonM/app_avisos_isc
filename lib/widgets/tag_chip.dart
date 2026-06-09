import 'package:flutter/material.dart';
import '../models/tag.dart';

class TagChip extends StatelessWidget {
  final Tag tag;
  final bool selected;
  final VoidCallback? onTap;
  final bool small;

  const TagChip({
    super.key,
    required this.tag,
    this.selected = false,
    this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 14,
          vertical: small ? 4 : 8,
        ),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: selected ? cs.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          tag.nombre,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: small ? 11 : null,
              ),
        ),
      ),
    );
  }
}
