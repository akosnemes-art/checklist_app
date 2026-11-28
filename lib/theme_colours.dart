part of 'main.dart';

enum _ThemeColour {
  background('app background'),
  panel('panels and fields'),
  sidebar('sidebar'),
  text('text'),
  buttons('buttons'),
  borders('borders'),
  checklistAccent('checklist accent'),
  notesAccent('notes accent'),
  links('note links'),
  low('low priority'),
  medium('medium priority'),
  high('high priority');

  const _ThemeColour(this.label);
  final String label;
}

class _AppliedTheme extends ThemeExtension<_AppliedTheme> {
  const _AppliedTheme(this.appearance, this.colours);

  final AppTheme appearance;
  final Map<String, int> colours;

  Color? colour(_ThemeColour role) {
    final value = colours[role.name];
    return value == null ? null : Color(value);
  }

  @override
  _AppliedTheme copyWith() => this;

  @override
  _AppliedTheme lerp(_AppliedTheme? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

extension _ThemeColours on ThemeData {
  AppTheme? get appearance => extension<_AppliedTheme>()?.appearance;
  Color? custom(_ThemeColour role) => extension<_AppliedTheme>()?.colour(role);
}

Color _contrastingInk(Color colour) =>
    colour.computeLuminance() > 0.179 ? const Color(0xFF161821) : _borderWhite;

ThemeData _applyThemeColours(
    ThemeData base, AppTheme appearance, Map<String, int> colours, bool notes) {
  final applied = _AppliedTheme(appearance, colours);
  if (colours.isEmpty) return base.copyWith(extensions: [applied]);

  final background = applied.colour(_ThemeColour.background);
  final panel = applied.colour(_ThemeColour.panel);
  final ink = applied.colour(_ThemeColour.text);
  final button = applied.colour(_ThemeColour.buttons);
  final border = applied.colour(_ThemeColour.borders);
  final accent = applied.colour(
    notes ? _ThemeColour.notesAccent : _ThemeColour.checklistAccent,
  );
  final otherAccent = applied.colour(
    notes ? _ThemeColour.checklistAccent : _ThemeColour.notesAccent,
  );
  final scheme = base.colorScheme;
  final input = base.inputDecorationTheme;

  OutlinedBorder? framed(ShapeBorder? shape) {
    if (shape is _CyberpunkPopupFrame) {
      return shape.copyWith(
        side: shape.side.copyWith(color: border),
        accent: accent,
      );
    }
    return shape is OutlinedBorder && border != null
        ? shape.copyWith(side: shape.side.copyWith(color: border))
        : null;
  }

  InputBorder? field(InputBorder? original) =>
      original == null || border == null
          ? null
          : original.copyWith(
              borderSide: original.borderSide.copyWith(color: border));

  ButtonStyle? style(ButtonStyle? original, {bool filled = false}) {
    if (original == null) return null;
    final existingSide = original.side;
    return original.copyWith(
      side: border == null
          ? null
          : WidgetStateProperty.resolveWith((states) {
              final side = existingSide?.resolve(states);
              return side == BorderSide.none
                  ? side
                  : (side ?? const BorderSide()).copyWith(color: border);
            }),
      foregroundColor: filled && button != null
          ? WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.disabled)
                  ? null
                  : _contrastingInk(button))
          : null,
      backgroundColor: filled && button != null
          ? WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled) ? null : button)
          : null,
    );
  }

  return base.copyWith(
    extensions: [applied],
    scaffoldBackgroundColor: background,
    dividerColor: border,
    colorScheme: scheme.copyWith(
      primary: accent,
      onPrimary: accent == null ? null : _contrastingInk(accent),
      secondary: otherAccent,
      surface: panel?.withValues(alpha: scheme.surface.a),
      onSurface: ink,
      onSurfaceVariant: ink?.withValues(alpha: 0.78),
      outline: border,
    ),
    textTheme: ink == null
        ? null
        : base.textTheme.apply(bodyColor: ink, displayColor: ink),
    inputDecorationTheme: input.copyWith(
      fillColor: panel,
      border: field(input.border),
      enabledBorder: field(input.enabledBorder ?? input.border),
      focusedBorder: field(input.focusedBorder ?? input.border),
    ),
    filledButtonTheme: FilledButtonThemeData(
        style: style(base.filledButtonTheme.style, filled: true)),
    outlinedButtonTheme:
        OutlinedButtonThemeData(style: style(base.outlinedButtonTheme.style)),
    textButtonTheme:
        TextButtonThemeData(style: style(base.textButtonTheme.style)),
    iconButtonTheme:
        IconButtonThemeData(style: style(base.iconButtonTheme.style)),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: panel,
      shape: framed(base.dialogTheme.shape),
    ),
    popupMenuTheme: base.popupMenuTheme.copyWith(
      color: panel,
      shape: framed(base.popupMenuTheme.shape),
    ),
  );
}

class _ThemeColourDialog extends StatefulWidget {
  const _ThemeColourDialog({required this.defaults, required this.colours});

  final Map<_ThemeColour, Color> defaults;
  final Map<String, int> colours;

  @override
  State<_ThemeColourDialog> createState() => _ThemeColourDialogState();
}

class _ThemeColourDialogState extends State<_ThemeColourDialog> {
  late final _draft = Map<String, int>.of(widget.colours);
  _ThemeColour? _editing;
  HSVColor _hsv = const HSVColor.fromAHSV(1, 0, 1, 1);

  Color _current(_ThemeColour role) {
    final value = _draft[role.name];
    return value == null ? widget.defaults[role]! : Color(value);
  }

  void _edit(_ThemeColour role) => setState(() {
        if (_editing == role) {
          _editing = null;
        } else {
          _editing = role;
          _hsv = HSVColor.fromColor(_current(role)).withAlpha(1);
        }
      });

  void _update(HSVColor value) => setState(() {
        _hsv = value;
        _draft[_editing!.name] = value.toColor().toARGB32();
      });

  Widget _slider(String label, double value, double max, List<Color> colours,
      ValueChanged<double> change) {
    final name = localizeText(context, label);
    return Row(
      children: [
        SizedBox(width: 72, child: AppText(label, maxLines: 2)),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 18,
                right: 18,
                child: IgnorePointer(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: colours)),
                  ),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 5,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  secondaryActiveTrackColor: Colors.transparent,
                ),
                child: Semantics(
                  label: name,
                  child: Slider(
                    key: ValueKey('theme-hsv-$label'),
                    max: max,
                    value: value,
                    label: value.round().toString(),
                    semanticFormatterCallback: (value) => max == 360
                        ? '${value.round()}°'
                        : '${(value * 100).round()}%',
                    onChanged: change,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _colourRow(_ThemeColour role) {
    final colour = _current(role);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: AppText(role.label)),
            InkWell(
              key: ValueKey('theme-colour-${role.name}'),
              onTap: () => _edit(role),
              child: Tooltip(
                message: localizeText(context, role.label),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    width: 30,
                    height: 26,
                    decoration: BoxDecoration(
                      color: colour,
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_editing == role) ...[
          _slider(
              'hue',
              _hsv.hue,
              360,
              const [
                Colors.red,
                Color(0xFFFFFF00),
                Color(0xFF00FF00),
                Color(0xFF00FFFF),
                Colors.blue,
                Color(0xFFFF00FF),
                Colors.red,
              ],
              (v) => _update(_hsv.withHue(v))),
          _slider(
              'saturation',
              _hsv.saturation,
              1,
              [
                _hsv.withSaturation(0).withValue(1).toColor(),
                _hsv.withSaturation(1).withValue(1).toColor(),
              ],
              (v) => _update(_hsv.withSaturation(v))),
          _slider(
              'value',
              _hsv.value,
              1,
              [
                Colors.black,
                _hsv.withValue(1).toColor(),
              ],
              (v) => _update(_hsv.withValue(v))),
        ],
        const Divider(height: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => _popupAlert(
        context,
        key: const ValueKey('theme-customise-dialog'),
        title: const AppText('customise colours'),
        content: SizedBox(
          width: 380,
          height: math.min(460, MediaQuery.sizeOf(context).height * 0.50),
          child: ListView(
            key: const ValueKey('theme-colour-list'),
            children: [
              for (final role in _ThemeColour.values) _colourRow(role)
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _draft.isEmpty
                ? null
                : () => setState(() {
                      _draft.clear();
                      _editing = null;
                    }),
            child: const AppText('reset colours'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AppText('cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _draft),
            child: const AppText('save'),
          ),
        ],
      );
}

Color _sidebarColour(AppTheme appearance, bool notes) {
  return switch (appearance) {
    AppTheme.boi => notes ? _notesSidebar : _checklistSidebar,
    AppTheme.pencil => _lightSidebar,
    AppTheme.pastel => _milkBackground,
    AppTheme.copper ||
    AppTheme.blackMetal =>
      appearance._metalPalette!.sidebar(notes),
    AppTheme.pixel ||
    AppTheme.cyberpunk ||
    AppTheme.sv =>
      appearance._modernPalette!.sidebar(notes),
  };
}

Color _createButtonColour(AppTheme appearance, bool notes) {
  return switch (appearance) {
    AppTheme.boi => notes ? _deepBlueButton : _darkPurpleButton,
    AppTheme.pencil => _lightControl,
    AppTheme.pastel => _milkBackground,
    AppTheme.copper ||
    AppTheme.blackMetal =>
      appearance._metalPalette!.button(notes),
    AppTheme.pixel => appearance._modernPalette!.accent(notes),
    AppTheme.cyberpunk => notes ? _cyberpunkCreateBlue : _cyberpunkCreateRed,
    AppTheme.sv => notes ? _svPaper : _svOchre,
  };
}

Map<_ThemeColour, Color> _themeColourDefaults(AppTheme appearance, bool notes) {
  final metal = appearance._metalPalette;
  final modern = appearance._modernPalette;
  final pastel = appearance == AppTheme.pastel;
  final pencil = appearance == AppTheme.pencil;
  final checklist = metal?.checklistAccent ??
      modern?.checklistAccent ??
      (pencil
          ? _lightControl
          : pastel
              ? _milkLine
              : _brandPurple);
  final note = metal?.notesAccent ??
      modern?.notesAccent ??
      (pencil
          ? _lightControl
          : pastel
              ? _pastelPlum
              : _defaultNoteBlue);
  Color priority(ProjectImportance importance) {
    if (modern != null) return modern.priorities[importance.index];
    if (metal != null) {
      return switch (importance) {
        ProjectImportance.low => metal.muted,
        ProjectImportance.normal =>
          appearance == AppTheme.blackMetal ? _blackMetalMedium : note,
        ProjectImportance.high => checklist,
      };
    }
    if (pastel) return _pastelImportanceColor(importance);
    if (pencil) return _pencilImportanceColor(importance);
    return _importanceColor(importance);
  }

  return {
    _ThemeColour.background: metal?.background ??
        modern?.background ??
        (pencil
            ? _lightBackground
            : pastel
                ? _milkBackground
                : _backgroundDark),
    _ThemeColour.panel: metal?.surface ??
        modern?.panel ??
        (pencil
            ? _lightSurface
            : pastel
                ? _milkBackground
                : _surfaceDark),
    _ThemeColour.sidebar: _sidebarColour(appearance, notes),
    _ThemeColour.text: metal?.ink ??
        modern?.ink ??
        (pastel
            ? _milkInk
            : appearance.isDark
                ? _borderWhite
                : _lightText),
    _ThemeColour.buttons: _createButtonColour(appearance, notes),
    _ThemeColour.borders: metal?.line ??
        modern?.border ??
        (pencil
            ? _lightLine
            : pastel
                ? _pastelLavender
                : _defaultNoteBlue),
    _ThemeColour.checklistAccent: checklist,
    _ThemeColour.notesAccent: note,
    _ThemeColour.links: metal?.notesAccent ??
        modern?.notesAccent ??
        (pencil
            ? _defaultNoteBlue
            : pastel
                ? _deepBlueButton
                : _brandYellow),
    _ThemeColour.low: priority(ProjectImportance.low),
    _ThemeColour.medium: priority(ProjectImportance.normal),
    _ThemeColour.high: priority(ProjectImportance.high),
  };
}
