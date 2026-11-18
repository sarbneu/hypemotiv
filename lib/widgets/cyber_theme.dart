/// HypeMotiv cyberpunk design system: palette, theme and reusable widgets.
library;

import 'package:flutter/material.dart';

/// Neon-on-near-black design tokens shared by every HypeMotiv screen.
class CyberTheme {
  CyberTheme._();

  static Color get bg => const Color(0xFF050708);
  static Color get panel => const Color(0xFF0A0F0D);
  static Color get panelAlt => const Color(0xFF111A15);
  static Color get lime => const Color(0xFFB6FF3B);
  static Color get cyan => const Color(0xFF00E5FF);
  static Color get danger => const Color(0xFFFF2E88);
  static Color get muted => const Color(0xFF7C8C82);
  static Color get white => const Color(0xFFF4F8F3);
  static Color get line => const Color(0xFF1E2A22);

  /// Dark, monospace-flavoured theme with a lime primary colour.
  static ThemeData themeData() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      cardColor: panel,
      dividerColor: line,
      colorScheme: ColorScheme.dark(
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
        fillColor: panelAlt,
        hintStyle: TextStyle(
          color: muted,
          fontSize: 12,
          letterSpacing: 0.8,
          fontFamily: 'monospace',
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF7C8C82),
          fontSize: 11,
          letterSpacing: 1.2,
          fontFamily: 'monospace',
        ),
        border: _inputBorder(line),
        enabledBorder: _inputBorder(line),
        focusedBorder: _inputBorder(lime),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color),
    );
  }

  static TextTheme _textTheme() {
    const String family = 'monospace';
    return const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: family,
        color: Color(0xFFF4F8F3),
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
      headlineMedium: TextStyle(
        fontFamily: family,
        color: Color(0xFFF4F8F3),
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
      titleLarge: TextStyle(
        fontFamily: family,
        color: Color(0xFFF4F8F3),
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
      titleMedium: TextStyle(
        fontFamily: family,
        color: Color(0xFFF4F8F3),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
      bodyLarge: TextStyle(fontFamily: family, color: Color(0xFFF4F8F3)),
      bodyMedium: TextStyle(fontFamily: family, color: Color(0xFFF4F8F3)),
      bodySmall: TextStyle(fontFamily: family, color: Color(0xFF7C8C82)),
      labelLarge: TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// Small uppercase monospace label used throughout the UI.
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
        fontFamily: 'monospace',
        color: color ?? CyberTheme.white,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
      ),
    );
  }
}

/// HYPEMOTIV wordmark plus a live status line and optional trailing microtext.
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
                'HYPEMOTIV',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFFB6FF3B),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 4),
              MicroText(
                status,
                color: statusColor ?? CyberTheme.cyan,
                fontSize: 10,
              ),
            ],
          ),
        ),
        if (trailing != null)
          MicroText(
            trailing!,
            color: CyberTheme.muted,
            fontSize: 9,
            textAlign: TextAlign.right,
          ),
      ],
    );
  }
}

/// Thin-bordered glass panel with an optional neon glow.
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
        color: CyberTheme.panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: glow ? CyberTheme.lime.withValues(alpha: 0.55) : CyberTheme.line,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: glow
                ? CyberTheme.lime.withValues(alpha: 0.14)
                : CyberTheme.bg.withValues(alpha: 0.4),
            blurRadius: glow ? 26 : 12,
            spreadRadius: glow ? 1 : 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Full-width capsule button in the cyber palette.
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
    final Color surface = primary ? CyberTheme.lime : CyberTheme.panelAlt;
    final Color foreground = primary ? CyberTheme.bg : CyberTheme.white;
    final Color border = primary ? CyberTheme.lime : CyberTheme.line;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor:
              WidgetStateProperty.all<Color>(active ? surface : CyberTheme.panel),
          foregroundColor:
              WidgetStateProperty.all<Color>(active ? foreground : CyberTheme.muted),
          elevation: WidgetStateProperty.all<double>(0),
          shadowColor: WidgetStateProperty.all<Color>(
            primary ? CyberTheme.lime.withValues(alpha: 0.22) : Colors.transparent,
          ),
          padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
            const EdgeInsets.symmetric(horizontal: 14),
          ),
          shape: WidgetStateProperty.all<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: active ? border : CyberTheme.line),
            ),
          ),
          textStyle: WidgetStateProperty.all<TextStyle>(
            TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              fontSize: fontSize,
              letterSpacing: 1.4,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 16),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label.toUpperCase(),
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

/// Lime section heading with an optional right-hand note.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 3,
          height: 12,
          color: CyberTheme.lime,
        ),
        const SizedBox(width: 8),
        MicroText(text, color: CyberTheme.lime, fontSize: 11, letterSpacing: 2),
        const Spacer(),
        if (trailing != null)
          MicroText(trailing!, color: CyberTheme.muted, fontSize: 9),
      ],
    );
  }
}

/// Small outlined status pill.
class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color chip = color ?? CyberTheme.cyan;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chip.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: chip.withValues(alpha: 0.5)),
      ),
      child: MicroText(label, color: chip, fontSize: 9, letterSpacing: 1.2),
    );
  }
}

/// Decorative waveform made of deterministic bars (no animation needed).
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
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final double slot = size.width / bars;
    for (int i = 0; i < bars; i++) {
      final double ratio = 0.15 + 0.85 * ((i * 37 % 17) / 16);
      final double barHeight = ratio * size.height;
      final double x = slot * i + slot / 2;
      canvas.drawLine(
        Offset(x, (size.height - barHeight) / 2),
        Offset(x, (size.height + barHeight) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.bars != bars;
  }
}

/// Scanline decoration meant to be dropped into a [Stack] via [Positioned.fill].
class ScanOverlay extends StatelessWidget {
  const ScanOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: _ScanPainter()),
      ),
    );
  }
}

class _ScanPainter extends CustomPainter {
  const _ScanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fine = Paint()
      ..color = CyberTheme.cyan.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), fine);
    }
    final Paint sweep = Paint()
      ..color = CyberTheme.cyan.withValues(alpha: 0.10)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      sweep,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanPainter oldDelegate) => false;
}
