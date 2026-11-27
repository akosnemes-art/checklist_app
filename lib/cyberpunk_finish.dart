part of 'main.dart';

const _cyberpunkContentStart = .51;

Widget _cyberpunkOutline(
  ThemeData theme,
  Widget child, {
  ShapeBorder shape = const RoundedRectangleBorder(),
  FocusNode? focus,
}) {
  if (theme.appearance != AppTheme.cyberpunk) return child;
  return CustomPaint(
    foregroundPainter:
        _CyberpunkBorderGlow(theme.colorScheme.outline, shape, focus),
    child: child,
  );
}

class _CyberpunkBorderGlow extends CustomPainter {
  const _CyberpunkBorderGlow(this.colour, this.shape, this.focus)
      : super(repaint: focus);

  final Color colour;
  final ShapeBorder shape;
  final FocusNode? focus;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.shortestSide < 2) return;
    final edge = shape.getOuterPath((Offset.zero & size).deflate(1));
    final focused = focus?.hasFocus ?? false;
    canvas.drawPath(edge, _cyberpunkGlowPaint(colour, focused ? .78 : .24));
  }

  @override
  bool shouldRepaint(_CyberpunkBorderGlow oldDelegate) =>
      oldDelegate.colour != colour ||
      oldDelegate.shape != shape ||
      oldDelegate.focus != focus;
}

Paint _cyberpunkGlowPaint(Color colour, double opacity) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 4
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
  ..color = colour.withValues(alpha: opacity);

const _cyberpunkReminderFrame = _CyberpunkPopupFrame(
  side: BorderSide(color: _cyberpunkRed, width: 1),
  accent: _cyberpunkRed,
  reminder: true,
);

DatePickerThemeData _cyberpunkCalendarTheme(
    DatePickerThemeData base, double flash) {
  final colour = Color.lerp(_cyberpunkRed, _brandYellow, flash)!;
  Color fill(Set<WidgetState> states) => states.contains(WidgetState.selected)
      ? colour.withValues(alpha: ui.lerpDouble(.24, .94, flash)!)
      : Colors.transparent;
  final selectedForeground =
      flash > .65 ? _cyberpunkPalette.buttonInk : _cyberpunkPalette.ink;
  return base.copyWith(
    dayBackgroundColor: WidgetStateProperty.resolveWith(fill),
    todayBackgroundColor: WidgetStateProperty.resolveWith(fill),
    todayBorder: BorderSide.none,
    dayForegroundColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? selectedForeground : null),
    todayForegroundColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? selectedForeground
            : _cyberpunkPalette.checklistAccent),
    dayOverlayColor: const WidgetStatePropertyAll(Color(0x21FF2349)),
    dayShape: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      return _CyberpunkCalendarDay(
        BorderSide(
            color: selected ? colour : const Color(0x58FF2349), width: .7),
        selected: selected,
      );
    }),
  );
}

class _CyberpunkCalendarDay extends BeveledRectangleBorder {
  const _CyberpunkCalendarDay(BorderSide side, {required this.selected})
      : super(
          side: side,
          borderRadius:
              const BorderRadius.only(bottomRight: Radius.circular(6)),
        );

  final bool selected;

  Rect _square(Rect rect) => Rect.fromCenter(
      center: rect.center, width: rect.shortestSide, height: rect.shortestSide);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      super.getOuterPath(_square(rect), textDirection: textDirection);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      super.getInnerPath(_square(rect), textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final outline = getOuterPath(rect.deflate(side.width / 2));
    if (selected) {
      canvas.drawPath(outline, _cyberpunkGlowPaint(side.color, .54));
    }
    canvas.drawPath(outline, side.toPaint());
  }

  @override
  _CyberpunkCalendarDay copyWith(
          {BorderSide? side, BorderRadiusGeometry? borderRadius}) =>
      _CyberpunkCalendarDay(
        side == null || side.style == BorderStyle.none ? this.side : side,
        selected: selected,
      );

  @override
  bool operator ==(Object other) =>
      other is _CyberpunkCalendarDay &&
      super == other &&
      selected == other.selected;

  @override
  int get hashCode => Object.hash(super.hashCode, selected);
}

AnimationStyle? _cyberpunkMenuMotion(BuildContext context) {
  if (Theme.of(context).appearance != AppTheme.cyberpunk) return null;
  if (MediaQuery.disableAnimationsOf(context)) {
    return AnimationStyle.noAnimation;
  }
  return const AnimationStyle(
    duration: _popupDuration,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInQuad,
  );
}

class _CyberpunkFinish extends CustomPainter {
  const _CyberpunkFinish(this.accent, {this.sidebarBorder});

  final Color accent;
  final Color? sidebarBorder;
  static const _tileSize = 160.0;
  static final _grain = makeGrain(8107);

  static ui.Picture makeGrain(int seed) {
    final random = math.Random(seed);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Offset.zero & const Size.square(_tileSize));
    for (final colour in [const Color(0x0EFFEAF3), const Color(0x1A000000)]) {
      final points = Float32List(4100);
      for (var i = 0; i < points.length; i++) {
        points[i] = random.nextDouble() * _tileSize;
      }
      canvas.drawRawPoints(
        ui.PointMode.points,
        points,
        Paint()
          ..color = colour
          ..strokeWidth = .75
          ..isAntiAlias = false,
      );
    }
    return recorder.endRecording();
  }

  static void paintGrain(Canvas canvas, Rect bounds) {
    canvas.save();
    canvas.clipRect(bounds);
    canvas.translate(bounds.left, bounds.top);
    for (var y = 0.0; y < bounds.height; y += _tileSize) {
      final start = -((y / _tileSize) * 47 % _tileSize);
      canvas.save();
      canvas.translate(start, y);
      for (var x = start; x < bounds.width; x += _tileSize) {
        canvas.drawPicture(_grain);
        canvas.translate(_tileSize, 0);
      }
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final edge = Rect.fromLTWH(0, 0, size.width, math.min(92, size.height));
    canvas.drawRect(
      edge,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.withValues(alpha: .08), accent.withValues(alpha: 0)],
        ).createShader(edge),
    );
    if (sidebarBorder case final colour?) {
      final edge = Offset(size.width - 1, 0);
      canvas.drawLine(edge, edge.translate(0, size.height),
          _cyberpunkGlowPaint(colour, .3));
    }
  }

  @override
  bool shouldRepaint(_CyberpunkFinish oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.sidebarBorder != sidebarBorder;
}

class _CyberpunkPopupFrame extends RoundedRectangleBorder {
  const _CyberpunkPopupFrame({
    required super.side,
    required this.accent,
    this.progress = 1,
    this.surface,
    this.reminder = false,
  });

  final Color accent;
  final double progress;
  // The native time picker owns its content. Fade it through a surface mask.
  final Color? surface;
  final bool reminder;

  Path _outline(Rect rect) => reminder
      ? const BeveledRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(18),
          ),
        ).getOuterPath(rect)
      : (Path()..addRect(rect));

  Rect _aperture(Rect rect) {
    final horizontal =
        const Interval(0, .25, curve: Curves.easeOutCubic).transform(progress);
    final vertical = const Interval(.14, .55, curve: Curves.easeOutCubic)
        .transform(progress);
    return Rect.fromCenter(
      center: rect.center,
      width: rect.width * horizontal,
      height: ui.lerpDouble(math.min(rect.height, 3), rect.height, vertical)!,
    );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _outline(_aperture(rect));

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final opening = _aperture(rect);
    final inset = math.min(side.width, opening.shortestSide / 2);
    return _outline(opening.deflate(inset));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final opening = _aperture(rect);
    if (opening.isEmpty) return;
    final reveal =
        const Interval(_cyberpunkContentStart, 1, curve: Curves.easeOut)
            .transform(progress);
    if (surface case final colour? when reveal < 1) {
      canvas.drawRect(
          opening, Paint()..color = colour.withValues(alpha: 1 - reveal));
    }

    _CyberpunkFinish.paintGrain(canvas, opening);
    canvas.save();
    canvas.clipRect(opening);

    final pulse =
        1 - const Interval(.24, .72, curve: Curves.easeOut).transform(progress);
    if (pulse > 0) {
      // Two translucent plates expand with the frame and settle before the copy.
      final plate = opening.deflate(math.min(opening.shortestSide / 4, 5));
      canvas.drawRect(
          plate, Paint()..color = accent.withValues(alpha: .14 * pulse));
      canvas.drawRect(
        Rect.fromLTRB(plate.left, plate.top, plate.left + plate.width * .28,
            plate.bottom),
        Paint()..color = accent.withValues(alpha: .12 * pulse),
      );
    }

    final frame =
        opening.deflate(math.min(side.width / 2, opening.shortestSide / 2));
    final outline = _outline(frame);
    canvas.drawPath(
        outline, _cyberpunkGlowPaint(side.color, .20 + .18 * pulse));
    canvas.drawPath(outline, side.toPaint());
    final rail = math.min(27.0, frame.width * .16);
    final trim = Paint()
      ..color = Color.lerp(side.color, Colors.white, .12 + .1 * pulse)!
      ..strokeWidth = 2;
    canvas.drawLine(frame.topLeft, frame.topLeft + Offset(rail, 0), trim);
    if (reminder) {
      final foot =
          Offset(frame.right - math.min(19, frame.width / 4), frame.bottom);
      canvas.drawLine(foot - Offset(rail, 0), foot, trim);
      final interference = math.sin(math.pi * (progress / .72).clamp(0, 1));
      if (interference > .01) {
        final step = (progress * 26).floor();
        final trace = Paint()
          ..color = accent.withValues(alpha: .32 * interference);
        for (var band = 0; band < 3; band++) {
          final left = frame.left + frame.width * ((step + band * 3) % 8) / 10;
          final top = frame.top + frame.height * (.19 + band * .29);
          canvas.drawRect(
              Rect.fromLTWH(left, top, frame.width * .19, 2), trace);
        }
      }
    } else {
      canvas.drawLine(
          frame.bottomRight - Offset(rail, 0), frame.bottomRight, trim);
    }
    canvas.restore();
  }

  // Material receives the route's current frame directly.
  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => this;

  @override
  _CyberpunkPopupFrame copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
    Color? accent,
    double? progress,
  }) =>
      _CyberpunkPopupFrame(
        side: side ?? this.side,
        accent: accent ?? this.accent,
        progress: progress ?? this.progress,
        surface: surface,
        reminder: reminder,
      );

  @override
  bool operator ==(Object other) =>
      other is _CyberpunkPopupFrame &&
      other.side == side &&
      other.accent == accent &&
      other.progress == progress &&
      other.surface == surface &&
      other.reminder == reminder;

  @override
  int get hashCode => Object.hash(side, accent, progress, surface, reminder);
}
