import 'package:flutter/material.dart';
import 'dart:math' as math;

class WaterGlassWidget extends StatefulWidget {
  final double currentAmount;
  final double targetAmount;
  final double width;
  final double height;
  final bool showBubbles;
  final bool goalReached;

  WaterGlassWidget({
    @required this.currentAmount,
    @required this.targetAmount,
    this.width = 160,
    this.height = 220,
    this.showBubbles = true,
    this.goalReached = false,
  });

  @override
  _WaterGlassWidgetState createState() => _WaterGlassWidgetState();
}

class _WaterGlassWidgetState extends State<WaterGlassWidget>
    with TickerProviderStateMixin {
  AnimationController _waveController;
  AnimationController _fillController;
  AnimationController _bubbleController;
  AnimationController _splashController;
  Animation<double> _fillAnimation;
  double _currentFillLevel = 0;
  double _targetFillLevel = 0;
  double _previousFillLevel = 0;
  List<_Bubble> _bubbles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _targetFillLevel = widget.currentAmount / widget.targetAmount;
    _currentFillLevel = _targetFillLevel;
    _previousFillLevel = _targetFillLevel;

    _waveController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat();

    _fillController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _bubbleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000),
    )..repeat();

    _splashController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fillAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.easeOutCubic),
    );

    _generateBubbles();
  }

  void _generateBubbles() {
    _bubbles = List.generate(12, (index) => _Bubble(
      x: _random.nextDouble() * 0.6 + 0.2,
      y: _random.nextDouble() * 0.7 + 0.3,
      size: _random.nextDouble() * 4 + 2,
      speed: _random.nextDouble() * 0.5 + 0.3,
      phase: _random.nextDouble() * math.pi * 2,
    ));
  }

  @override
  void didUpdateWidget(WaterGlassWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    double newTarget = widget.currentAmount / widget.targetAmount;
    if ((newTarget - _targetFillLevel).abs() > 0.001) {
      _animateFillLevel(newTarget);
    }
  }

  void _animateFillLevel(double newTarget) {
    _previousFillLevel = _currentFillLevel;
    setState(() {
      _targetFillLevel = newTarget;
    });

    _fillAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.easeOutCubic),
    );

    _fillController.reset();
    _splashController.reset();
    _splashController.forward();
    _fillController.forward().then((_) {
      setState(() {
        _currentFillLevel = _targetFillLevel;
      });
    });

    if (newTarget > _previousFillLevel) {
      _generateBubbles();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fillController.dispose();
    _bubbleController.dispose();
    _splashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _waveController,
        _fillController,
        _bubbleController,
        _splashController,
      ]),
      builder: (context, child) {
        double animatedFill;
        if (_fillController.isAnimating) {
          animatedFill = _previousFillLevel +
              (_targetFillLevel - _previousFillLevel) * _fillAnimation.value;
        } else {
          animatedFill = _targetFillLevel;
        }

        double wavePhase = _waveController.value * 2 * math.pi;
        double bubblePhase = _bubbleController.value * 2 * math.pi;
        double splashPhase = _splashController.value;

        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _WaterGlassPainter(
            fillPercent: animatedFill.clamp(0.0, 1.0),
            wavePhase: wavePhase,
            bubblePhase: bubblePhase,
            bubbles: _bubbles,
            splashIntensity: _fillController.isAnimating ? splashPhase : 0,
            goalReached: widget.goalReached,
          ),
        );
      },
    );
  }
}

class _Bubble {
  double x;
  double y;
  double size;
  double speed;
  double phase;

  _Bubble({
    this.x = 0.5,
    this.y = 0.5,
    this.size = 3,
    this.speed = 0.5,
    this.phase = 0,
  });
}

class _WaterGlassPainter extends CustomPainter {
  final double fillPercent;
  final double wavePhase;
  final double bubblePhase;
  final List<_Bubble> bubbles;
  final double splashIntensity;
  final bool goalReached;

  _WaterGlassPainter({
    this.fillPercent = 0,
    this.wavePhase = 0,
    this.bubblePhase = 0,
    this.bubbles = const [],
    this.splashIntensity = 0,
    this.goalReached = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double glassWidth = size.width;
    double glassHeight = size.height;
    double glassRadius = 25;
    double bottomRadius = 20;
    double waterLevel = glassHeight * (1 - fillPercent);

    double taperLeft = glassWidth * 0.08;
    double taperRight = glassWidth * 0.08;

    Path glassPath = Path();
    glassPath.moveTo(glassRadius + 10, 0);
    glassPath.lineTo(glassWidth - glassRadius - 10, 0);
    glassPath.arcToPoint(
      Offset(glassWidth - 10, glassRadius),
      radius: Radius.circular(glassRadius),
    );
    glassPath.lineTo(glassWidth - 10 - taperRight, glassHeight - bottomRadius);
    glassPath.arcToPoint(
      Offset(glassWidth - 10 - taperRight - bottomRadius, glassHeight),
      radius: Radius.circular(bottomRadius),
    );
    glassPath.lineTo(glassRadius + 10 + bottomRadius, glassHeight);
    glassPath.arcToPoint(
      Offset(glassRadius + 10, glassHeight - bottomRadius),
      radius: Radius.circular(bottomRadius),
    );
    glassPath.lineTo(10 + taperLeft, glassRadius);
    glassPath.arcToPoint(
      Offset(glassRadius + 10, 0),
      radius: Radius.circular(glassRadius),
    );
    glassPath.close();

    canvas.save();
    canvas.clipPath(glassPath);

    if (fillPercent > 0) {
      _drawWater(canvas, size, waterLevel, glassWidth, glassHeight);
      _drawBubbles(canvas, size, waterLevel, glassWidth, glassHeight);
    }

    if (splashIntensity > 0) {
      _drawSplash(canvas, size, glassWidth, waterLevel, splashIntensity);
    }

    canvas.restore();

    _drawGlassGlass(canvas, size, glassWidth, glassHeight);
    _drawGlassHighlights(canvas, size, glassWidth, glassHeight, glassRadius);

    if (goalReached) {
      _drawGoalReachedEffect(canvas, size, glassWidth, glassHeight);
    }
  }

  void _drawWater(Canvas canvas, Size size, double waterLevel,
      double glassWidth, double glassHeight) {
    double baseWaveHeight = 8 + splashIntensity * 10;

    Path wave1Path = Path();
    wave1Path.moveTo(0, glassHeight);
    wave1Path.lineTo(0, waterLevel);

    double freq1 = 2.0;
    double freq2 = 3.5;
    double freq3 = 1.5;

    for (double x = 0; x <= glassWidth; x += 2) {
      double y1 = math.sin(x * freq1 * 0.08 + wavePhase) * baseWaveHeight;
      double y2 = math.sin(x * freq2 * 0.08 + wavePhase * 1.5 + 0.5) * baseWaveHeight * 0.5;
      double y3 = math.sin(x * freq3 * 0.08 + wavePhase * 0.8 + 1) * baseWaveHeight * 0.3;
      double y = waterLevel + y1 + y2 + y3;
      wave1Path.lineTo(x, y);
    }

    wave1Path.lineTo(glassWidth, glassHeight);
    wave1Path.close();

    Paint waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF4FC3F7).withOpacity(0.8),
          Color(0xFF29B6F6).withOpacity(0.85),
          Color(0xFF03A9F4).withOpacity(0.9),
          Color(0xFF0288D1).withOpacity(0.95),
        ],
        stops: [0.0, 0.3, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, waterLevel, glassWidth, glassHeight - waterLevel));

    canvas.drawPath(wave1Path, waterPaint);

    Path wave2Path = Path();
    wave2Path.moveTo(0, glassHeight);
    wave2Path.lineTo(0, waterLevel + 2);

    for (double x = 0; x <= glassWidth; x += 2) {
      double y1 = math.sin(x * freq1 * 0.08 + wavePhase + math.pi * 0.7) * baseWaveHeight * 0.6;
      double y2 = math.sin(x * freq2 * 0.08 + wavePhase * 1.5 + 1.5) * baseWaveHeight * 0.4;
      double y = waterLevel + 2 + y1 + y2;
      wave2Path.lineTo(x, y);
    }

    wave2Path.lineTo(glassWidth, glassHeight);
    wave2Path.close();

    Paint secondWavePaint = Paint()
      ..color = Color(0xFF81D4FA).withOpacity(0.5);

    canvas.drawPath(wave2Path, secondWavePaint);

    Path thirdWavePath = Path();
    thirdWavePath.moveTo(0, glassHeight);
    thirdWavePath.lineTo(0, waterLevel + 5);

    for (double x = 0; x <= glassWidth; x += 2) {
      double y1 = math.sin(x * freq1 * 0.08 + wavePhase + math.pi * 1.2) * baseWaveHeight * 0.4;
      double y = waterLevel + 5 + y1;
      thirdWavePath.lineTo(x, y);
    }

    thirdWavePath.lineTo(glassWidth, glassHeight);
    thirdWavePath.close();

    Paint thirdWavePaint = Paint()
      ..color = Colors.white.withOpacity(0.2);

    canvas.drawPath(thirdWavePath, thirdWavePaint);

    Paint shimmerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.25),
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.0),
        ],
        stops: [0.0, 0.3, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, waterLevel, glassWidth, glassHeight - waterLevel));

    canvas.drawPath(wave1Path, shimmerPaint);

    Path reflectionPath = Path();
    reflectionPath.moveTo(glassWidth * 0.15, waterLevel);
    reflectionPath.quadraticBezierTo(
      glassWidth * 0.25,
      glassHeight * 0.6,
      glassWidth * 0.18,
      glassHeight,
    );
    reflectionPath.lineTo(glassWidth * 0.22, glassHeight);
    reflectionPath.quadraticBezierTo(
      glassWidth * 0.3,
      glassHeight * 0.6,
      glassWidth * 0.2,
      waterLevel,
    );
    reflectionPath.close();

    Paint reflectionPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(
        glassWidth * 0.1,
        waterLevel,
        glassWidth * 0.15,
        glassHeight - waterLevel,
      ));

    canvas.drawPath(reflectionPath, reflectionPaint);
  }

  void _drawBubbles(Canvas canvas, Size size, double waterLevel,
      double glassWidth, double glassHeight) {
    Paint bubblePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    Paint bubbleHighlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (var bubble in bubbles) {
      double progress = (bubblePhase * bubble.speed + bubble.phase) % (math.pi * 2);
      double normalizedProgress = progress / (math.pi * 2);

      double bubbleY = waterLevel + (glassHeight - waterLevel - 10) * (1 - normalizedProgress);
      double wobble = math.sin(bubblePhase * 3 + bubble.phase) * 3;

      double bubbleX = glassWidth * bubble.x + wobble;
      double actualSize = bubble.size * (0.5 + normalizedProgress * 0.5);

      if (bubbleY > waterLevel + 5 && bubbleY < glassHeight - 5) {
        canvas.drawCircle(
          Offset(bubbleX, bubbleY),
          actualSize,
          bubblePaint,
        );

        canvas.drawCircle(
          Offset(bubbleX - actualSize * 0.3, bubbleY - actualSize * 0.3),
          actualSize * 0.3,
          bubbleHighlightPaint,
        );
      }
    }
  }

  void _drawSplash(Canvas canvas, Size size, double glassWidth,
      double waterLevel, double intensity) {
    double splashHeight = intensity * 20;
    double splashWidth = intensity * 30;

    Paint splashPaint = Paint()
      ..color = Color(0xFF4FC3F7).withOpacity(0.7 * intensity)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      double x = glassWidth * 0.3 + i * glassWidth * 0.1;
      double splashY = waterLevel - splashHeight * (1 - (i / 5).abs());

      Path droplet = Path();
      droplet.moveTo(x, waterLevel);
      droplet.quadraticBezierTo(
        x - splashWidth * 0.5,
        waterLevel - splashHeight,
        x - splashWidth * 0.3,
        waterLevel - splashHeight - 5,
      );
      droplet.quadraticBezierTo(
        x,
        waterLevel - splashHeight - 10,
        x + splashWidth * 0.3,
        waterLevel - splashHeight - 5,
      );
      droplet.quadraticBezierTo(
        x + splashWidth * 0.5,
        waterLevel - splashHeight,
        x,
        waterLevel,
      );

      canvas.drawPath(droplet, splashPaint);
    }
  }

  void _drawGlassGlass(Canvas canvas, Size size, double glassWidth, double glassHeight) {
    Paint glassPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    double taperLeft = glassWidth * 0.08;
    double taperRight = glassWidth * 0.08;
    double glassRadius = 25;
    double bottomRadius = 20;

    Path glassBorderPath = Path();
    glassBorderPath.moveTo(glassRadius + 10, 0);
    glassBorderPath.lineTo(glassWidth - glassRadius - 10, 0);
    glassBorderPath.arcToPoint(
      Offset(glassWidth - 10, glassRadius),
      radius: Radius.circular(glassRadius),
    );
    glassBorderPath.lineTo(glassWidth - 10 - taperRight, glassHeight - bottomRadius);
    glassBorderPath.arcToPoint(
      Offset(glassWidth - 10 - taperRight - bottomRadius, glassHeight),
      radius: Radius.circular(bottomRadius),
    );
    glassBorderPath.lineTo(glassRadius + 10 + bottomRadius, glassHeight);
    glassBorderPath.arcToPoint(
      Offset(glassRadius + 10, glassHeight - bottomRadius),
      radius: Radius.circular(bottomRadius),
    );
    glassBorderPath.lineTo(10 + taperLeft, glassRadius);
    glassBorderPath.arcToPoint(
      Offset(glassRadius + 10, 0),
      radius: Radius.circular(glassRadius),
    );

    canvas.drawPath(glassBorderPath, glassPaint);

    Paint glassFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.15),
        ],
      ).createShader(Rect.fromLTWH(0, 0, glassWidth, glassHeight));

    canvas.drawPath(glassBorderPath, glassFillPaint);
  }

  void _drawGlassHighlights(Canvas canvas, Size size, double glassWidth,
      double glassHeight, double glassRadius) {
    Paint leftHighlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(glassRadius + 5, 5, glassWidth * 0.25, glassHeight - 10));

    canvas.drawRRect(
      RRect.fromLTRBR(
        glassRadius + 5,
        5,
        glassRadius + 5 + glassWidth * 0.25,
        glassHeight - 5,
        Radius.circular(glassRadius),
      ),
      leftHighlight,
    );

    Paint rimHighlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.6),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, glassWidth, 20));

    canvas.drawRRect(
      RRect.fromLTRBR(
        glassRadius + 5,
        2,
        glassWidth - glassRadius - 5,
        18,
        Radius.circular(glassRadius),
      ),
      rimHighlight,
    );

    Paint smallHighlight1 = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(glassWidth - glassRadius - 15, glassHeight * 0.25),
      Offset(glassWidth - glassRadius - 15, glassHeight * 0.45),
      smallHighlight1,
    );

    canvas.drawLine(
      Offset(glassWidth - glassRadius - 15, glassHeight * 0.5),
      Offset(glassWidth - glassRadius - 15, glassHeight * 0.6),
      smallHighlight1,
    );
  }

  void _drawGoalReachedEffect(Canvas canvas, Size size, double glassWidth, double glassHeight) {
    Paint glowPaint = Paint()
      ..color = Color(0xFF4CAF50).withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawRRect(
      RRect.fromLTRBR(
        5,
        5,
        glassWidth - 5,
        glassHeight - 5,
        Radius.circular(25),
      ),
      glowPaint,
    );

    double shimmer = (math.sin(wavePhase * 2) + 1) / 2;
    Paint shimmerGlow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(shimmer * 0.3),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, glassWidth, glassHeight));

    canvas.drawRRect(
      RRect.fromLTRBR(
        5,
        5,
        glassWidth - 5,
        glassHeight - 5,
        Radius.circular(25),
      ),
      shimmerGlow,
    );
  }

  @override
  bool shouldRepaint(_WaterGlassPainter oldDelegate) {
    return oldDelegate.fillPercent != fillPercent ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.splashIntensity != splashIntensity ||
        oldDelegate.goalReached != goalReached;
  }
}