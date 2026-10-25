import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'controller.dart';
import 'models.dart';

class UX {
  static const bg = Color(0xFF0D0F12);
  static const accent = Color(0xFF29D3FF);
  static const accent2 = Color(0xFF8A5CFF);
  static const red = Color(0xFFFF3B3B);
  static const green = Color(0xFF39FF7A);
  static const yellow = Color(0xFFFFD83B);
  static const orange = Color(0xFFFF8A2B);
}

Color op(Color c, double o) => c.withAlpha((o.clamp(0.0, 1.0) * 255).round());

Color groupColor(int g) {
  switch (g) {
    case 1:
      return const Color(0xFFFF8A2B);
    case 2:
      return const Color(0xFF3BD88A);
    case 3:
      return const Color(0xFFB05CFF);
    case 4:
      return const Color(0xFFFFD83B);
    default:
      return const Color(0xFF6C737D);
  }
}

// ---------------------------------------------------------------------------
// Baut
// ---------------------------------------------------------------------------
class Screw extends StatelessWidget {
  final double size;
  final double angle;
  const Screw({super.key, this.size = 9, this.angle = 0});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _ScrewPainter(angle)),
      );
}

class _ScrewPainter extends CustomPainter {
  final double angle;
  _ScrewPainter(this.angle);

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final r = s.width / 2;
    canvas.drawCircle(c.translate(0.6, 0.9), r, Paint()..color = const Color(0xAA000000));
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.45),
          radius: 1.0,
          colors: [Color(0xFFF4F4F4), Color(0xFF9CA1A8), Color(0xFF34373C)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(rect),
    );
    final slot = Paint()
      ..color = const Color(0xFF14161A)
      ..strokeWidth = max(1.0, r * 0.28)
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    canvas.drawLine(Offset(-r * 0.62, 0), Offset(r * 0.62, 0), slot);
    canvas.drawLine(Offset(0, -r * 0.62), Offset(0, r * 0.62), slot);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScrewPainter old) => old.angle != angle;
}

// ---------------------------------------------------------------------------
// Panel logam dengan gradasi + bevel + baut
// ---------------------------------------------------------------------------
class MetalPanel extends StatelessWidget {
  final Widget? child;
  final EdgeInsets padding;
  final double radius;
  final bool screws;
  final Color? glow;
  final List<Color>? colors;

  const MetalPanel({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(8),
    this.radius = 8,
    this.screws = false,
    this.glow,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final inner = BorderRadius.circular(max(0.0, radius - 1.5));
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9AA2AD), Color(0xFF2B3037), Color(0xFF050607)],
        ),
        boxShadow: [
          const BoxShadow(color: Color(0xAA000000), blurRadius: 6, offset: Offset(0, 3)),
          if (glow != null) BoxShadow(color: op(glow!, 0.55), blurRadius: 10),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: inner,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors ??
                const [Color(0xFF454C56), Color(0xFF2A2F36), Color(0xFF1B1F24)],
          ),
        ),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Padding(padding: padding, child: child),
            if (screws) ...const [
              Positioned(left: 4, top: 4, child: Screw(size: 8, angle: 0.5)),
              Positioned(right: 4, top: 4, child: Screw(size: 8, angle: 1.9)),
              Positioned(left: 4, bottom: 4, child: Screw(size: 8, angle: 1.1)),
              Positioned(right: 4, bottom: 4, child: Screw(size: 8, angle: 2.6)),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lampu bulat + VU meter lampu
// ---------------------------------------------------------------------------
class Led extends StatelessWidget {
  final Color color;
  final bool on;
  final double size;
  const Led({super.key, required this.color, required this.on, this.size = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 0.9,
          colors: on
              ? [Color.lerp(Colors.white, color, 0.35)!, color, op(color, 0.7)]
              : const [Color(0xFF4A4F57), Color(0xFF23262B), Color(0xFF111316)],
          stops: const [0.0, 0.4, 1.0],
        ),
        border: Border.all(color: const Color(0xFF0A0B0D), width: 1),
        boxShadow: on
            ? [BoxShadow(color: op(color, 0.75), blurRadius: size * 0.9, spreadRadius: size * 0.05)]
            : null,
      ),
    );
  }
}

class VuLamps extends StatelessWidget {
  final double level;
  const VuLamps({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final n = (box.maxHeight / 12).floor().clamp(5, 16).toInt();
      final slot = box.maxHeight / n;
      final size = min(box.maxWidth * 0.62, slot - 2.5).clamp(4.0, 16.0).toDouble();
      final lit = (clamp01(level) * n).round();
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(n, (k) {
          final idx = n - 1 - k;
          final ratio = (idx + 1) / n;
          final color = ratio > 0.85
              ? UX.red
              : (ratio > 0.65 ? UX.yellow : UX.green);
          return Led(on: idx < lit, color: color, size: size);
        }),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Fader
// ---------------------------------------------------------------------------
class Fader extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final Color accent;
  const Fader({
    super.key,
    required this.value,
    required this.onChanged,
    this.accent = UX.accent,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final h = box.maxHeight;
      final w = box.maxWidth;
      final capH = h < 140 ? 28.0 : 36.0;
      final travel = max(1.0, h - capH);
      final capW = min(w, 46.0);
      double fromDy(double dy) => clamp01(1 - (dy - capH / 2) / travel);

      return Listener(
        onPointerSignal: (e) {
          if (e is PointerScrollEvent) {
            GestureBinding.instance.pointerSignalResolver.register(e, (ev) {
              final d = e.scrollDelta.dy > 0 ? -0.03 : 0.03;
              onChanged(clamp01(value + d));
            });
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => onChanged(fromDy(d.localPosition.dy)),
          onVerticalDragStart: (d) => onChanged(fromDy(d.localPosition.dy)),
          onVerticalDragUpdate: (d) => onChanged(fromDy(d.localPosition.dy)),
          onDoubleTap: () => onChanged(0.75),
          child: SizedBox(
            width: w,
            height: h,
            child: CustomPaint(
              painter: _FaderTrackPainter(capH),
              child: Stack(
                children: [
                  Positioned(
                    top: (1 - clamp01(value)) * travel,
                    left: (w - capW) / 2,
                    width: capW,
                    height: capH,
                    child: CustomPaint(painter: _CapPainter(accent)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _FaderTrackPainter extends CustomPainter {
  final double capH;
  _FaderTrackPainter(this.capH);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final top = capH / 2;
    final bottom = size.height - capH / 2;
    final slot = RRect.fromLTRBR(cx - 3.5, top - 5, cx + 3.5, bottom + 5, const Radius.circular(3));
    canvas.drawRRect(slot, Paint()..color = const Color(0xFF040506));
    canvas.drawRRect(
      slot.deflate(1),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF000000), Color(0xFF1B1E23), Color(0xFF000000)],
        ).createShader(slot.outerRect),
    );
    final tick = Paint()
      ..color = const Color(0xAA9AA3AE)
      ..strokeWidth = 1;
    for (var i = 0; i <= 10; i++) {
      final y = bottom - (bottom - top) * i / 10;
      final long = i % 5 == 0;
      final len = long ? 7.0 : 4.0;
      canvas.drawLine(Offset(cx - 9 - len, y), Offset(cx - 9, y), tick);
      canvas.drawLine(Offset(cx + 9, y), Offset(cx + 9 + len, y), tick);
    }
  }

  @override
  bool shouldRepaint(covariant _FaderTrackPainter old) => old.capH != capH;
}

class _CapPainter extends CustomPainter {
  final Color accent;
  _CapPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4));
    canvas.drawRRect(
      rr.shift(const Offset(0, 2)),
      Paint()
        ..color = const Color(0xAA000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC3C8D0), Color(0xFF727882), Color(0xFF3A3E45), Color(0xFF5B616A)],
          stops: [0.0, 0.45, 0.55, 1.0],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF15171A),
    );
    final mid = size.height / 2;
    final dark = Paint()
      ..color = const Color(0x66000000)
      ..strokeWidth = 1;
    final light = Paint()
      ..color = const Color(0x44FFFFFF)
      ..strokeWidth = 1;
    for (var k = -2; k <= 2; k++) {
      if (k == 0) continue;
      final y = mid + k * 5.0;
      canvas.drawLine(Offset(4, y), Offset(size.width - 4, y), dark);
      canvas.drawLine(Offset(4, y + 1), Offset(size.width - 4, y + 1), light);
    }
    canvas.drawRect(
      Rect.fromCenter(center: Offset(size.width / 2, mid), width: size.width - 8, height: 3),
      Paint()..color = accent,
    );
  }

  @override
  bool shouldRepaint(covariant _CapPainter old) => old.accent != accent;
}

// ---------------------------------------------------------------------------
// Tombol hardware
// ---------------------------------------------------------------------------
class MixButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool lit;
  final Color litColor;
  final double? width;
  final double? height;
  final bool repeat;
  final bool fit;
  final double fontSize;

  const MixButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.lit = false,
    this.litColor = UX.accent,
    this.width,
    this.height,
    this.repeat = false,
    this.fit = true,
    this.fontSize = 10,
  });

  @override
  State<MixButton> createState() => _MixButtonState();
}

class _MixButtonState extends State<MixButton> {
  bool _down = false;
  Timer? _timer;

  void _start() {
    setState(() => _down = true);
    if (widget.repeat) {
      widget.onTap?.call();
      _timer = Timer(const Duration(milliseconds: 350), () {
        _timer = Timer.periodic(const Duration(milliseconds: 70), (_) => widget.onTap?.call());
      });
    }
  }

  void _end() {
    _timer?.cancel();
    _timer = null;
    if (mounted && _down) setState(() => _down = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lit = widget.lit;
    final base = widget.litColor;
    final List<Color> colors = lit
        ? [Color.lerp(base, Colors.white, 0.5)!, base, Color.lerp(base, Colors.black, 0.35)!]
        : (_down
            ? const [Color(0xFF2A2E34), Color(0xFF3A3F47)]
            : const [Color(0xFF6C737D), Color(0xFF3D424A), Color(0xFF2B2F35)]);
    final fg = lit ? const Color(0xFF05080A) : const Color(0xFFE6EAEF);
    final Widget content = widget.fit
        ? FittedBox(fit: BoxFit.scaleDown, child: widget.child)
        : widget.child;

    return GestureDetector(
      onTapDown: (_) => _start(),
      onTapUp: (_) => _end(),
      onTapCancel: _end,
      onTap: widget.repeat ? null : widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        width: widget.width,
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
          border: Border.all(color: const Color(0xFF0B0C0E), width: 1),
          boxShadow: [
            if (!_down)
              const BoxShadow(color: Color(0x99000000), offset: Offset(0, 2), blurRadius: 2),
            if (lit) BoxShadow(color: op(base, 0.6), blurRadius: 8),
          ],
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: fg,
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
          child: IconTheme(
            data: IconThemeData(color: fg, size: 20),
            child: content,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logo
// ---------------------------------------------------------------------------
class LogoMark extends StatelessWidget {
  final double size;
  const LogoMark({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: CustomPaint(painter: _LogoPainter()));
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.22));
    canvas.drawRRect(
      rr.shift(Offset(0, s * 0.03)),
      Paint()
        ..color = const Color(0x88000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.04),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF29D3FF), Color(0xFF5B6CFF), Color(0xFF8A5CFF)],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rr.deflate(s * 0.015),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.03
        ..color = const Color(0x66FFFFFF),
    );
    final slot = Paint()
      ..color = const Color(0x55000A20)
      ..strokeWidth = s * 0.07
      ..strokeCap = StrokeCap.round;
    const ys = [0.38, 0.62, 0.48];
    for (var k = 0; k < 3; k++) {
      final x = s * (0.27 + 0.23 * k);
      canvas.drawLine(Offset(x, s * 0.2), Offset(x, s * 0.8), slot);
      final cap = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, s * ys[k]), width: s * 0.17, height: s * 0.1),
        Radius.circular(s * 0.025),
      );
      canvas.drawRRect(cap.shift(Offset(0, s * 0.012)), Paint()..color = const Color(0x66000000));
      canvas.drawRRect(
        cap,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFB8C2D6)],
          ).createShader(cap.outerRect),
      );
      canvas.drawLine(
        Offset(x - s * 0.06, s * ys[k]),
        Offset(x + s * 0.06, s * ys[k]),
        Paint()
          ..color = const Color(0xFF3A4470)
          ..strokeWidth = s * 0.012,
      );
    }
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawOval(
      Rect.fromLTWH(-s * 0.2, -s * 0.55, s * 1.4, s * 0.95),
      Paint()..color = const Color(0x22FFFFFF),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class BrandTitle extends StatelessWidget {
  final double size;
  const BrandTitle({super.key, this.size = 34});

  @override
  Widget build(BuildContext context) => ShaderMask(
        shaderCallback: (r) => const LinearGradient(
          colors: [Color(0xFF7FE6FF), Color(0xFFB59BFF)],
        ).createShader(r),
        child: Text(
          'UxMix',
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// LCD
// ---------------------------------------------------------------------------
class LcdScreen extends StatelessWidget {
  final MixerController c;
  const LcdScreen({super.key, required this.c});

  static const _lcd = Color(0xFF5CF4FF);

  TextStyle _ts(double size, {bool bold = false, Color? color}) => TextStyle(
        fontFamily: 'Consolas',
        fontFamilyFallback: const ['Courier New', 'monospace'],
        fontSize: size,
        height: 1.15,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: color ?? _lcd,
      );

  Widget _bar(double v, {int n = 28}) {
    final on = (clamp01(v) * n).round();
    return Row(
      children: List.generate(
        n,
        (i) => Expanded(
          child: Container(
            height: 9,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            color: i < on ? _lcd : op(_lcd, 0.14),
          ),
        ),
      ),
    );
  }

  Widget _flag(String t, bool on) => Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: on ? _lcd : Colors.transparent,
          border: Border.all(color: op(_lcd, on ? 1 : 0.2)),
        ),
        child: Text(t, style: _ts(12, bold: true, color: on ? const Color(0xFF021014) : op(_lcd, 0.25))),
      );

  Widget _tab(String t, int idx) {
    final on = c.page == idx;
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      color: on ? _lcd : Colors.transparent,
      child: Text(t, style: _ts(11, bold: true, color: on ? const Color(0xFF021014) : op(_lcd, 0.5))),
    );
  }

  String _pct(double v) => '${(v * 100).round()}%'.padLeft(4);

  Widget _volRow(String label, double v) => Row(
        children: [
          Text('$label ', style: _ts(14, bold: true)),
          Expanded(child: _bar(v)),
          Text(_pct(v), style: _ts(14)),
        ],
      );

  Widget _body() {
    switch (c.page) {
      case 0:
        {
          final ch = c.channels[c.selected];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('CH ${(c.selected + 1).toString().padLeft(2, '0')}', style: _ts(30, bold: true)),
                  const SizedBox(width: 14),
                  Text('GRP ${kGroupLetters[ch.group]}', style: _ts(16)),
                  const Spacer(),
                  _flag('MUTE', ch.mute),
                  _flag('SOLO', ch.solo),
                ],
              ),
              Text(ch.hasTrack ? ch.file : '-- NO TRACK --',
                  style: _ts(14), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              _volRow('VOL', ch.volume),
              const SizedBox(height: 6),
              Text('${fmtMs(ch.posMs)} / ${fmtMs(ch.durMs)}', style: _ts(14)),
            ],
          );
        }
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MASTER', style: _ts(30, bold: true)),
            const SizedBox(height: 8),
            _volRow('VOL', c.master),
            const SizedBox(height: 8),
            Row(children: [Text('L   ', style: _ts(14, bold: true)), Expanded(child: _bar(c.meterL))]),
            const SizedBox(height: 4),
            Row(children: [Text('R   ', style: _ts(14, bold: true)), Expanded(child: _bar(c.meterR))]),
          ],
        );
      case 2:
        {
          final g = c.groups[c.selGroup];
          final members = [
            for (var i = 0; i < kChannels; i++)
              if (c.channels[i].group == c.selGroup + 1) i + 1
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('GROUP ${kGroupLetters[c.selGroup + 1]}', style: _ts(30, bold: true)),
                  const Spacer(),
                  _flag('MUTE', g.mute),
                ],
              ),
              const SizedBox(height: 8),
              _volRow('VOL', g.volume),
              const SizedBox(height: 6),
              Text(
                'CH: ${members.isEmpty ? '-' : members.map((e) => e.toString().padLeft(2, '0')).join(' ')}',
                style: _ts(13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        }
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SYSTEM', style: _ts(26, bold: true)),
            Text('SETTING SLOT ${c.slot}   (< > ganti slot)', style: _ts(13, bold: true)),
            const SizedBox(height: 4),
            for (final l in c.systemLines()) Text(l, style: _ts(13)),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF050607), Color(0xFF1E2227)],
        ),
        border: Border.all(color: const Color(0xFF000000)),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B3C49), Color(0xFF04202A)],
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Row(
                  children: [
                    Text('UxMix', style: _ts(12, bold: true, color: op(_lcd, 0.7))),
                    const Spacer(),
                    _tab('CH', 0),
                    _tab('MST', 1),
                    _tab('GRP', 2),
                    _tab('SYS', 3),
                    const Spacer(),
                    Text(c.playing ? 'PLAY' : 'STOP', style: _ts(12, bold: true)),
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: _body(),
                  ),
                ),
              ],
            ),
            if (c.toast.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  color: _lcd,
                  child: Text(c.toast, style: _ts(13, bold: true, color: const Color(0xFF021014))),
                ),
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [op(Colors.white, 0.08), op(Colors.white, 0.0)],
                      stops: const [0.0, 0.5],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// D-pad: atas / bawah / kiri / kanan + SELECT
// ---------------------------------------------------------------------------
class DPad extends StatelessWidget {
  final MixerController c;
  final double cell;
  const DPad({super.key, required this.c, this.cell = 48});

  Widget _b(IconData icon, String dir) => Padding(
        padding: const EdgeInsets.all(2),
        child: MixButton(
          width: cell,
          height: cell,
          repeat: true,
          onTap: () => c.send({'t': 'nav', 'd': dir}),
          child: Icon(icon, size: 26),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final sp = SizedBox(width: cell + 4, height: cell + 4);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [sp, _b(Icons.keyboard_arrow_up, 'u'), sp]),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _b(Icons.keyboard_arrow_left, 'l'),
            Padding(
              padding: const EdgeInsets.all(2),
              child: MixButton(
                width: cell,
                height: cell,
                lit: true,
                litColor: UX.accent,
                fontSize: 9,
                onTap: () => c.send({'t': 'page'}),
                child: const Text('SELECT'),
              ),
            ),
            _b(Icons.keyboard_arrow_right, 'r'),
          ],
        ),
        Row(mainAxisSize: MainAxisSize.min, children: [sp, _b(Icons.keyboard_arrow_down, 'd'), sp]),
      ],
    );
  }
}
