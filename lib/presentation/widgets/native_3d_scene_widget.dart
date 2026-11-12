import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pure Native Flutter 3D Interactive Scene Painter
/// Renders 3D perspective geometry, glowing PBR light orbits, particle swarms,
/// and time-shift rifts natively on Flutter Canvas without WebView!
class Native3DScenePainter extends CustomPainter {
  final double animationValue;
  final String storyId;
  final String timeState; // "2088" or "2140" for Chrono-Core
  final Offset touchPosition;

  Native3DScenePainter({
    required this.animationValue,
    required this.storyId,
    this.timeState = '2140',
    this.touchPosition = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.4);
    final radius = math.min(size.width, size.height) * 0.35;

    // Background Atmospheric Gradient
    final isChronoPast = timeState == '2088';
    Color bgDark = const Color(0xFF050B14);
    Color bgLight = const Color(0xFF0D1B2A);
    Color coreGlowColor = const Color(0xFF00E5FF);

    if (storyId == 'chrono_core') {
      bgDark = isChronoPast ? const Color(0xFF030E1E) : const Color(0xFF1E0303);
      bgLight = isChronoPast ? const Color(0xFF0A2540) : const Color(0xFF380808);
      coreGlowColor = isChronoPast ? const Color(0xFF00E5FF) : const Color(0xFFFF3300);
    } else if (storyId == 'abyssal_archive') {
      bgDark = const Color(0xFF0C0704);
      bgLight = const Color(0xFF24140B);
      coreGlowColor = const Color(0xFFFF9900);
    } else if (storyId == 'neon_phantom') {
      bgDark = const Color(0xFF050012);
      bgLight = const Color(0xFF16032B);
      coreGlowColor = const Color(0xFFFF007F);
    } else if (storyId == 'last_beacon') {
      bgDark = const Color(0xFF020B18);
      bgLight = const Color(0xFF0A2239);
      coreGlowColor = const Color(0xFF66EEFF);
    } else if (storyId == 'valkyrie_down') {
      bgDark = const Color(0xFF011208);
      bgLight = const Color(0xFF062C16);
      coreGlowColor = const Color(0xFF00FF88);
    }

    final bgGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [bgLight, bgDark],
    );

    final bgPaint = Paint()..shader = bgGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 1. Draw Volumetric Core Halo Glow
    final glowPaint = Paint()
      ..color = coreGlowColor.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    canvas.drawCircle(center, radius * 0.8, glowPaint);

    // 2. Draw 3D Rotating Rings (Perspective Projected Torus)
    final ringPaint = Paint()
      ..color = coreGlowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    final numRings = 3;
    for (int r = 0; r < numRings; r++) {
      final angle = animationValue * 2 * math.pi + (r * math.pi / 3);
      final tiltX = math.sin(angle) * 35;
      final tiltY = math.cos(angle * 0.7) * radius * 0.6;

      final path = Path();
      final points = 60;
      for (int i = 0; i <= points; i++) {
        final theta = (i / points) * 2 * math.pi;
        final x = center.dx + (radius * (0.6 + r * 0.25)) * math.cos(theta);
        final y = center.dy + tiltY * math.sin(theta) + math.sin(theta + angle) * tiltX;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, ringPaint);
    }

    // 3. Draw 3D Particle Swarm
    final particlePaint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42);
    final particleCount = 70;

    for (int i = 0; i < particleCount; i++) {
      final speed = 0.5 + random.nextDouble();
      final pAngle = (animationValue * speed * 2 * math.pi) + (i * 0.1);
      final pDist = (random.nextDouble() * 0.8 + 0.2) * radius;

      final pX = center.dx + math.cos(pAngle) * pDist;
      final pY = center.dy + math.sin(pAngle * 1.3) * (pDist * 0.6);
      final pSize = random.nextDouble() * 3.5 + 1.5;
      final pOpacity = (math.sin(pAngle * 2) * 0.4 + 0.6).clamp(0.1, 1.0);

      particlePaint.color = coreGlowColor.withValues(alpha: pOpacity);
      canvas.drawCircle(Offset(pX, pY), pSize, particlePaint);
    }

    // 4. Interactive Touch Ripple Effect
    if (touchPosition != Offset.zero) {
      final touchPaint = Paint()
        ..color = coreGlowColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(touchPosition, (animationValue % 0.5) * 100, touchPaint);
    }
  }

  @override
  bool shouldRepaint(covariant Native3DScenePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.storyId != storyId ||
        oldDelegate.timeState != timeState ||
        oldDelegate.touchPosition != touchPosition;
  }
}

/// Pure Native Flutter 3D Interactive Canvas Widget
class Native3DSceneWidget extends StatefulWidget {
  final String storyId;
  final String timeState;

  const Native3DSceneWidget({
    super.key,
    required this.storyId,
    this.timeState = '2140',
  });

  @override
  State<Native3DSceneWidget> createState() => _Native3DSceneWidgetState();
}

class _Native3DSceneWidgetState extends State<Native3DSceneWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _touchPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        setState(() {
          _touchPosition = details.localPosition;
        });
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: Native3DScenePainter(
              animationValue: _controller.value,
              storyId: widget.storyId,
              timeState: widget.timeState,
              touchPosition: _touchPosition,
            ),
          );
        },
      ),
    );
  }
}
