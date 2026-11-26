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
  final popup = palette.panel;
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
  const _AppearanceBackdrop({
    required this.child,
    this.sidebar = false,
  });

  final Widget child;
  final bool sidebar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appearance = theme.appearance;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (appearance == AppTheme.cyberpunk)
          Positioned.fill(
            child: RepaintBoundary(child: _CyberpunkBackdrop(sidebar: sidebar)),
          ),
        if (appearance == AppTheme.pixel && !sidebar)
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _PixelScanlines()),
            ),
          ),
        if (appearance == AppTheme.pixel &&
            !sidebar &&
            !MediaQuery.disableAnimationsOf(context))
          const Positioned.fill(
            child: IgnorePointer(child: RepaintBoundary(child: _PixelNoise())),
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
