import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// App logo: amber tile with an excavator glyph.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'JCB Works logo',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(size * .28),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: .35),
              blurRadius: size * .3,
              offset: Offset(0, size * .1),
            ),
          ],
        ),
        child: Icon(
          Icons.construction_rounded,
          size: size * .55,
          color: AppPalette.graphite,
        ),
      ),
    );
  }
}
