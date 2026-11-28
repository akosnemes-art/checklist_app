part of 'main.dart';

const _milkFont = 'Manrope';
const _milkThemeLabel = 'Blue milk';
const _pastelReadingFont = 'Nunito';
const _defaultPastelCorner = 18.0;
const _milkBackground = Color(0xFFE8FDF6);
const _milkTaskHint = Color(0xFF899095);
const _milkInk = Color(0xFF324256);
const _pastelMutedInk = Color(0xFF536479);
const _pastelPlum = Color(0xFF52378B);
const _pastelLavender = Color(0xFFE4DBF7);
const _milkLine = Color(0xFFC4D0DC);
const _milkFocusInk = Color(0xFF7655B0);
const _milkShade = Color(0xFFA3B1BF);
const _milkLight = Color(0xFFFFFFFF);
const _milkAccentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF9C72ED), Color(0xFFAF96F4)],
);
const _milkCardShadows = [
  BoxShadow(color: Color(0x47A3B1BF), offset: Offset(7, 7), blurRadius: 15),
  BoxShadow(color: Color(0xE6FFFFFF), offset: Offset(-7, -7), blurRadius: 15),
];
const _milkSmallShadows = [
  BoxShadow(color: Color(0x4DA3B1BF), offset: Offset(4, 4), blurRadius: 9),
  BoxShadow(color: Color(0xE6FFFFFF), offset: Offset(-4, -4), blurRadius: 9),
];

Color _pastelSecondaryInk(ThemeData theme) =>
    theme.custom(_ThemeColour.text) ?? _pastelMutedInk;

Color _pastelAccentInk(Color colour) {
  final luminanceLimit = (_milkBackground.computeLuminance() + .05) / 4.5 - .05;
  if (colour.computeLuminance() <= luminanceLimit) return colour;
  final shaded = Color.lerp(colour, _milkInk, .55)!;
  return shaded.computeLuminance() <= luminanceLimit
      ? shaded
      : Color.lerp(shaded, _milkInk, .60)!;
}

Color _editorHintInk(ThemeData theme) => theme.appearance == AppTheme.pastel
    ? _pastelSecondaryInk(theme)
    : _switchGrey;

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
          style: ButtonStyle(
            side: WidgetStatePropertyAll(BorderSide.none),
            backgroundBuilder: _plainButtonFace,
            backgroundColor: WidgetStatePropertyAll(Colors.transparent),
          ),
        ),
        child: button,
      ),
    ),
  );
}

Widget _plainButtonFace(
        BuildContext context, Set<WidgetState> states, Widget? child) =>
    child ?? const SizedBox.shrink();

ThemeData _buildPastelFinish(ThemeData base, double radius) {
  final corners = BorderRadius.circular(radius);
  final shape = RoundedRectangleBorder(borderRadius: corners);
  final fields = base.inputDecorationTheme;
  final field = _PastelInsetField(borderRadius: corners);
  final fonts = base.textTheme.apply(
    fontFamily: _milkFont,
    fontFamilyFallback: const [_pastelReadingFont, 'Roboto', 'sans-serif'],
    displayColor: _milkInk,
    bodyColor: _milkInk,
  );
  TextStyle? heading(TextStyle? style) => style?.copyWith(
        fontWeight: FontWeight.w600,
        fontVariations: const [ui.FontVariation('wght', 600)],
      );
  ButtonStyle bevel(ButtonStyle? original, {bool capsule = false}) =>
      _pastelButtonBevel(capsule ? BorderRadius.circular(100) : corners,
              filled: capsule)
          .merge(original);
  final dayShape = _PastelSoftBorder(
      borderRadius: BorderRadius.circular(radius * .72), recessed: true);

  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      onPrimary: _pastelPlum,
      onSurfaceVariant: _pastelMutedInk,
      surfaceContainer: _milkBackground,
    ),
    iconTheme: const IconThemeData(color: _pastelMutedInk, size: 20),
    textTheme: fonts.copyWith(
      headlineLarge: heading(fonts.headlineLarge),
      headlineMedium: heading(fonts.headlineMedium),
      headlineSmall: heading(fonts.headlineSmall),
      titleLarge: heading(fonts.titleLarge),
    ),
    inputDecorationTheme: fields.copyWith(
      border: field,
      enabledBorder: field,
      focusedBorder: _PastelInsetField(borderRadius: corners, focused: true),
      hintStyle: const TextStyle(color: _pastelMutedInk),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
        style: bevel(base.filledButtonTheme.style, capsule: true)),
    outlinedButtonTheme:
        OutlinedButtonThemeData(style: bevel(base.outlinedButtonTheme.style)),
    textButtonTheme: TextButtonThemeData(
      style: bevel(base.textButtonTheme.style),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: _pastelButtonBevel(BorderRadius.circular(100), filled: false)
          .merge(base.iconButtonTheme.style)
          .copyWith(
            overlayColor: const WidgetStatePropertyAll(Color(0x1A8866AD)),
          ),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: _milkBackground,
      shape: _PastelSoftBorder(borderRadius: corners),
      elevation: 7,
      shadowColor: const Color(0x59A3B1BF),
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: base.popupMenuTheme.copyWith(
      color: _milkBackground,
      shape: _PastelSoftBorder(borderRadius: corners),
      menuPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      elevation: 5,
      shadowColor: const Color(0x47A3B1BF),
      surfaceTintColor: Colors.transparent,
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: _PastelSoftBorder(borderRadius: corners),
      side: BorderSide.none,
      backgroundColor: _milkBackground,
    ),
    datePickerTheme: base.datePickerTheme.copyWith(
      backgroundColor: _milkBackground,
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
      dialBackgroundColor: _milkBackground,
      dialHandColor: const Color(0xFFC5AFE0),
      dayPeriodShape: dayShape,
      dayPeriodBorderSide: BorderSide.none,
    ),
    checkboxTheme: base.checkboxTheme.copyWith(side: BorderSide.none),
    drawerTheme: base.drawerTheme.copyWith(shape: shape, endShape: shape),
    snackBarTheme: base.snackBarTheme.copyWith(
      shape: _PastelSoftBorder(borderRadius: corners),
      backgroundColor: _milkBackground,
      contentTextStyle: const TextStyle(color: _milkInk, fontFamily: _milkFont),
    ),
    tooltipTheme: base.tooltipTheme.copyWith(
      decoration: BoxDecoration(color: _milkLine, borderRadius: corners),
    ),
  );
}

ButtonStyle _pastelButtonBevel(BorderRadius corners, {required bool filled}) =>
    ButtonStyle(
      shape:
          WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: corners)),
      side: const WidgetStatePropertyAll(BorderSide.none),
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.disabled)
              ? const Color(0xFFE4EBF2)
              : _milkBackground),
      foregroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.disabled)
              ? _pastelMutedInk.withValues(alpha: .58)
              : _pastelMutedInk),
      backgroundBuilder: (context, states, child) => _PastelPointerFace(
        radius: corners,
        colour: filled
            ? null
            : states.contains(WidgetState.selected)
                ? _pastelLavender
                : Theme.of(context).custom(_ThemeColour.panel) ??
                    _milkBackground,
        held: states.contains(WidgetState.pressed),
        hovered: states.contains(WidgetState.hovered),
        focused: states.contains(WidgetState.focused),
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
      color: colour ?? _milkBackground,
      boxShadow: inset ? null : _milkCardShadows,
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
  bool held = false,
  bool flatAtRest = false,
}) {
  if (theme.appearance != AppTheme.pastel) return child;
  return _PastelPointerFace(
    radius: round ? BorderRadius.circular(100) : _pastelRadius(theme),
    colour: flatAtRest
        ? null
        : colour ?? theme.custom(_ThemeColour.panel) ?? _milkBackground,
    held: held,
    flatAtRest: flatAtRest,
    child: child,
  );
}

class _PastelPointerFace extends StatefulWidget {
  const _PastelPointerFace({
    required this.radius,
    required this.colour,
    this.held = false,
    this.hovered = false,
    this.focused = false,
    this.disabled = false,
    this.flatAtRest = false,
    required this.child,
  });

  final BorderRadius radius;
  final Color? colour;
  final bool held;
  final bool hovered;
  final bool focused;
  final bool disabled;
  final bool flatAtRest;
  final Widget child;

  @override
  State<_PastelPointerFace> createState() => _PastelPointerFaceState();
}

class _PastelPointerFaceState extends State<_PastelPointerFace> {
  int? _pointer;
  Timer? _releaseTimer;
  Duration _pressedAt = Duration.zero;
  bool _pressed = false;

  void _release(PointerEvent event) {
    if (_pointer != event.pointer) return;
    _pointer = null;
    final remaining =
        const Duration(milliseconds: 120) - (event.timeStamp - _pressedAt);
    if (event is PointerCancelEvent ||
        remaining <= Duration.zero ||
        MediaQuery.disableAnimationsOf(context)) {
      setState(() => _pressed = false);
      return;
    }
    _releaseTimer = Timer(remaining, () => setState(() => _pressed = false));
  }

  @override
  void dispose() {
    _releaseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          if (_pointer != null || widget.disabled) return;
          _releaseTimer?.cancel();
          _pointer = event.pointer;
          _pressedAt = event.timeStamp;
          setState(() => _pressed = true);
        },
        onPointerUp: _release,
        onPointerCancel: _release,
        child: _PastelPressFace(
          radius: widget.radius,
          colour: widget.colour,
          pressed: _pressed || widget.held,
          hovered: widget.hovered,
          focused: widget.focused,
          disabled: widget.disabled,
          flatAtRest: widget.flatAtRest,
          child: widget.child,
        ),
      );
}

class _PastelPressFace extends StatelessWidget {
  const _PastelPressFace({
    required this.radius,
    required this.colour,
    required this.pressed,
    this.hovered = false,
    this.focused = false,
    this.disabled = false,
    this.flatAtRest = false,
    this.restingDepth = 0,
    required this.child,
  });

  final BorderRadius radius;
  final Color? colour;
  final bool pressed;
  final bool hovered;
  final bool focused;
  final bool disabled;
  final bool flatAtRest;
  final double restingDepth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (disabled) return child;
    return TweenAnimationBuilder<double>(
      key: const ValueKey('pastel-press-depth'),
      tween: Tween(
          end: pressed
              ? 1.0
              : hovered
                  ? -.12
                  : restingDepth),
      duration: reduced
          ? Duration.zero
          : Duration(milliseconds: hovered && !pressed ? 150 : 120),
      curve: Curves.easeInOut,
      builder: (context, depth, child) => CustomPaint(
        painter: _PastelFacePainter(radius, depth, colour,
            focused: focused, flatAtRest: flatAtRest),
        child: Transform.translate(
          key: const ValueKey('pastel-press-travel'),
          offset: Offset(
              0, reduced ? 0 : (depth - restingDepth).clamp(0.0, 1.0) * 1.2),
          transformHitTests: false,
          child: Transform.scale(
            scale: reduced ? 1 : 1 - .02 * depth.clamp(0.0, 1.0),
            transformHitTests: false,
            child: child,
          ),
        ),
      ),
      child: child,
    );
  }
}

class _PastelFacePainter extends CustomPainter {
  const _PastelFacePainter(this.radius, this.depth, this.colour,
      {this.focused = false, this.flatAtRest = false});

  final BorderRadius radius;
  final double depth;
  final Color? colour;
  final bool focused;
  final bool flatAtRest;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;
    _paintPastelRelief(canvas, bounds, radius, depth, colour,
        raised: !flatAtRest);
    if (focused) _paintMilkFocus(canvas, bounds, radius);
  }

  @override
  bool shouldRepaint(_PastelFacePainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.depth != depth ||
      oldDelegate.focused != focused ||
      oldDelegate.flatAtRest != flatAtRest ||
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
          child: _MilkSidebarDivider(key: ValueKey('pastel-sidebar-divider')),
        ),
    ],
  );
}

class _MilkSidebarDivider extends StatelessWidget {
  const _MilkSidebarDivider({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: double.infinity,
        height: 3,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(2)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x5551677B),
                Color(0x1851677B),
                Color(0x65F7FAFC),
              ],
              stops: [0, .52, 1],
            ),
          ),
        ),
      );
}

class _MilkJug extends CustomPainter {
  const _MilkJug(this.colour);

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 18;
    canvas.scale(scale);
    final ink = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final jug = Path()
      ..moveTo(3, 2.5)
      ..lineTo(12.5, 2.5)
      ..lineTo(10.8, 5.7)
      ..quadraticBezierTo(13, 8, 13, 11)
      ..lineTo(13, 13.5)
      ..quadraticBezierTo(13, 16, 10.5, 16)
      ..lineTo(5, 16)
      ..quadraticBezierTo(2.5, 16, 2.5, 13.5)
      ..lineTo(2.5, 10.8)
      ..quadraticBezierTo(2.5, 8, 4.9, 5.7)
      ..close();
    final handle = Path()
      ..moveTo(12.6, 8)
      ..lineTo(14.8, 8)
      ..quadraticBezierTo(17, 8, 17, 10.4)
      ..quadraticBezierTo(17, 12.6, 14.8, 13)
      ..lineTo(13, 13);
    canvas.drawPath(jug, ink);
    canvas.drawPath(handle, ink);
    canvas.drawLine(const Offset(5, 6), const Offset(10.8, 6), ink);
  }

  @override
  bool shouldRepaint(_MilkJug oldDelegate) => colour != oldDelegate.colour;
}

Widget _pastelChecklistProgress(ThemeData theme, double value) {
  const radius = BorderRadius.all(Radius.circular(100));
  final accent = theme.custom(_ThemeColour.checklistAccent);
  return Semantics(
    value: '${(value * 100).round()}%',
    child: SizedBox(
      height: 10,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(
              key: ValueKey('pastel-progress-track'),
              painter: _PastelFacePainter(radius, 1, _milkBackground),
            ),
            if (value > 0)
              FractionallySizedBox(
                widthFactor: value,
                alignment: AlignmentDirectional.centerStart,
                child: DecoratedBox(
                  key: const ValueKey('pastel-progress-fill'),
                  decoration: BoxDecoration(
                    color: accent,
                    gradient: accent == null ? _milkAccentGradient : null,
                    borderRadius: radius,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

void _paintPastelRelief(
    Canvas canvas, Rect bounds, BorderRadius radius, double depth, Color? face,
    {bool raised = true}) {
  if (bounds.isEmpty) return;
  final contour = radius.toRRect(bounds).scaleRadii();
  final lift = 1 - depth;
  if (raised && lift > 0) {
    canvas.save();
    if (face == null) {
      canvas.clipPath(Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(bounds.inflate(20))
        ..addRRect(contour));
    }
    for (final shadow in _milkSmallShadows) {
      final ink = shadow.toPaint()
        ..color = shadow.color
            .withValues(alpha: shadow.color.a * lift.clamp(0.0, 1.0));
      canvas.drawRRect(contour.shift(shadow.offset * lift), ink);
    }
    canvas.restore();
  }
  if (face != null) canvas.drawRRect(contour, Paint()..color = face);
  if (depth <= 0) return;

  canvas.save();
  canvas.clipRRect(contour);
  final shift = Offset(4, 4) * depth;
  final shadow = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
  void inset(Offset offset, Color colour, double opacity) {
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(bounds.inflate(24))
      ..addRRect(contour.shift(offset));
    canvas.drawPath(
        outside, shadow..color = colour.withValues(alpha: opacity * depth));
  }

  inset(shift, _milkShade, .43);
  inset(-shift, _milkLight, .90);
  canvas.restore();
}

void _paintMilkFocus(Canvas canvas, Rect bounds, BorderRadius radius) {
  if (bounds.width < 4 || bounds.height < 4) return;
  canvas.drawRRect(
    radius.toRRect(bounds.deflate(1)).scaleRadii(),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _milkFocusInk,
  );
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
  const _PastelInsetField({required super.borderRadius, this.focused = false})
      : super(borderSide: BorderSide.none);

  final bool focused;

  @override
  _PastelInsetField copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
  }) =>
      _PastelInsetField(
        borderRadius: borderRadius ?? this.borderRadius,
        focused: focused,
      );

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0,
    double gapPercentage = 0,
    TextDirection? textDirection,
  }) {
    _paintPastelRelief(canvas, rect, borderRadius, 1, null);
    if (focused) _paintMilkFocus(canvas, rect, borderRadius);
  }

  @override
  bool operator ==(Object other) =>
      other is _PastelInsetField && super == other && focused == other.focused;

  @override
  int get hashCode => Object.hash(super.hashCode, focused);
}

class _PastelBackdrop extends StatelessWidget {
  const _PastelBackdrop(this.background);

  final Color background;

  @override
  Widget build(BuildContext context) => ColoredBox(color: background);
}
