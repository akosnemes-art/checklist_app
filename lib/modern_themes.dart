part of 'main.dart';

const _pixelFont = 'Pixelify Sans';

class _ModernPalette {
  const _ModernPalette({
    required this.background,
    required this.panel,
    required this.checklistSidebar,
    required this.notesSidebar,
    required this.ink,
    required this.border,
    required this.checklistAccent,
    required this.notesAccent,
    required this.buttonInk,
    required this.priorities,
  });

  final Color background;
  final Color panel;
  final Color checklistSidebar;
  final Color notesSidebar;
  final Color ink;
  final Color border;
  final Color checklistAccent;
  final Color notesAccent;
  final Color buttonInk;
  final List<Color> priorities;

  Color sidebar(bool notes) => notes ? notesSidebar : checklistSidebar;
  Color accent(bool notes) => notes ? notesAccent : checklistAccent;
}

const _pixelPalette = _ModernPalette(
  background: Color(0xFF060C09),
  panel: Color(0xFF0E1912),
  checklistSidebar: Color(0xFF101F15),
  notesSidebar: Color(0xFF0D2321),
  ink: Color(0xFFD9FFDF),
  border: Color(0xFF46865A),
  checklistAccent: Color(0xFFA9FF42),
  notesAccent: Color(0xFF51F5CA),
  buttonInk: Color(0xFF101A0D),
  priorities: [Color(0xFF58DDAA), Color(0xFFA9FF42), Color(0xFFFFCF61)],
);

const _glassPalette = _ModernPalette(
  background: Color(0xFFE4ECFB),
  panel: Color(0xB8F9FCFF),
  checklistSidebar: Color(0x61F3FAFF),
  notesSidebar: Color(0x62F2EDFF),
  ink: Color(0xFF192641),
  border: Color(0xFF6B7AA1),
  checklistAccent: Color(0xFF2257A0),
  notesAccent: Color(0xFF644595),
  buttonInk: Color(0xFFF8FAFF),
  priorities: [Color(0xFF356987), Color(0xFF4F55AD), Color(0xFF8B3C75)],
);

ThemeData _buildModernTheme(
  ThemeData base,
  _ModernPalette palette, {
  required bool notes,
  required bool pixel,
}) {
  final accent = palette.accent(notes);
  final scheme = base.colorScheme.copyWith(
    primary: accent,
    onPrimary: palette.buttonInk,
    secondary: palette.accent(!notes),
    surface: palette.panel,
    onSurface: palette.ink,
    outline: palette.border,
  );
  final text = base.textTheme.apply(
    bodyColor: palette.ink,
    displayColor: palette.ink,
    fontFamily: pixel ? _pixelFont : null,
    fontFamilyFallback: pixel ? const ['sans-serif'] : null,
  );
  final outline = OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: palette.border),
  );
  final button = ButtonStyle(
    shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
    side: WidgetStatePropertyAll(BorderSide(color: palette.border)),
  );
  final frame = RoundedRectangleBorder(
    side: BorderSide(color: palette.border, width: 2),
  );
  final popup = pixel ? palette.panel : const Color(0xFFF0F3FC);
  return base.copyWith(
    scaffoldBackgroundColor: palette.background,
    colorScheme: scheme,
    dividerColor: palette.border,
    textTheme: text,
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      fillColor: palette.panel,
      border: outline,
      enabledBorder: outline,
      focusedBorder: outline.copyWith(borderSide: BorderSide(color: accent)),
    ),
    filledButtonTheme: FilledButtonThemeData(style: button),
    outlinedButtonTheme: OutlinedButtonThemeData(style: button),
    textButtonTheme: TextButtonThemeData(style: button),
    iconButtonTheme: IconButtonThemeData(style: button),
    dialogTheme: DialogThemeData(backgroundColor: popup, shape: frame),
    popupMenuTheme: PopupMenuThemeData(color: popup, shape: frame),
    chipTheme: base.chipTheme.copyWith(side: BorderSide(color: palette.border)),
    tooltipTheme: base.tooltipTheme.copyWith(
      decoration: BoxDecoration(color: popup),
      textStyle: TextStyle(color: palette.ink, fontSize: 12),
    ),
  );
}

class _AppearanceBackdrop extends StatelessWidget {
  const _AppearanceBackdrop({required this.child, this.lens = false});

  final Widget child;
  final bool lens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appearance = theme.appearance;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (appearance == AppTheme.glass)
          Positioned.fill(
            child: RepaintBoundary(
              child: _GlassWallpaper(
                background: theme.scaffoldBackgroundColor,
                lens:
                    MediaQuery.highContrastOf(context) ? 0 : (lens ? 1 : 0.28),
              ),
            ),
          ),
        if (appearance == AppTheme.pixel && !lens)
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _PixelScanlines()),
            ),
          ),
        KeyedSubtree(
            key: const ValueKey('appearance-panel-child'), child: child),
      ],
    );
  }
}

class _PixelScanlines extends CustomPainter {
  const _PixelScanlines();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x092AFF59);
    for (var y = 1.0; y < size.height; y += 5) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_PixelScanlines oldDelegate) => false;
}

class _GlassWallpaper extends StatefulWidget {
  const _GlassWallpaper({required this.background, required this.lens});

  final Color background;
  final double lens;

  @override
  State<_GlassWallpaper> createState() => _GlassWallpaperState();
}

class _GlassWallpaperState extends State<_GlassWallpaper> {
  static Future<ui.FragmentProgram>? _program;
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await (_program ??=
          ui.FragmentProgram.fromAsset('shaders/glass.frag'));
      if (mounted) setState(() => _shader = program.fragmentShader());
    } catch (error) {
      debugPrint('Glass shader unavailable: $error');
    }
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
        key: const ValueKey('glass-wallpaper'),
        painter: _GlassRefraction(_shader, widget.background, widget.lens),
      );
}

class _GlassRefraction extends CustomPainter {
  _GlassRefraction(this.shader, this.background, this.lens);

  final ui.FragmentShader? shader;
  final Color background;
  final double lens;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint();
    const cool = Color(0xFFABCDF2);
    const warm = Color(0xFFCEB8EE);
    final bounds = Offset.zero & size;
    if (shader case final effect?) {
      effect.setFloat(0, size.width);
      effect.setFloat(1, size.height);
      var index = 2;
      for (final colour in [background, cool, warm]) {
        effect.setFloat(index++, colour.r);
        effect.setFloat(index++, colour.g);
        effect.setFloat(index++, colour.b);
      }
      effect.setFloat(index, lens);
      paint.shader = effect;
    } else {
      paint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(background, cool, 0.55)!,
          Color.lerp(background, warm, 0.35)!
        ],
      ).createShader(bounds);
    }
    canvas.drawRect(bounds, paint);
  }

  @override
  bool shouldRepaint(_GlassRefraction oldDelegate) =>
      oldDelegate.shader != shader ||
      oldDelegate.background != background ||
      oldDelegate.lens != lens;
}
