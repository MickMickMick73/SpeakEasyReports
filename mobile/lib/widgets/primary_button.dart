import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum PrimaryButtonVariant { primary, secondary, success, danger }

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = PrimaryButtonVariant.primary,
    @Deprecated('Use variant instead') this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PrimaryButtonVariant variant;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    Color bg;
    Color fg;
    BorderSide? border;

    if (color != null) {
      bg = color!;
      fg = p.onPrimary;
    } else {
      switch (variant) {
        case PrimaryButtonVariant.primary:
          bg = p.primary;
          fg = p.onPrimary;
        case PrimaryButtonVariant.secondary:
          bg = p.buttonSecondaryBg;
          fg = p.buttonSecondaryText;
          border = BorderSide(color: p.buttonSecondaryBorder, width: 2);
        case PrimaryButtonVariant.success:
          bg = p.success;
          fg = p.onPrimary;
        case PrimaryButtonVariant.danger:
          bg = p.danger;
          fg = p.onPrimary;
      }
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: border,
          elevation: variant == PrimaryButtonVariant.secondary ? 0 : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, color: fg), const SizedBox(width: 10)],
            Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}