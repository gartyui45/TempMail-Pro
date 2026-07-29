import 'dart:math';
import 'package:flutter/material.dart';

class NeonBackground extends StatefulWidget {
  final Widget child;
  final bool slowMotion;

  const NeonBackground({
    super.key,
    required this.child,
    this.slowMotion = true,
  });

  @override
  State<NeonBackground> createState() => _NeonBackgroundState();
}

class _NeonBackgroundState extends State<NeonBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.slowMotion
          ? const Duration(seconds: 30)
          : const Duration(seconds: 8),
    )..repeat();

    for (int i = 0; i < 60; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 4 + 1,
        speedX: (_random.nextDouble() - 0.5) * 0.002,
        speedY: (_random.nextDouble() - 0.5) * 0.002,
        opacity: _random.nextDouble() * 0.5 + 0.1,
        hue: 200.0 + _random.nextDouble() * 40.0, // Azul a ciano
      ));
    }

    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF05081A),
            Color(0xFF0A0E27),
            Color(0xFF0D1B2A),
            Color(0xFF001233),
            Color(0xFF0A0E27),
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Partículas neon animadas
          CustomPaint(
            size: Size.infinite,
            painter: _NeonParticlePainter(
              particles: _particles,
              progress: _controller.value,
            ),
          ),
          // Efeito de luz pulsante no centro
          AnimatedOpacity(
            opacity: 0.3 + sin(_controller.value * pi) * 0.15,
            duration: const Duration(milliseconds: 100),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(
                    sin(_controller.value * 2 * pi) * 0.2,
                    cos(_controller.value * 2 * pi) * 0.2,
                  ),
                  colors: [
                    const Color(0xFF00D4FF).withOpacity(0.04),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          // Conteúdo
          widget.child,
        ],
      ),
    );
  }
}

class _Particle {
  double x, y;
  double size;
  double speedX, speedY;
  double opacity;
  double hue;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
    required this.hue,
  });
}

class _NeonParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _NeonParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      p.x += p.speedX;
      p.y += p.speedY;

      if (p.x > 1) p.x = 0;
      if (p.x < 0) p.x = 1;
      if (p.y > 1) p.y = 0;
      if (p.y < 0) p.y = 1;

      final color = HSLColor.fromAHSL(p.opacity, p.hue, 0.9, 0.5).toColor();

      // Brilho externo (glow)
      final glowPaint = Paint()
        ..color = color.withOpacity(p.opacity * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size * 5,
        glowPaint,
      );

      // Brilho médio
      final midPaint = Paint()
        ..color = color.withOpacity(p.opacity * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size * 2.5,
        midPaint,
      );

      // Ponto central brilhante
      final corePaint = Paint()..color = Colors.white.withOpacity(p.opacity * 0.9);

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size * 0.8,
        corePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NeonParticlePainter oldDelegate) => true;
}
