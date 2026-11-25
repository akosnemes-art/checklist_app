part of 'main.dart';

const _metalSerif = 'serif';
const _blackMetalMedium = Color(0xFF492453);
const _blackMetalMediumLabel = Color(0xFFE2C4EE);

class _MetalPalette {
  const _MetalPalette({
    required this.background,
    required this.surface,
    required this.checklistSidebar,
    required this.notesSidebar,
    required this.ink,
    required this.muted,
    required this.checklistAccent,
    required this.notesAccent,
    required this.line,
    required this.checklistButton,
    required this.notesButton,
  });

  final Color background;
  final Color surface;
  final Color checklistSidebar;
  final Color notesSidebar;
  final Color ink;
  final Color muted;
  final Color checklistAccent;
  final Color notesAccent;
  final Color line;
  final Color checklistButton;
  final Color notesButton;

  Color sidebar(bool notesActive) =>
      notesActive ? notesSidebar : checklistSidebar;
  Color button(bool notesActive) => notesActive ? notesButton : checklistButton;
}

const _copperPalette = _MetalPalette(
  background: Color(0xFF100D10),
  surface: Color(0xFF1B161B),
  checklistSidebar: Color(0xFF24161D),
  notesSidebar: Color(0xFF201925),
  ink: Color(0xFFF3E8DC),
  muted: Color(0xFFAA98A5),
  checklistAccent: Color(0xFFD6B583),
  notesAccent: Color(0xFFDA9EA9),
  line: Color(0xFF785A69),
  checklistButton: Color(0xFF492A35),
  notesButton: Color(0xFF3D2D43),
);

const _blackMetalPalette = _MetalPalette(
  background: Color(0xFF09090C),
  surface: Color(0xFF131216),
  checklistSidebar: Color(0xFF211217),
  notesSidebar: Color(0xFF18191F),
  ink: Color(0xFFECE9E8),
  muted: Color(0xFFA8A4AF),
  checklistAccent: Color(0xFFDA7781),
  notesAccent: Color(0xFFBDC8D3),
  line: Color(0xFF75505A),
  checklistButton: Color(0xFF751823),
  notesButton: Color(0xFF66121D),
);

extension _MetalAppearance on ThemeData {
  bool get isBlackMetal => appearance == AppTheme.blackMetal;

  _MetalPalette? get metalPalette {
    if (appearance == AppTheme.copper) {
      return _copperPalette;
    }
    if (isBlackMetal) {
      return _blackMetalPalette;
    }
    return null;
  }
}

ThemeData _buildMetalTheme(
  ThemeData base,
  _MetalPalette palette, {
  required bool notesActive,
}) {
  final accent = notesActive ? palette.notesAccent : palette.checklistAccent;
  final blackMetal = identical(palette, _blackMetalPalette);
  final controlAccent = blackMetal ? palette.checklistAccent : accent;
  final frame = RoundedRectangleBorder(
    side: BorderSide(color: palette.checklistAccent, width: 2),
  );
  final outline = OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: palette.line),
  );
  final titles =
      base.textTheme.apply(bodyColor: palette.ink, displayColor: palette.ink);
  final button = ButtonStyle(
    shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
    side: WidgetStatePropertyAll(BorderSide(color: controlAccent, width: 2)),
  );
  return base.copyWith(
    scaffoldBackgroundColor: palette.background,
    colorScheme: ColorScheme.dark(
      primary: accent,
      onPrimary: palette.background,
      secondary: notesActive ? palette.checklistAccent : palette.notesAccent,
      onSecondary: palette.background,
      surface: palette.surface,
      onSurface: palette.ink,
      onSurfaceVariant: palette.muted,
      outline: palette.line,
    ),
    dividerColor: palette.line,
    textTheme: titles.copyWith(
      headlineMedium: titles.headlineMedium?.copyWith(fontFamily: _metalSerif),
      headlineSmall: titles.headlineSmall?.copyWith(fontFamily: _metalSerif),
      titleLarge: titles.titleLarge?.copyWith(fontFamily: _metalSerif),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      fillColor: palette.surface,
      border: outline,
      enabledBorder: outline,
      focusedBorder: outline.copyWith(borderSide: BorderSide(color: accent)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: blackMetal
          ? button.copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.disabled)
                      ? null
                      : palette.button(notesActive)),
              foregroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.disabled) ? null : palette.ink),
              backgroundBuilder: _blackMetalButtonFinish,
            )
          : button,
    ),
    textButtonTheme: TextButtonThemeData(style: button),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: blackMetal
          ? button.copyWith(
              backgroundColor: const WidgetStatePropertyAll(Color(0xFF371119)),
              foregroundColor: WidgetStatePropertyAll(palette.ink),
            )
          : button,
    ),
    iconButtonTheme: IconButtonThemeData(style: button),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      shape: frame,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.surface,
      shape: frame,
    ),
    chipTheme: base.chipTheme.copyWith(
      side: BorderSide(color: palette.line, width: 2),
    ),
    tooltipTheme: base.tooltipTheme.copyWith(
      decoration: BoxDecoration(color: palette.checklistButton),
      textStyle: TextStyle(color: palette.ink, fontSize: 12),
    ),
  );
}

BoxDecoration _metalBackdrop(
  _MetalPalette palette, {
  required bool notesActive,
  Color? background,
  Color? sidebar,
}) =>
    BoxDecoration(
      gradient: RadialGradient(
        center: const Alignment(0.82, -0.87),
        radius: 0.94,
        colors: [
          sidebar ?? palette.sidebar(notesActive),
          background ?? palette.background,
        ],
      ),
    );
