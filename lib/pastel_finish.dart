part of 'main.dart';

const _pastelDisplayFont = 'Coiny';
const _pastelReadingFont = 'Nunito';
const _defaultPastelCorner = 18.0;
const _pastelRoseButton = Color(0xFFF2AED3);
const _pastelBlueButton = Color(0xFFB4CEFF);
const _pastelLavender = Color(0xFFE8DDF9);
const _pastelPorcelain = Color(0xFFFFFAFE);
const _pastelRose = Color(0xFFFFDCEE);
const _pastelPlateShadow = Color(0x43725388);
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

Widget _pastelDrawerRing(ThemeData theme, Widget child) {
  if (theme.appearance != AppTheme.pastel) return child;
  return DecoratedBox(
    key: const ValueKey('pastel-drawer-button-ring'),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0x52FFFFFF),
      border: Border.all(color: Colors.white, width: 1.5),
      boxShadow: const [BoxShadow(color: Color(0xC0FFFFFF), blurRadius: 9)],
    ),
    child: child,
  );
}

ThemeData _buildPastelFinish(ThemeData base, double radius) {
  final corners = BorderRadius.circular(radius);
  final shape = RoundedRectangleBorder(borderRadius: corners);
  final fields = base.inputDecorationTheme;
  final field = OutlineInputBorder(
    borderRadius: corners,
    borderSide: BorderSide.none,
  );
  final fonts = base.textTheme.apply(
    fontFamily: _pastelReadingFont,
    fontFamilyFallback: const ['Roboto', 'sans-serif'],
  );
  TextStyle? heading(TextStyle? style) =>
      style?.copyWith(fontFamily: _pastelDisplayFont);
  ButtonStyle bevel(ButtonStyle? original) =>
      _pastelButtonBevel(corners).merge(original);

  return base.copyWith(
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
    filledButtonTheme:
        FilledButtonThemeData(style: bevel(base.filledButtonTheme.style)),
    outlinedButtonTheme:
        OutlinedButtonThemeData(style: bevel(base.outlinedButtonTheme.style)),
    textButtonTheme: TextButtonThemeData(
      style: base.textButtonTheme.style!.copyWith(
        shape: WidgetStatePropertyAll(shape),
        side: const WidgetStatePropertyAll(BorderSide.none),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: base.iconButtonTheme.style!.copyWith(
        shape: WidgetStatePropertyAll(shape),
        side: const WidgetStatePropertyAll(BorderSide.none),
      ),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      shape: (base.dialogTheme.shape! as RoundedRectangleBorder)
          .copyWith(borderRadius: corners, side: BorderSide.none),
      elevation: 10,
      shadowColor: _pastelPlateShadow,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: base.popupMenuTheme.copyWith(
      shape: (base.popupMenuTheme.shape! as RoundedRectangleBorder)
          .copyWith(borderRadius: corners, side: BorderSide.none),
      elevation: 6,
      shadowColor: _pastelPlateShadow,
      surfaceTintColor: Colors.transparent,
    ),
    chipTheme: base.chipTheme.copyWith(shape: shape, side: BorderSide.none),
    checkboxTheme: base.checkboxTheme.copyWith(side: BorderSide.none),
    drawerTheme: base.drawerTheme.copyWith(shape: shape, endShape: shape),
    snackBarTheme: base.snackBarTheme.copyWith(shape: shape),
    tooltipTheme: base.tooltipTheme.copyWith(
      decoration: BoxDecoration(color: _pastelMauve, borderRadius: corners),
    ),
  );
}

ButtonStyle _pastelButtonBevel(BorderRadius corners) => ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: corners),
      ),
      side: const WidgetStatePropertyAll(BorderSide.none),
      shadowColor: const WidgetStatePropertyAll(_pastelPlateShadow),
      elevation: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled) ||
                states.contains(WidgetState.pressed)
            ? 0
            : 3,
      ),
      backgroundBuilder: (_, states, child) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: corners,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: states.contains(WidgetState.pressed)
                ? const [Color(0x16966AA7), Color(0x06FFFFFF)]
                : const [Color(0x4DFFFFFF), Color(0x18966AA7)],
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );

Widget _pastelLift(
  ThemeData theme,
  Widget child, {
  Color? colour,
}) {
  if (theme.appearance != AppTheme.pastel) return child;
  final radius = _pastelRadius(theme);
  return DecoratedBox(
    key: const ValueKey('pastel-beveled-surface'),
    decoration: BoxDecoration(
      borderRadius: radius,
      gradient: colour == null
          ? null
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(colour, Colors.white, .48)!, colour],
            ),
      boxShadow: [
        const BoxShadow(
            color: Color(0x2F765387), blurRadius: 13, offset: Offset(0, 6)),
        BoxShadow(
          color: theme.custom(_ThemeColour.borders)?.withValues(alpha: .22) ??
              const Color(0x21664C7C),
          blurRadius: 4,
          offset: const Offset(0, 3),
        ),
        const BoxShadow(
            color: Color(0xB0FFFFFF), blurRadius: 2, offset: Offset(-1, -1)),
      ],
    ),
    child: child,
  );
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
              Color.lerp(background, _pastelLavender, .72)!,
              Color.lerp(background, _pastelPorcelain, .68)!,
              Color.lerp(background, _pastelRose, .64)!,
            ],
            stops: const [0, .49, 1],
          ),
        ),
        child: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(.93, -.60),
              radius: .75,
              colors: [Color(0x65BEDBFF), Color(0x00BEDBFF)],
            ),
          ),
        ),
      );
}
