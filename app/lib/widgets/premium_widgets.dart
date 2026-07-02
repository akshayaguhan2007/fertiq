import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

// ── Glassmorphism Card ────────────────────────────────────────────────────────

class PremiumGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final BorderRadius? radius;
  final Color? tint;
  final bool dark;
  final double blur;
  final VoidCallback? onTap;

  const PremiumGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.tint,
    this.dark = false,
    this.blur = 12,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final br = radius ?? BorderRadius.circular(24);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.03),
                      ]
                    : [
                        (tint ?? Colors.white).withValues(alpha: 0.72),
                        (tint ?? Colors.white).withValues(alpha: 0.50),
                      ],
              ),
              borderRadius: br,
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.8),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (tint ?? Colors.black).withValues(alpha: dark ? 0.3 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── Gradient Text ─────────────────────────────────────────────────────────────

class GradientText extends StatelessWidget {
  final String text;
  final List<Color> colors;
  final TextStyle? style;
  final TextAlign? textAlign;

  const GradientText(
    this.text, {
    super.key,
    required this.colors,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Text(
          text,
          textAlign: textAlign,
          style: (style ?? GoogleFonts.plusJakartaSans(
            fontSize: 28, fontWeight: FontWeight.w800,
          )).copyWith(color: Colors.white),
        ),
      );
}

// ── Animated Counter ──────────────────────────────────────────────────────────

class AnimatedCounter extends StatefulWidget {
  final double target;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final Duration duration;
  final int decimals;

  const AnimatedCounter({
    super.key,
    required this.target,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.duration = const Duration(milliseconds: 1400),
    this.decimals = 0,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, _) {
          final val = _anim.value * widget.target;
          final formatted = widget.decimals > 0
              ? val.toStringAsFixed(widget.decimals)
              : val.round().toString();
          return Text(
            '${widget.prefix}$formatted${widget.suffix}',
            style: widget.style ??
                GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: kPrimary,
                ),
          );
        },
      );
}

// ── Pressable tap scale card ──────────────────────────────────────────────────

class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  double _s = 1.0;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          setState(() => _s = widget.scale);
        },
        onTapUp: (_) => setState(() => _s = 1.0),
        onTapCancel: () => setState(() => _s = 1.0),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _s,
          duration: const Duration(milliseconds: 120),
          child: widget.child,
        ),
      );
}

// ── Shimmer Box ───────────────────────────────────────────────────────────────

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? radius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E8E8),
          borderRadius: radius ?? BorderRadius.circular(12),
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: 1200.ms,
            color: Colors.white.withValues(alpha: 0.6),
          );
}

// ── Animated Progress Ring ────────────────────────────────────────────────────

class AnimatedProgressRing extends StatefulWidget {
  final double value; // 0.0 – 1.0
  final Color color;
  final double size;
  final double strokeWidth;
  final Widget? center;

  const AnimatedProgressRing({
    super.key,
    required this.value,
    required this.color,
    this.size = 100,
    this.strokeWidth = 10,
    this.center,
  });

  @override
  State<AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<AnimatedProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, _) => SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _RingPainter(
              value: _anim.value * widget.value,
              color: widget.color,
              strokeWidth: widget.strokeWidth,
            ),
            child: Center(child: widget.center),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final double strokeWidth;

  const _RingPainter({
    required this.value,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + 2 * math.pi * value,
          colors: [color.withValues(alpha: 0.6), color],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

// ── Floating Particles Background ────────────────────────────────────────────

class ParticleBackground extends StatefulWidget {
  final Color color;
  final int count;
  final Widget child;

  const ParticleBackground({
    super.key,
    required this.child,
    this.color = kPrimary,
    this.count = 35,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with TickerProviderStateMixin {
  late final List<_Particle> _particles;
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    _particles = List.generate(
      widget.count,
      (_) => _Particle(rnd),
    );
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ParticlePainter(
                particles: _particles,
                progress: _ctrl.value,
                color: widget.color,
              ),
            ),
          ),
          widget.child,
        ],
      );
}

class _Particle {
  final double x, y, size, speed, opacity;
  const _Particle._({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
  factory _Particle(math.Random rnd) => _Particle._(
        x: rnd.nextDouble(),
        y: rnd.nextDouble(),
        size: rnd.nextDouble() * 4 + 2,
        speed: rnd.nextDouble() * 0.04 + 0.01,
        opacity: rnd.nextDouble() * 0.4 + 0.1,
      );
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  const _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dy = (p.y - progress * p.speed * 5) % 1.0;
      final paint = Paint()
        ..color = color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(p.x * size.width, dy * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// ── Gradient background container ────────────────────────────────────────────

class GradientBackground extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const GradientBackground({
    super.key,
    required this.colors,
    required this.child,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: begin,
            end: end,
          ),
        ),
        child: child,
      );
}

// ── Stat chip (small metric tile) ────────────────────────────────────────────

class StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData? icon;
  final String? trend;

  const StatChip({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.icon,
    this.trend,
  });

  @override
  Widget build(BuildContext context) => TapScale(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              if (icon != null) const SizedBox(height: 10),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: kTextGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (trend != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trend!.startsWith('+')
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 12,
                      color: trend!.startsWith('+') ? kPrimary : kAccentRed,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: trend!.startsWith('+') ? kPrimary : kAccentRed,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
}
