library;

import 'package:flutter/material.dart';

class CyberTheme {
  CyberTheme._();

  static Color get bg => const Color(0xFFF7F8FA);
  static Color get panel => const Color(0xFFFFFFFF);
  static Color get panelAlt => const Color(0xFFF2F4F7);
  static Color get lime => const Color(0xFF3D5AFE);
  static Color get cyan => const Color(0xFF0F766E);
  static Color get danger => const Color(0xFFF04438);
  static Color get muted => const Color(0xFF667085);
  static Color get white => const Color(0xFF1F2933);
  static Color get line => const Color(0xFFE4E7EC);

  static ThemeData themeData() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      cardColor: panel,
      dividerColor: line,
      colorScheme: ColorScheme.light(
        primary: lime,
        secondary: cyan,
        error: danger,
        surface: panel,
        onPrimary: bg,
        onSecondary: bg,
        onSurface: white,
        onError: bg,
      ),
      textTheme: _textTheme(),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panel,
        hintStyle: TextStyle(color: muted, fontSize: 14),
        labelStyle: TextStyle(color: muted, fontSize: 14),
        border: _inputBorder(line),
        enabledBorder: _inputBorder(line),
        focusedBorder: _inputBorder(lime),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
  }

  static TextTheme _textTheme() {
    return const TextTheme(
      headlineLarge: TextStyle(
        color: Color(0xFF1F2933),
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        color: Color(0xFF1F2933),
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: Color(0xFF1F2933),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: Color(0xFF1F2933),
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: Color(0xFF1F2933), fontSize: 16),
      bodyMedium: TextStyle(color: Color(0xFF1F2933), fontSize: 14),
      bodySmall: TextStyle(color: Color(0xFF667085), fontSize: 13),
      labelLarge: TextStyle(
        color: Color(0xFF1F2933),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class MicroText extends StatelessWidget {
  const MicroText(
    this.text, {
    super.key,
    this.color,
    this.fontSize = 10,
    this.letterSpacing = 1.6,
    this.fontWeight = FontWeight.w600,
    this.textAlign,
    this.maxLines,
  });

  final String text;
  final Color? color;
  final double fontSize;
  final double letterSpacing;
  final FontWeight fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: TextStyle(
        color: color ?? CyberTheme.white,
        fontSize: fontSize < 12 ? 12 : fontSize,
        fontWeight: fontWeight,
      ),
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    required this.status,
    this.trailing,
    this.statusColor,
  });

  final String status;
  final String? trailing;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'HypeMotiv',
                style: TextStyle(
                  color: Color(0xFF1F2933),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              MicroText(
                status,
                color: statusColor ?? CyberTheme.muted,
                fontSize: 12,
              ),
            ],
          ),
        ),
        if (trailing != null)
          MicroText(
            trailing!,
            color: CyberTheme.muted,
            fontSize: 12,
            textAlign: TextAlign.right,
          ),
      ],
    );
  }
}

class CyberCard extends StatelessWidget {
  const CyberCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.glow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: padding,
      decoration: BoxDecoration(
        color: CyberTheme.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: glow
              ? CyberTheme.lime.withValues(alpha: 0.45)
              : CyberTheme.line,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: CyberTheme.white.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class NeonButton extends StatelessWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = true,
    this.icon,
    this.height = 52,
    this.fontSize = 12,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final IconData? icon;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final bool active = onPressed != null;
    final Color surface = primary ? CyberTheme.lime : CyberTheme.panel;
    final Color foreground = primary ? CyberTheme.bg : CyberTheme.white;
    final Color border = primary ? CyberTheme.lime : CyberTheme.line;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all<Color>(
            active ? surface : CyberTheme.panelAlt,
          ),
          foregroundColor: WidgetStateProperty.all<Color>(
            active ? foreground : CyberTheme.muted,
          ),
          elevation: WidgetStateProperty.all<double>(0),
          shadowColor: WidgetStateProperty.all<Color>(Colors.transparent),
          padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
            const EdgeInsets.symmetric(horizontal: 14),
          ),
          shape: WidgetStateProperty.all<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: active ? border : CyberTheme.line),
            ),
          ),
          textStyle: WidgetStateProperty.all<TextStyle>(
            TextStyle(
              fontSize: fontSize < 13 ? 13 : fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF1F2933),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (trailing != null)
          MicroText(trailing!, color: CyberTheme.muted, fontSize: 12),
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color chip = color ?? CyberTheme.cyan;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chip.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chip.withValues(alpha: 0.25)),
      ),
      child: MicroText(label, color: chip, fontSize: 12),
    );
  }
}

class Waveform extends StatelessWidget {
  const Waveform({
    super.key,
    required this.color,
    this.bars = 40,
    this.height = 56,
  });

  final Color color;
  final int bars;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(painter: _WavePainter(color: color, bars: bars)),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({required this.color, required this.bars});

  final Color color;
  final int bars;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    final double slot = size.width / bars;
    final double barWidth = slot > 6 ? 3 : (slot * 0.5).clamp(1, 4);
    for (int i = 0; i < bars; i++) {
      final double ratio = 0.2 + 0.8 * ((i * 37 % 17) / 16);
      final double barHeight = ratio * size.height;
      final double x = slot * i + (slot - barWidth) / 2;
      final double y = (size.height - barHeight) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.bars != bars;
  }
}

class ScanOverlay extends StatelessWidget {
  const ScanOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(child: SizedBox.shrink()),
    );
  }
}
