part of 'main.dart';

const _svWood = Color(0xFF764330);
const _svInk = Color(0xFF422A22);
const _svButtonFont = 'Press Start 2P';
const _svTextFont = 'VT323';
const _svFrameSide = BorderSide(color: _svWood, width: 2);
const _svPalette = _ModernPalette(
  background: Color(0xFFD1E7D3),
  panel: Color(0xFFFFE8BB),
  checklistSidebar: Color(0xFFF3D19B),
  notesSidebar: Color(0xFFF6DCB0),
  ink: _svInk,
  border: _svWood,
  checklistAccent: Color(0xFF426438),
  notesAccent: Color(0xFF305F71),
  buttonInk: _svInk,
  priorities: [Color(0xFF3D6776), Color(0xFF506632), Color(0xFF943F4B)],
);
const _svOchre = Color(0xFFE5A867);
const _svPaper = Color(0xFFFFECC8);
const _svCheckPanel = Color(0xFFE7EDBA);

ThemeData _buildSvTheme(ThemeData light, {required bool notes}) {
  final base = _buildModernTheme(light, _svPalette, notes: notes, pixel: false);
  final typography = base.textTheme.apply(
    fontFamily: _svTextFont,
    fontFamilyFallback: const [_pastelReadingFont, 'sans-serif'],
  );
  const frame = _SvFrame();
  const buttonStyle = ButtonStyle(
    foregroundColor: WidgetStatePropertyAll(_svInk),
    backgroundColor: WidgetStatePropertyAll(_svOchre),
    shape: WidgetStatePropertyAll(frame),
    side: WidgetStatePropertyAll(_svFrameSide),
    elevation: WidgetStatePropertyAll(0),
  );
  final field = base.inputDecorationTheme;
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      onPrimary: _svPaper,
      onSurfaceVariant: const Color(0xFF5E4737),
      surfaceContainer: _svPaper,
    ),
    textTheme: typography.copyWith(
      titleLarge: typography.titleLarge?.copyWith(fontSize: 25),
      bodyLarge: typography.bodyLarge?.copyWith(fontSize: 19),
      bodyMedium: typography.bodyMedium?.copyWith(fontSize: 17),
      bodySmall: typography.bodySmall?.copyWith(fontSize: 14),
    ),
    filledButtonTheme: const FilledButtonThemeData(style: buttonStyle),
    outlinedButtonTheme: const OutlinedButtonThemeData(style: buttonStyle),
    textButtonTheme: const TextButtonThemeData(style: buttonStyle),
    iconButtonTheme: const IconButtonThemeData(style: buttonStyle),
    inputDecorationTheme: field.copyWith(
      hintStyle: const TextStyle(color: Color(0xFF6C5041)),
    ),
    checkboxTheme: const CheckboxThemeData(
      checkColor: WidgetStatePropertyAll(_svPaper),
      shape: RoundedRectangleBorder(),
      side: _svFrameSide,
    ),
    dialogTheme: base.dialogTheme.copyWith(
      shape: frame,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: base.popupMenuTheme.copyWith(
      shape: frame,
      surfaceTintColor: Colors.transparent,
    ),
    timePickerTheme: base.timePickerTheme.copyWith(shape: frame),
    tooltipTheme: base.tooltipTheme.copyWith(
      decoration: const ShapeDecoration(color: _svPaper, shape: frame),
    ),
  );
}

Color _svControlFace(ThemeData theme, {bool selected = false}) =>
    selected ? _svCheckPanel : theme.custom(_ThemeColour.buttons) ?? _svOchre;

_SvFrame _svControlFrame(ThemeData theme) =>
    _SvFrame(side: BorderSide(color: theme.colorScheme.outline, width: 2));

Color _svControlInk(ThemeData theme, {bool selected = false}) =>
    theme.custom(_ThemeColour.buttons) == null || selected
        ? _svInk
        : _contrastingInk(_svControlFace(theme));

ButtonStyle _svNoteButtonStyle(ThemeData theme, {bool selected = false}) {
  final frame = _svControlFrame(theme);
  return IconButton.styleFrom(
    backgroundColor: _svControlFace(theme, selected: selected),
    foregroundColor: _svControlInk(theme, selected: selected),
    shape: frame,
    side: frame.side,
  );
}

class _SvFrame extends RoundedRectangleBorder {
  const _SvFrame({super.side = _svFrameSide});

  @override
  _SvFrame copyWith({BorderSide? side, BorderRadiusGeometry? borderRadius}) =>
      _SvFrame(side: side ?? this.side);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    super.paint(canvas, rect, textDirection: textDirection);
    if (rect.shortestSide < 10) return;
    final edge = rect.deflate(side.width + 1);
    final trim = Paint()..strokeWidth = 2;
    canvas.drawLine(
        edge.topLeft, edge.topRight, trim..color = const Color(0xFFFFDEA4));
    canvas.drawLine(edge.topLeft, edge.bottomLeft, trim);
    canvas.drawLine(edge.bottomLeft, edge.bottomRight,
        trim..color = const Color(0xFFB87A51));
    canvas.drawLine(edge.topRight, edge.bottomRight, trim);
  }
}

Widget _taskSurface(ThemeData theme, Widget child, {required bool completed}) {
  final panel = theme.custom(_ThemeColour.panel);
  if (theme.appearance == AppTheme.sv) {
    return DecoratedBox(
      key: const ValueKey('sv-task-card'),
      decoration: ShapeDecoration(
        color: panel ?? (completed ? _svCheckPanel : _svPaper),
        shape: _SvFrame(
            side: BorderSide(color: theme.colorScheme.outline, width: 2)),
        shadows: const [
          BoxShadow(color: Color(0x44764230), offset: Offset(2, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: child,
      ),
    );
  }
  return _pastelLift(theme, child, colour: panel);
}

class _SvLandscape extends CustomPainter {
  const _SvLandscape(this.sky);
  final Color sky;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      paint
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(sky, const Color(0xFFB9DDE4), .45)!,
            sky,
            const Color(0xFFF6E1B1)
          ],
          stops: const [0, .52, 1],
        ).createShader(bounds),
    );
    paint.shader = null;
    final pixel = (size.width / 76).clamp(3.0, 8.0).floorToDouble();
    // Stepped field banks, drawn at a fixed pixel scale across screen widths.
    for (var layer = 0; layer < 3; layer++) {
      paint.color = [
        const Color(0xFFABC694),
        const Color(0xFFA8BD78),
        const Color(0xFFBBC78A),
      ][layer];
      final horizon = size.height * (.73 + layer * .075);
      for (var x = 0.0; x < size.width; x += pixel) {
        final wave =
            math.sin(x / size.width * 6.7 + layer * 1.9) * size.height * .048;
        final top = ((horizon + wave) / pixel).round() * pixel;
        canvas.drawRect(Rect.fromLTWH(x, top, pixel, size.height - top), paint);
      }
    }
    final random = math.Random(628);
    for (var i = 0; i < 65; i++) {
      final x = (random.nextDouble() * size.width / pixel).floor() * pixel;
      final y =
          (((.88 + random.nextDouble() * .12) * size.height) / pixel).floor() *
              pixel;
      paint.color =
          i % 6 == 0 ? const Color(0xFFECDC9D) : const Color(0x27849450);
      canvas.drawRect(Rect.fromLTWH(x, y, pixel, pixel / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_SvLandscape oldDelegate) => oldDelegate.sky != sky;
}
