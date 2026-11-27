part of 'main.dart';

const _pastelDisplayFont = 'Coiny';
const _pastelReadingFont = 'Nunito';
const _defaultPastelCorner = 18.0;
const _pastelRoseButton = Color(0xFFECD2E1);
const _pastelBlueButton = Color(0xFFD5DFF3);
const _pastelLavender = Color(0xFFE7E0F0);
const _pastelPorcelain = Color(0xFFF2EEF5);
const _pastelRose = Color(0xFFF1E2E9);
const _pastelClay = Color(0xFFEBE7F1);
const _pastelCompletedTaskSurface = Color(0xFFE5F4EB);
const _pastelPlateShadow = Color(0x4783709B);
const _pastelPlum = Color(0xFF75445F);

BorderRadius _pastelRadius(ThemeData theme, {double scale = 1}) {
  if (theme.appearance != AppTheme.pastel) return BorderRadius.zero;
  final shape = theme.dialogTheme.shape as RoundedRectangleBorder;
  return BorderRadius.circular(
      shape.borderRadius.resolve(TextDirection.ltr).topLeft.x * scale);
}

RoundedRectangleBorder _pastelShape(ThemeData theme, {double scale = 1}) =>
    RoundedRectangleBorder(borderRadius: _pastelRadius(theme, scale: scale));

BorderSide _surfaceSide(ThemeData theme, Color colour, {double width = 2}) =>
    theme.appearance == AppTheme.pastel
        ? BorderSide.none
        : BorderSide(color: colour, width: width);

Widget _pastelDrawerButton(ThemeData theme, IconButton button) {
  if (theme.appearance != AppTheme.pastel) return button;
  return _pastelPressable(
    theme,
    KeyedSubtree(
      key: const ValueKey('pastel-drawer-button'),
      child: IconButtonTheme(
        data: const IconButtonThemeData(
          style: ButtonStyle(side: WidgetStatePropertyAll(BorderSide.none)),
        ),
        child: button,
      ),
    ),
    round: true,
    seatWidth: 4,
  );
}

ThemeData _buildPastelFinish(ThemeData base, double radius) {
  final corners = BorderRadius.circular(radius);
  final shape = RoundedRectangleBorder(borderRadius: corners);
  final fields = base.inputDecorationTheme;
  final field = _PastelInsetField(borderRadius: corners);
  final fonts = base.textTheme.apply(
    fontFamily: _pastelReadingFont,
    fontFamilyFallback: const ['Roboto', 'sans-serif'],
  );
  TextStyle? heading(TextStyle? style) =>
      style?.copyWith(fontFamily: _pastelDisplayFont);
  ButtonStyle bevel(ButtonStyle? original, {bool filled = false}) =>
      _pastelButtonBevel(corners, filled: filled).merge(original);
  final dayShape = _PastelSoftBorder(
      borderRadius: BorderRadius.circular(radius * .72), recessed: true);

  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      onPrimary: _pastelPlum,
      surfaceContainer: _pastelClay,
    ),
    textTheme: fonts.copyWith(
      headlineLarge: heading(fonts.headlineLarge),
      headlineMedium: heading(fonts.headlineMedium),
      headlineSmall: heading(fonts.headlineSmall),
      titleLarge: heading(fonts.titleLarge),
    ),
    inputDecorationTheme: fields.copyWith(
      border: field,
      enabledBorder: field,
      focusedBorder: field,
    ),
    filledButtonTheme: FilledButtonThemeData(
        style: bevel(base.filledButtonTheme.style, filled: true)),
    outlinedButtonTheme:
        OutlinedButtonThemeData(style: bevel(base.outlinedButtonTheme.style)),
    textButtonTheme: TextButtonThemeData(
      style: bevel(base.textButtonTheme.style),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: bevel(base.iconButtonTheme.style).copyWith(
        overlayColor: const WidgetStatePropertyAll(Color(0x1A8866AD)),
      ),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: _pastelPorcelain,
      shape: _PastelSoftBorder(borderRadius: corners),
      elevation: 7,
      shadowColor: _pastelPlateShadow,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: base.popupMenuTheme.copyWith(
      color: _pastelPorcelain,
      shape: _PastelSoftBorder(borderRadius: corners),
      elevation: 5,
      shadowColor: _pastelPlateShadow,
      surfaceTintColor: Colors.transparent,
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: _PastelSoftBorder(borderRadius: corners),
      side: BorderSide.none,
      backgroundColor: _pastelClay,
    ),
    datePickerTheme: base.datePickerTheme.copyWith(
      backgroundColor: _pastelPorcelain,
      shape: _PastelSoftBorder(borderRadius: corners),
      dayShape: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.pressed) ||
                  states.contains(WidgetState.selected)
              ? dayShape
              : shape),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? _pastelLavender : null),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? _pastelPlum : null),
      dayOverlayColor: const WidgetStatePropertyAll(Color(0x198A65AD)),
      todayBorder: BorderSide.none,
      todayForegroundColor: const WidgetStatePropertyAll(_pastelPlum),
    ),
    timePickerTheme: base.timePickerTheme.copyWith(
      shape: _PastelSoftBorder(borderRadius: corners),
      hourMinuteShape: dayShape,
      hourMinuteColor: _pastelLavender,
      hourMinuteTextColor: _pastelPlum,
      dialBackgroundColor: _pastelClay,
      dialHandColor: const Color(0xFFC5AFE0),
      dayPeriodShape: dayShape,
      dayPeriodBorderSide: BorderSide.none,
    ),
    checkboxTheme: base.checkboxTheme.copyWith(side: BorderSide.none),
    drawerTheme: base.drawerTheme.copyWith(shape: shape, endShape: shape),
    snackBarTheme: base.snackBarTheme.copyWith(
      shape: _PastelSoftBorder(borderRadius: corners),
      backgroundColor: _pastelClay,
      contentTextStyle:
          const TextStyle(color: _lightText, fontFamily: _pastelReadingFont),
    ),
    tooltipTheme: base.tooltipTheme.copyWith(
      decoration: BoxDecoration(color: _pastelMauve, borderRadius: corners),
    ),
  );
}

ButtonStyle _pastelButtonBevel(BorderRadius corners, {required bool filled}) =>
    ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: corners),
      ),
      side: const WidgetStatePropertyAll(BorderSide.none),
      elevation: const WidgetStatePropertyAll(0),
      foregroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.disabled)
              ? _pastelPlum.withValues(alpha: .45)
              : _pastelPlum),
      backgroundBuilder: (context, states, child) => _PastelPressFace(
        radius: corners,
        colour: filled
            ? null
            : Theme.of(context).custom(_ThemeColour.panel) ??
                Theme.of(context).colorScheme.surfaceContainer,
        pressed: states.contains(WidgetState.pressed),
        disabled: states.contains(WidgetState.disabled),
        child: child ?? const SizedBox.shrink(),
      ),
    );

Widget _pastelLift(
  ThemeData theme,
  Widget child, {
  Color? colour,
  bool inset = false,
}) {
  if (theme.appearance != AppTheme.pastel) return child;
  final radius = _pastelRadius(theme);
  return DecoratedBox(
    key: const ValueKey('pastel-beveled-surface'),
    decoration: BoxDecoration(
      borderRadius: radius,
      color: colour,
      boxShadow: inset
          ? null
          : [
              BoxShadow(
                color: theme
                        .custom(_ThemeColour.borders)
                        ?.withValues(alpha: .31) ??
                    _pastelPlateShadow,
                blurRadius: 9,
                offset: const Offset(4, 5),
              ),
              const BoxShadow(
                  color: Color(0xC4FFFFFF),
                  blurRadius: 9,
                  offset: Offset(-4, -4)),
            ],
    ),
    child: inset
        ? CustomPaint(
            foregroundPainter: _PastelFacePainter(radius, 1, null),
            child: child,
          )
        : child,
  );
}

Widget _pastelPressable(
  ThemeData theme,
  Widget child, {
  Color? colour,
  bool round = false,
  bool selected = false,
  double seatWidth = 0,
  double restingDepth = 0,
}) {
  if (theme.appearance != AppTheme.pastel) return child;
  return _PastelPointerFace(
    radius: round ? BorderRadius.circular(100) : _pastelRadius(theme),
    colour: colour ?? theme.custom(_ThemeColour.panel) ?? _pastelClay,
    selected: selected,
    seatWidth: seatWidth,
    restingDepth: restingDepth,
    child: child,
  );
}

class _PastelPointerFace extends StatefulWidget {
  const _PastelPointerFace({
    required this.radius,
    required this.colour,
    required this.selected,
    required this.seatWidth,
    required this.restingDepth,
    required this.child,
  });

  final BorderRadius radius;
  final Color colour;
  final bool selected;
  final double seatWidth;
  final double restingDepth;
  final Widget child;

  @override
  State<_PastelPointerFace> createState() => _PastelPointerFaceState();
}

class _PastelPointerFaceState extends State<_PastelPointerFace> {
  int? _pointer;

  void _release(PointerEvent event) {
    if (_pointer == event.pointer) setState(() => _pointer = null);
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (event) {
          if (_pointer == null) setState(() => _pointer = event.pointer);
        },
        onPointerUp: _release,
        onPointerCancel: _release,
        child: _PastelPressFace(
          radius: widget.radius,
          colour: widget.colour,
          seatWidth: widget.seatWidth,
          restingDepth: widget.restingDepth,
          pressed: _pointer != null || widget.selected,
          child: widget.child,
        ),
      );
}

class _PastelPressFace extends StatelessWidget {
  const _PastelPressFace({
    required this.radius,
    required this.colour,
    required this.pressed,
    this.disabled = false,
    this.seatWidth = 0,
    this.restingDepth = 0,
    required this.child,
  });

  final BorderRadius radius;
  final Color? colour;
  final bool pressed;
  final bool disabled;
  final double seatWidth;
  final double restingDepth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (disabled) return child;
    return TweenAnimationBuilder<double>(
      key: const ValueKey('pastel-press-depth'),
      tween: Tween(end: pressed ? 1.0 : restingDepth),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      builder: (context, depth, child) => CustomPaint(
        painter:
            _PastelFacePainter(radius, depth, colour, seatWidth: seatWidth),
        child: Transform.translate(
          key: const ValueKey('pastel-press-travel'),
          offset: Offset(0, reduced ? 0 : (depth - restingDepth) * 1.2),
          transformHitTests: false,
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _PastelFacePainter extends CustomPainter {
  const _PastelFacePainter(this.radius, this.depth, this.colour,
      {this.seatWidth = 0});

  final BorderRadius radius;
  final double depth;
  final Color? colour;
  final double seatWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;
    if (seatWidth > 0) {
      _paintPastelRelief(canvas, bounds, radius, 1, colour);
    }
    _paintPastelRelief(
        canvas, bounds.deflate(seatWidth), radius, depth, colour);
  }

  @override
  bool shouldRepaint(_PastelFacePainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.depth != depth ||
      oldDelegate.seatWidth != seatWidth ||
      oldDelegate.colour != colour;
}

Widget _sidebarEntry(ThemeData theme, Widget child, {required bool hasNext}) {
  if (theme.appearance != AppTheme.pastel) {
    return Padding(padding: const EdgeInsets.only(bottom: 4), child: child);
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      child,
      if (hasNext)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: SizedBox(
            height: 3,
            child: DecoratedBox(
              key: ValueKey('pastel-sidebar-divider'),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(2)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x3576658B),
                    Color(0x0F76658B),
                    Color(0x91FFFFFF)
                  ],
                  stops: [0, .52, 1],
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

Widget _pastelChecklistProgress(ThemeData theme, double value) {
  const radius = BorderRadius.all(Radius.circular(100));
  final green = theme.custom(_ThemeColour.panel) ?? _pastelCompletedTaskSurface;
  return Semantics(
    value: '${(value * 100).round()}%',
    child: SizedBox(
      height: 10,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          const CustomPaint(
            key: ValueKey('pastel-progress-track'),
            painter: _PastelFacePainter(radius, 1, null),
          ),
          if (value > 0)
            FractionallySizedBox(
              widthFactor: value,
              alignment: AlignmentDirectional.centerStart,
              child: DecoratedBox(
                key: const ValueKey('pastel-progress-fill'),
                decoration: BoxDecoration(color: green, borderRadius: radius),
                child: const CustomPaint(
                  foregroundPainter: _PastelFacePainter(radius, 0, null),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

void _paintPastelRelief(Canvas canvas, Rect bounds, BorderRadius radius,
    double depth, Color? face) {
  final contour = radius.toRRect(bounds).scaleRadii();
  final height = 1 - depth;
  final dark = _pastelPlateShadow;
  if (height > 0) {
    canvas.save();
    canvas.clipPath(Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(bounds.inflate(14))
      ..addRRect(contour));
    final haze = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(
      contour.shift(Offset(3 * height, 4 * height)),
      haze..color = dark.withValues(alpha: .34 * height),
    );
    canvas.drawRRect(
      contour.shift(Offset(-3 * height, -4 * height)),
      haze..color = Colors.white.withValues(alpha: .88 * height),
    );
    canvas.restore();
  }
  if (face != null) canvas.drawRRect(contour, Paint()..color = face);
  canvas.save();
  canvas.clipRRect(contour);
  final rim = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3 + depth * 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
  final shift = ui.lerpDouble(-1.8, 2.5, depth)!;
  canvas.drawRRect(
    contour.shift(Offset(shift, shift)),
    rim..color = dark.withValues(alpha: .19 + depth * .18),
  );
  canvas.drawRRect(
    contour.shift(Offset(-shift, -shift)),
    rim..color = Colors.white.withValues(alpha: .64),
  );
  canvas.restore();
}

class _PastelSoftBorder extends RoundedRectangleBorder {
  const _PastelSoftBorder({required super.borderRadius, this.recessed = false})
      : super(side: BorderSide.none);

  final bool recessed;

  @override
  _PastelSoftBorder copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
  }) =>
      _PastelSoftBorder(
          borderRadius: borderRadius ?? this.borderRadius, recessed: recessed);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (rect.isEmpty) return;
    _paintPastelRelief(
      canvas,
      rect,
      borderRadius.resolve(textDirection),
      recessed ? 1 : .12,
      null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _PastelSoftBorder &&
      other.borderRadius == borderRadius &&
      other.recessed == recessed;

  @override
  int get hashCode => Object.hash(borderRadius, recessed);
}

class _PastelInsetField extends OutlineInputBorder {
  const _PastelInsetField({required super.borderRadius})
      : super(borderSide: BorderSide.none);

  @override
  _PastelInsetField copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
  }) =>
      _PastelInsetField(borderRadius: borderRadius ?? this.borderRadius);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0,
    double gapPercentage = 0,
    TextDirection? textDirection,
  }) {
    if (!rect.isEmpty) _paintPastelRelief(canvas, rect, borderRadius, 1, null);
  }
}

class _PastelBackdrop extends StatelessWidget {
  const _PastelBackdrop(this.background);

  final Color background;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(background, _pastelClay, .94)!,
              Color.lerp(background, _pastelPorcelain, .94)!,
              Color.lerp(background, _pastelRose, .89)!,
            ],
            stops: const [0, .49, 1],
          ),
        ),
        child: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(.93, -.60),
              radius: .75,
              colors: [Color(0x4BD4DEF3), Color(0x00D4DEF3)],
            ),
          ),
        ),
      );
}
