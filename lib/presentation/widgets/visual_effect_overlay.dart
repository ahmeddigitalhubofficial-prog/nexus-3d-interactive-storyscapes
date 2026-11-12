import 'dart:math';
import 'package:flutter/material.dart';

class Particle {
  double x; // 0.0 to 1.0 (relative screen width)
  double y; // 0.0 to 1.0 (relative screen height)
  double size;
  double speedY;
  double speedX;
  double maxOpacity;
  double opacity;
  double phase; // Unique phase for oscillating movement/twinkle
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.speedX,
    required this.maxOpacity,
    required this.color,
    required this.phase,
  }) : opacity = maxOpacity;
}

class VisualEffectOverlay extends StatefulWidget {
  final Widget child;
  final String? effect; // "shake", "flash_red", or null
  final String? storyId; // Current active story/genre identifier
  final VoidCallback? onFinished;

  const VisualEffectOverlay({
    super.key,
    required this.child,
    this.effect,
    this.storyId,
    this.onFinished,
  });

  @override
  State<VisualEffectOverlay> createState() => _VisualEffectOverlayState();
}

class _VisualEffectOverlayState extends State<VisualEffectOverlay> with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  // Particle System
  AnimationController? _particleController;
  final List<Particle> _particles = [];
  final Random _random = Random();
  String _currentGenre = '';

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _flashController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _flashAnimation = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );

    _triggerEffect();
    _initParticles();
  }

  @override
  void didUpdateWidget(covariant VisualEffectOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.effect != oldWidget.effect && widget.effect != null) {
      _triggerEffect();
    }
    if (widget.storyId != oldWidget.storyId) {
      _initParticles();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _flashController.dispose();
    _particleController?.dispose();
    super.dispose();
  }

  void _triggerEffect() {
    if (widget.effect == 'shake') {
      _shakeController.forward(from: 0.0).then((_) => widget.onFinished?.call());
    } else if (widget.effect == 'flash_red') {
      _flashController.forward(from: 0.0).then((_) => widget.onFinished?.call());
    }
  }

  void _initParticles() {
    if (widget.storyId == null) {
      _currentGenre = '';
      _particles.clear();
      _particleController?.stop();
      return;
    }

    final storyId = widget.storyId!.toLowerCase();
    if (storyId.contains('horror')) {
      _currentGenre = 'horror';
    } else if (storyId.contains('history')) {
      _currentGenre = 'history';
    } else if (storyId.contains('comedy')) {
      _currentGenre = 'comedy';
    } else {
      _currentGenre = '';
      _particles.clear();
      _particleController?.stop();
      return;
    }

    _particles.clear();
    final count = _currentGenre == 'horror' ? 15 : 25;
    for (int i = 0; i < count; i++) {
      _particles.add(_createRandomParticle(startAtBottom: false));
    }

    if (_particleController == null) {
      _particleController = AnimationController(
        duration: const Duration(seconds: 10),
        vsync: this,
      )..repeat();
    } else {
      _particleController!.repeat();
    }
  }

  Particle _createRandomParticle({required bool startAtBottom}) {
    final double yVal = startAtBottom ? 1.15 : _random.nextDouble();
    final double xVal = _random.nextDouble();

    if (_currentGenre == 'horror') {
      return Particle(
        x: xVal,
        y: yVal,
        size: 25.0 + _random.nextDouble() * 30.0,
        speedY: -0.005 - _random.nextDouble() * 0.008,
        speedX: -0.003 + _random.nextDouble() * 0.006,
        maxOpacity: 0.03 + _random.nextDouble() * 0.06,
        color: _random.nextBool()
            ? const Color(0xFF4A0E0E) // Dark Blood Red Mist
            : const Color(0xFF140707), // Dark Charcoal/Black Mist
        phase: _random.nextDouble() * pi * 2,
      );
    } else if (_currentGenre == 'history') {
      return Particle(
        x: xVal,
        y: yVal,
        size: 3.0 + _random.nextDouble() * 4.5,
        speedY: -0.015 - _random.nextDouble() * 0.02,
        speedX: -0.008 + _random.nextDouble() * 0.016,
        maxOpacity: 0.2 + _random.nextDouble() * 0.4,
        color: _random.nextBool()
            ? const Color(0xFFFFD700) // Bright Gold spark
            : const Color(0xFFFF9800), // Amber spark
        phase: _random.nextDouble() * pi * 2,
      );
    } else {
      // Comedy
      return Particle(
        x: xVal,
        y: yVal,
        size: 4.5 + _random.nextDouble() * 5.0,
        speedY: -0.01 - _random.nextDouble() * 0.015,
        speedX: -0.006 + _random.nextDouble() * 0.012,
        maxOpacity: 0.25 + _random.nextDouble() * 0.45,
        color: [
          const Color(0xFFFF80AB), // Whimsical Pink
          const Color(0xFFFFE082), // Sunny Yellow
          const Color(0xFF80D8FF), // Sky Blue
          Colors.white,
        ][_random.nextInt(4)],
        phase: _random.nextDouble() * pi * 2,
      );
    }
  }

  void _tickParticles() {
    if (_particles.isEmpty) return;

    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      // Slow constant update step
      p.y += p.speedY * 0.2;
      p.x += p.speedX * 0.2 + sin(p.phase + _particleController!.value * pi * 4) * 0.0005;

      // Twinkle opacity oscillation
      p.opacity = p.maxOpacity * (0.3 + 0.7 * sin(p.phase + _particleController!.value * pi * 6).abs());

      // Recycle when drifting completely off bounds
      if (p.y < -0.25 || p.y > 1.25 || p.x < -0.25 || p.x > 1.25) {
        _particles[i] = _createRandomParticle(startAtBottom: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        double dx = 0.0;
        if (_shakeController.isAnimating) {
          double progress = _shakeController.value;
          double amp = 20.0 * (1.0 - progress);
          dx = sin(progress * pi * 10) * amp;
        }

        return Transform.translate(
          offset: Offset(dx, 0.0),
          child: Stack(
            children: [
              widget.child,
              // Optimized ambient particle overlay
              if (_currentGenre.isNotEmpty && _particleController != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _particleController!,
                      builder: (context, child) {
                        _tickParticles();
                        return CustomPaint(
                          painter: EnvironmentalParticlePainter(
                            particles: _particles,
                            genre: _currentGenre,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              // Red Flash Overlay
              AnimatedBuilder(
                animation: _flashController,
                builder: (context, child) {
                  if (_flashController.value == 0.0 || _flashController.value == 1.0) {
                    return const SizedBox.shrink();
                  }
                  return Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.red.withValues(alpha: _flashAnimation.value),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class EnvironmentalParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final String genre;

  EnvironmentalParticlePainter({
    required this.particles,
    required this.genre,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      paint.color = p.color.withValues(alpha: p.opacity);

      final center = Offset(p.x * size.width, p.y * size.height);
      final s = p.size;

      if (genre == 'horror') {
        // Render blurry dark mist circles
        canvas.drawCircle(center, s, paint);
      } else if (genre == 'history') {
        // Render diamond shape golden sparks
        final path = Path();
        path.moveTo(center.dx, center.dy - s);
        path.lineTo(center.dx + s * 0.5, center.dy);
        path.lineTo(center.dx, center.dy + s);
        path.lineTo(center.dx - s * 0.5, center.dy);
        path.close();
        canvas.drawPath(path, paint);
      } else if (genre == 'comedy') {
        // Render whimsical 4-point stars
        final path = Path();
        path.moveTo(center.dx, center.dy - s);
        path.quadraticBezierTo(center.dx, center.dy, center.dx + s, center.dy);
        path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + s);
        path.quadraticBezierTo(center.dx, center.dy, center.dx - s, center.dy);
        path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - s);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant EnvironmentalParticlePainter oldDelegate) => true;
}
