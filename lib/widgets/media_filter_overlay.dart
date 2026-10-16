import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/post_filter.dart';

class MediaFilterOverlay extends StatefulWidget {
  final String? filterId;
  final bool interactive;
  final double? normalizedX;
  final double? normalizedY;
  final double? scale;
  final double? mediaAspectRatio;
  final void Function(double normX, double normY, double scale)? onTransformChanged;

  const MediaFilterOverlay({
    super.key,
    required this.filterId,
    this.interactive = false,
    this.normalizedX,
    this.normalizedY,
    this.scale,
    this.mediaAspectRatio,
    this.onTransformChanged,
  });

  @override
  State<MediaFilterOverlay> createState() => _MediaFilterOverlayState();
}

class _MediaFilterOverlayState extends State<MediaFilterOverlay> {
  late double _currentScale;
  Offset? _pixelOffset;
  Offset _dragStartFocalPoint = Offset.zero;
  Offset _dragStartOffset = Offset.zero;
  double _dragStartScale = 1.0;
  final Set<int> _activePointers = <int>{};

  @override
  void initState() {
    super.initState();
    _currentScale = widget.scale ?? 1.0;
  }

  @override
  void didUpdateWidget(covariant MediaFilterOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scale != null && widget.scale != oldWidget.scale) {
      _currentScale = widget.scale!;
    }
    if (widget.normalizedX != oldWidget.normalizedX ||
        widget.normalizedY != oldWidget.normalizedY ||
        widget.filterId != oldWidget.filterId) {
      // Una nueva detección o un nuevo filtro debe reemplazar el último
      // desplazamiento manual, no superponerse con él.
      _pixelOffset = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final option = PostFilterOption.fromId(widget.filterId);
    if (option.type == PostFilterType.none) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        Widget filterWidget;
        double defaultTopRatio = 0.25;
        double baseFilterWidth = 170.0;

        switch (option.type) {
          case PostFilterType.sunglasses:
            defaultTopRatio = 0.28;
            baseFilterWidth = 180.0;
            filterWidget = _SunglassesFilter(width: baseFilterWidth);
            break;
          case PostFilterType.mustache:
            defaultTopRatio = 0.44;
            baseFilterWidth = 150.0;
            filterWidget = _MustacheFilter(width: baseFilterWidth);
            break;
          case PostFilterType.birthdayCone:
            defaultTopRatio = 0.05;
            baseFilterWidth = 160.0;
            filterWidget = _BirthdayConeFilter(width: baseFilterWidth);
            break;
          case PostFilterType.partyGlasses:
            defaultTopRatio = 0.28;
            baseFilterWidth = 190.0;
            filterWidget = _PartyGlassesFilter(width: baseFilterWidth);
            break;
          case PostFilterType.funnyHat:
            defaultTopRatio = 0.04;
            baseFilterWidth = 180.0;
            filterWidget = _FunnyHatFilter(width: baseFilterWidth);
            break;
          case PostFilterType.crown:
            defaultTopRatio = 0.06;
            baseFilterWidth = 170.0;
            filterWidget = _CrownFilter(width: baseFilterWidth);
            break;
          case PostFilterType.catEars:
            defaultTopRatio = 0.07;
            baseFilterWidth = 200.0;
            filterWidget = _CatEarsFilter(width: baseFilterWidth);
            break;
          case PostFilterType.none:
            return const SizedBox.shrink();
        }

        final double defaultLeft = (width - baseFilterWidth) / 2;
        final double defaultTop = height * defaultTopRatio;

        // La imagen con BoxFit.contain puede dejar bandas vacías. Mapeamos
        // las coordenadas normalizadas al rectángulo visible de la imagen.
        double mediaLeft = 0;
        double mediaTop = 0;
        double mediaWidth = width;
        double mediaHeight = height;
        final aspect = widget.mediaAspectRatio;
        if (aspect != null && aspect > 0) {
          final containerAspect = width / height;
          if (aspect > containerAspect) {
            mediaHeight = width / aspect;
            mediaTop = (height - mediaHeight) / 2;
          } else {
            mediaWidth = height * aspect;
            mediaLeft = (width - mediaWidth) / 2;
          }
        }

        final isHat = option.type == PostFilterType.birthdayCone ||
            option.type == PostFilterType.funnyHat ||
            option.type == PostFilterType.crown ||
            option.type == PostFilterType.catEars;
        final filterHeight = _filterHeight(option.type, baseFilterWidth);
        final anchorY = isHat ? 0.90 : 0.50;

        double currentLeft;
        double currentTop;

        if (_pixelOffset != null) {
          currentLeft = _pixelOffset!.dx;
          currentTop = _pixelOffset!.dy;
        } else if (widget.normalizedX != null && widget.normalizedY != null) {
          final centerX = mediaLeft + (widget.normalizedX! * mediaWidth);
          final centerY = mediaTop + (widget.normalizedY! * mediaHeight);
          currentLeft = centerX - (baseFilterWidth * _currentScale / 2);
          currentTop = centerY - (filterHeight * _currentScale * anchorY);
        } else {
          currentLeft = defaultLeft;
          currentTop = defaultTop;
        }

        final double maxLeft = math.max<double>(0.0, width - 40);
        final double maxTop = math.max<double>(0.0, height - 40);
        final double left = currentLeft.clamp(-80.0, maxLeft).toDouble();
        final double top = currentTop.clamp(-40.0, maxTop).toDouble();

        void reportTransform(double newLeft, double newTop) {
          if (widget.onTransformChanged == null) return;
          final centerX =
              (newLeft + (baseFilterWidth * _currentScale / 2) - mediaLeft) /
                  mediaWidth;
          final centerY =
              (newTop + (filterHeight * _currentScale * anchorY) - mediaTop) /
                  mediaHeight;
          widget.onTransformChanged!(
            centerX.clamp(0.0, 1.0).toDouble(),
            centerY.clamp(0.0, 1.0).toDouble(),
            _currentScale,
          );
        }

        final scaledContent = Transform.scale(
          scale: _currentScale,
          alignment: Alignment.center,
          child: filterWidget,
        );

        if (!widget.interactive) {
          return Positioned(
            left: left,
            top: top,
            child: IgnorePointer(child: scaledContent),
          );
        }

        // El área táctil cubre toda la vista previa. Antes solo coincidía con
        // el tamaño original del dibujo y era muy fácil no acertarle al item,
        // especialmente después de reducirlo.
        return Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) => _activePointers.add(event.pointer),
            onPointerUp: (event) => _activePointers.remove(event.pointer),
            onPointerCancel: (event) => _activePointers.remove(event.pointer),
            // Un dedo mueve el filtro de forma directa. Listener evita que el
            // gesto de escala intercepte el arrastre en algunos dispositivos.
            onPointerMove: (event) {
              if (_activePointers.length != 1) return;
              final current = _pixelOffset ?? Offset(left, top);
              final newLeft = current.dx + event.delta.dx;
              final newTop = current.dy + event.delta.dy;
              setState(() => _pixelOffset = Offset(newLeft, newTop));
              reportTransform(newLeft, newTop);
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (details) {
                _dragStartFocalPoint = details.focalPoint;
                _dragStartOffset = _pixelOffset ?? Offset(left, top);
                _dragStartScale = _currentScale;
              },
              onScaleUpdate: (details) {
                if (details.pointerCount < 2) return;
                final delta = details.focalPoint - _dragStartFocalPoint;
                final newLeft = _dragStartOffset.dx + delta.dx;
                final newTop = _dragStartOffset.dy + delta.dy;
                setState(() {
                  _pixelOffset = Offset(newLeft, newTop);
                  _currentScale =
                      (_dragStartScale * details.scale).clamp(0.4, 3.0).toDouble();
                });
                reportTransform(newLeft, newTop);
              },
              child: Stack(
                children: [
                  Positioned(
                    left: left,
                    top: top,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: scaledContent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _filterHeight(PostFilterType type, double width) {
    switch (type) {
      case PostFilterType.sunglasses:
        return width * 0.38;
      case PostFilterType.mustache:
      case PostFilterType.partyGlasses:
        return width * 0.45;
      case PostFilterType.birthdayCone:
        return width * 1.15;
      case PostFilterType.funnyHat:
        return width * 0.75;
      case PostFilterType.crown:
        return width * 0.65;
      case PostFilterType.catEars:
        return width * 0.55;
      case PostFilterType.none:
        return 0;
    }
  }
}

class _SunglassesFilter extends StatelessWidget {
  final double width;
  const _SunglassesFilter({required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.38,
      child: CustomPaint(
        painter: _SunglassesPainter(),
      ),
    );
  }
}

class _SunglassesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.fill;

    final lensPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1E272C), Color(0xFF000000)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final reflectionPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final eyeWidth = size.width * 0.42;
    final eyeHeight = size.height * 0.75;
    final rrectRadius = Radius.circular(eyeHeight * 0.4);

    // Lente izquierdo
    final leftRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.04, size.height * 0.15, eyeWidth, eyeHeight),
      rrectRadius,
    );
    // Lente derecho
    final rightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.54, size.height * 0.15, eyeWidth, eyeHeight),
      rrectRadius,
    );

    // Marco
    canvas.drawRRect(leftRect.inflate(4), framePaint);
    canvas.drawRRect(rightRect.inflate(4), framePaint);

    // Puente nasal
    final bridgePath = Path()
      ..moveTo(size.width * 0.43, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.49, size.height * 0.22, size.width * 0.55, size.height * 0.3)
      ..lineTo(size.width * 0.55, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.49, size.height * 0.32, size.width * 0.43, size.height * 0.4)
      ..close();
    canvas.drawPath(bridgePath, framePaint);

    // Lentes oscuros
    canvas.drawRRect(leftRect, lensPaint);
    canvas.drawRRect(rightRect, lensPaint);

    // Reflejo blanco en cristales
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.3),
      Offset(size.width * 0.28, size.height * 0.7),
      reflectionPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, size.height * 0.3),
      Offset(size.width * 0.78, size.height * 0.7),
      reflectionPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MustacheFilter extends StatelessWidget {
  final double width;
  const _MustacheFilter({required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.45,
      child: CustomPaint(
        painter: _MustachePainter(),
      ),
    );
  }
}

class _MustachePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2C1B14)
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black26
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, h * 0.35);
    // Lado izquierdo
    path.cubicTo(w * 0.38, h * 0.05, w * 0.15, h * 0.2, w * 0.02, h * 0.55);
    path.cubicTo(w * 0.12, h * 0.95, w * 0.35, h * 0.75, w * 0.5, h * 0.55);
    // Lado derecho
    path.cubicTo(w * 0.65, h * 0.75, w * 0.88, h * 0.95, w * 0.98, h * 0.55);
    path.cubicTo(w * 0.85, h * 0.2, w * 0.62, h * 0.05, w * 0.5, h * 0.35);
    path.close();

    canvas.drawPath(path.shift(const Offset(0, 3)), shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BirthdayConeFilter extends StatelessWidget {
  final double width;
  const _BirthdayConeFilter({required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 1.15,
      child: CustomPaint(
        painter: _BirthdayConePainter(),
      ),
    );
  }
}

class _BirthdayConePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Cono
    final conePath = Path()
      ..moveTo(w * 0.5, h * 0.15)
      ..lineTo(w * 0.85, h * 0.9)
      ..quadraticBezierTo(w * 0.5, h * 0.98, w * 0.15, h * 0.9)
      ..close();

    final conePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF3366), Color(0xFFFF9900), Color(0xFF00CCFF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(conePath, conePaint);

    // Franjas festivas
    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(w * 0.38, h * 0.45), Offset(w * 0.62, h * 0.45), stripePaint);
    canvas.drawLine(Offset(w * 0.28, h * 0.65), Offset(w * 0.72, h * 0.65), stripePaint);
    canvas.drawLine(Offset(w * 0.20, h * 0.82), Offset(w * 0.80, h * 0.82), stripePaint);

    // Pompón superior
    final pompomPaint = Paint()..color = const Color(0xFFFFEA00);
    canvas.drawCircle(Offset(w * 0.5, h * 0.12), w * 0.1, pompomPaint);

    // Puntos de confeti decorativo
    final confetiColors = [Colors.cyanAccent, Colors.yellowAccent, Colors.pinkAccent, Colors.greenAccent];
    final random = math.Random(42);
    for (int i = 0; i < 16; i++) {
      final paint = Paint()..color = confetiColors[i % confetiColors.length];
      final cx = w * (0.05 + random.nextDouble() * 0.9);
      final cy = h * (0.05 + random.nextDouble() * 0.95);
      canvas.drawCircle(Offset(cx, cy), 3.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PartyGlassesFilter extends StatelessWidget {
  final double width;
  const _PartyGlassesFilter({required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.45,
      child: CustomPaint(
        painter: _PartyGlassesPainter(),
      ),
    );
  }
}

class _PartyGlassesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final starPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF007F), Color(0xFFFFD700)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final lensPaint = Paint()
      ..color = Colors.purple.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    Path createStar(Offset center, double radius) {
      final path = Path();
      const points = 5;
      const angle = math.pi / points;
      for (int i = 0; i < 2 * points; i++) {
        final r = (i % 2 == 0) ? radius : radius * 0.5;
        final x = center.dx + r * math.sin(i * angle);
        final y = center.dy - r * math.cos(i * angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      return path;
    }

    final leftCenter = Offset(w * 0.28, h * 0.5);
    final rightCenter = Offset(w * 0.72, h * 0.5);

    // Puente entre estrellas
    final bridgePaint = Paint()
      ..color = const Color(0xFFFF007F)
      ..strokeWidth = 5;
    canvas.drawLine(leftCenter, rightCenter, bridgePaint);

    // Estrellas
    final leftStar = createStar(leftCenter, w * 0.24);
    final rightStar = createStar(rightCenter, w * 0.24);

    canvas.drawPath(leftStar, starPaint);
    canvas.drawPath(rightStar, starPaint);

    // Lentes interiores translúcidos
    canvas.drawCircle(leftCenter, w * 0.12, lensPaint);
    canvas.drawCircle(rightCenter, w * 0.12, lensPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FunnyHatFilter extends StatelessWidget {
  final double width;
  const _FunnyHatFilter({required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.75,
      child: CustomPaint(
        painter: _FunnyHatPainter(),
      ),
    );
  }
}

class _FunnyHatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final hatPaint = Paint()
      ..color = const Color(0xFF1E1E2C)
      ..style = PaintingStyle.fill;

    final ribbonPaint = Paint()
      ..color = const Color(0xFFFF2A6D)
      ..style = PaintingStyle.fill;

    // Copa del sombrero
    final crownPath = Path()
      ..moveTo(w * 0.26, h * 0.72)
      ..lineTo(w * 0.22, h * 0.18)
      ..quadraticBezierTo(w * 0.5, h * 0.12, w * 0.78, h * 0.18)
      ..lineTo(w * 0.74, h * 0.72)
      ..close();
    canvas.drawPath(crownPath, hatPaint);

    // Cinta de color llamativo
    final ribbonPath = Path()
      ..moveTo(w * 0.25, h * 0.72)
      ..lineTo(w * 0.24, h * 0.58)
      ..lineTo(w * 0.76, h * 0.58)
      ..lineTo(w * 0.75, h * 0.72)
      ..close();
    canvas.drawPath(ribbonPath, ribbonPaint);

    // Ala ancha del sombrero
    final brimRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.76),
      width: w * 0.95,
      height: h * 0.22,
    );
    canvas.drawOval(brimRect, hatPaint);

    // Flor o estrella divertida en la cinta
    final flowerPaint = Paint()..color = const Color(0xFF05FFA1);
    canvas.drawCircle(Offset(w * 0.68, h * 0.65), 10, flowerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CrownFilter extends StatelessWidget {
  final double width;
  const _CrownFilter({required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.65,
      child: CustomPaint(
        painter: _CrownPainter(),
      ),
    );
  }
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final goldPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFDF00), Color(0xFFD4AF37), Color(0xFFFFB300)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(w * 0.1, h * 0.8)
      ..lineTo(w * 0.1, h * 0.3)
      ..lineTo(w * 0.3, h * 0.55)
      ..lineTo(w * 0.5, h * 0.18) // Pico central más alto
      ..lineTo(w * 0.7, h * 0.55)
      ..lineTo(w * 0.9, h * 0.3)
      ..lineTo(w * 0.9, h * 0.8)
      ..close();

    canvas.drawPath(path, goldPaint);

    // Gemas de la corona
    final gemColors = [Colors.redAccent, Colors.cyanAccent, Colors.purpleAccent];
    final gemX = [w * 0.3, w * 0.5, w * 0.7];
    for (int i = 0; i < gemX.length; i++) {
      final gemPaint = Paint()..color = gemColors[i % gemColors.length];
      canvas.drawCircle(Offset(gemX[i], h * 0.68), 7, gemPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CatEarsFilter extends StatelessWidget {
  final double width;
  const _CatEarsFilter({required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.55,
      child: CustomPaint(
        painter: _CatEarsPainter(),
      ),
    );
  }
}

class _CatEarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final outerPaint = Paint()
      ..color = const Color(0xFF2C2C2C)
      ..style = PaintingStyle.fill;

    final innerPaint = Paint()
      ..color = const Color(0xFFFF8DA1)
      ..style = PaintingStyle.fill;

    // Oreja izquierda externa
    final leftEarOuter = Path()
      ..moveTo(w * 0.15, h * 0.85)
      ..lineTo(w * 0.22, h * 0.12)
      ..lineTo(w * 0.42, h * 0.65)
      ..close();

    // Oreja derecha externa
    final rightEarOuter = Path()
      ..moveTo(w * 0.85, h * 0.85)
      ..lineTo(w * 0.78, h * 0.12)
      ..lineTo(w * 0.58, h * 0.65)
      ..close();

    canvas.drawPath(leftEarOuter, outerPaint);
    canvas.drawPath(rightEarOuter, outerPaint);

    // Oreja izquierda interna rosa
    final leftEarInner = Path()
      ..moveTo(w * 0.20, h * 0.78)
      ..lineTo(w * 0.25, h * 0.26)
      ..lineTo(w * 0.38, h * 0.65)
      ..close();

    // Oreja derecha interna rosa
    final rightEarInner = Path()
      ..moveTo(w * 0.80, h * 0.78)
      ..lineTo(w * 0.75, h * 0.26)
      ..lineTo(w * 0.62, h * 0.65)
      ..close();

    canvas.drawPath(leftEarInner, innerPaint);
    canvas.drawPath(rightEarInner, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
