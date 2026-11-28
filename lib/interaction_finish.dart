part of 'main.dart';

class _SettingsMenu<T> extends StatefulWidget {
  const _SettingsMenu({
    required this.iconKey,
    required this.tooltip,
    required this.dimension,
    required this.itemBuilder,
    required this.onSelected,
    this.iconSize = 18,
    this.colour,
    this.pastelRecessed = false,
  });

  final Key iconKey;
  final String tooltip;
  final double dimension;
  final double iconSize;
  final Color? colour;
  final bool pastelRecessed;
  final PopupMenuItemBuilder<T> itemBuilder;
  final ValueChanged<T> onSelected;

  @override
  State<_SettingsMenu<T>> createState() => _SettingsMenuState<T>();
}

class _SettingsMenuState<T> extends State<_SettingsMenu<T>> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appearance = theme.appearance;
    final icon = switch (appearance) {
      AppTheme.pixel => CustomPaint(
          key: const ValueKey('pixel-settings-dots'),
          size: const Size(18, 18),
          painter: _PixelDots(theme.colorScheme.primary, _open),
        ),
      AppTheme.cyberpunk => _CyberpunkActivation(
          active: _open,
          builder: (colour, lit) => Icon(
            Icons.more_vert_rounded,
            size: widget.iconSize,
            color: colour,
            shadows: lit
                ? [Shadow(color: colour.withValues(alpha: 0.82), blurRadius: 8)]
                : null,
          ),
        ),
      AppTheme.pastel => Icon(Icons.more_vert_rounded,
          size: widget.iconSize, color: _pastelSecondaryInk(theme)),
      _ => Icon(Icons.more_vert_rounded,
          size: widget.iconSize, color: widget.colour),
    };

    return PopupMenuButton<T>(
      popUpAnimationStyle: _cyberpunkMenuMotion(context),
      tooltip: widget.tooltip,
      padding: EdgeInsets.zero,
      onOpened: () => setState(() => _open = true),
      onCanceled: () => setState(() => _open = false),
      onSelected: (value) {
        setState(() => _open = false);
        widget.onSelected(value);
      },
      itemBuilder: widget.itemBuilder,
      child: SizedBox.square(
        key: widget.iconKey,
        dimension: widget.dimension,
        child: Center(
          child: appearance == AppTheme.pastel
              ? _PastelPressFace(
                  radius: BorderRadius.circular(100),
                  colour: theme.custom(_ThemeColour.panel) ?? _milkBackground,
                  pressed: false,
                  restingDepth: widget.pastelRecessed ? .78 : 0,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: icon,
                  ),
                )
              : icon,
        ),
      ),
    );
  }
}

class _PixelDots extends CustomPainter {
  const _PixelDots(this.colour, this.active);

  final Color colour;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = colour.withValues(alpha: active ? 1 : 0.68);
    final shadow = Paint()
      ..color = colour.withValues(alpha: active ? .55 : .24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (var i = 0; i < 3; i++) {
      final dot = Rect.fromLTWH(size.width / 2 - 1.5, 2 + i * 5, 3, 3);
      canvas.drawRect(dot, shadow);
      canvas.drawRect(dot, paint);
    }
  }

  @override
  bool shouldRepaint(_PixelDots oldDelegate) =>
      oldDelegate.colour != colour || oldDelegate.active != active;
}

Widget _settingsGlyph(
  BuildContext context,
  IconData icon, {
  required double size,
  Color? colour,
  bool active = false,
  bool? settingsOpen,
}) {
  final theme = Theme.of(context);
  if (theme.appearance == AppTheme.cyberpunk && settingsOpen != null) {
    return Icon(
      icon,
      size: size,
      color: _cyberpunkRed,
      shadows: settingsOpen
          ? [Shadow(color: _cyberpunkRed.withValues(alpha: .65), blurRadius: 7)]
          : null,
    );
  }
  if (theme.appearance != AppTheme.pixel) {
    return Icon(icon, size: size, color: colour);
  }
  final accent = theme.colorScheme.primary;
  final pixels = switch (icon) {
    Icons.settings_outlined => const [28, 62, 107, 99, 107, 62, 28],
    Icons.keyboard_arrow_down_rounded => const [0, 0, 65, 34, 20, 8, 0],
    Icons.arrow_back_rounded => const [8, 16, 32, 127, 32, 16, 8],
    Icons.menu_rounded => const [0, 127, 0, 127, 0, 127, 0],
    Icons.palette_outlined => const [28, 34, 81, 65, 83, 62, 16],
    Icons.translate_rounded => const [24, 126, 24, 36, 42, 73, 15],
    Icons.import_export_rounded => const [32, 112, 32, 34, 2, 7, 2],
    Icons.info_outline_rounded => const [62, 65, 73, 65, 73, 73, 62],
    Icons.tune_rounded => const [0, 127, 32, 0, 8, 127, 0],
    Icons.file_upload_outlined => const [8, 28, 42, 8, 8, 65, 127],
    Icons.file_download_outlined => const [8, 8, 42, 28, 8, 65, 127],
    _ => null,
  };
  if (pixels == null) {
    return Icon(icon, size: size, color: accent, shadows: [
      Shadow(color: accent.withValues(alpha: .3), blurRadius: 5),
    ]);
  }
  return CustomPaint(
    key: ValueKey('pixel-settings-glyph-${icon.codePoint}'),
    size: Size.square(size),
    painter: _PixelSettingsGlyph(pixels, accent, active),
  );
}

Widget _noteGlyph(
  BuildContext context,
  IconData icon, {
  Color? colour,
  bool active = false,
}) {
  final appearance = Theme.of(context).appearance;
  if (appearance != AppTheme.pixel && appearance != AppTheme.sv) {
    return Icon(icon, color: colour);
  }
  final pixels = switch (icon) {
    Icons.format_bold_rounded => const [60, 34, 34, 60, 34, 34, 60],
    Icons.format_italic_rounded => const [30, 8, 8, 16, 16, 32, 60],
    Icons.format_underlined_rounded => const [34, 34, 34, 34, 28, 0, 62],
    Icons.label_outline_rounded => const [0, 124, 66, 65, 66, 124, 0],
    Icons.add_rounded => const [0, 8, 8, 62, 8, 8, 0],
    _ => null,
  };
  if (pixels == null) return Icon(icon, color: colour);
  final prefix = appearance == AppTheme.sv ? 'sv' : 'pixel';
  return CustomPaint(
    key: ValueKey('$prefix-note-glyph-${icon.codePoint}'),
    size: const Size.square(24),
    painter: _PixelSettingsGlyph(
      pixels,
      colour ??
          IconTheme.of(context).color ??
          Theme.of(context).colorScheme.primary,
      active,
      glow: appearance == AppTheme.pixel,
    ),
  );
}

class _PixelSettingsGlyph extends CustomPainter {
  const _PixelSettingsGlyph(this.rows, this.colour, this.active,
      {this.glow = true});

  final List<int> rows;
  final Color colour;
  final bool active;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final pixel = (size.shortestSide / 8).floorToDouble();
    final origin = Offset(
        (size.width - 7 * pixel) / 2, (size.height - rows.length * pixel) / 2);
    final pattern = Path();
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < 7; x++) {
        if ((rows[y] & (1 << (6 - x))) == 0) continue;
        pattern.addRect(
            origin.translate(x * pixel, y * pixel) & Size.square(pixel));
      }
    }
    if (glow) {
      canvas.drawPath(
        pattern,
        Paint()
          ..color = colour.withValues(alpha: active ? .56 : .32)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
    }
    canvas.drawPath(
      pattern,
      Paint()
        ..color = colour.withValues(alpha: active || !glow ? 1 : .86)
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(_PixelSettingsGlyph oldDelegate) =>
      oldDelegate.rows != rows ||
      oldDelegate.colour != colour ||
      oldDelegate.active != active ||
      oldDelegate.glow != glow;
}

class _TaskCheckbox extends StatelessWidget {
  const _TaskCheckbox({required this.checked, required this.onToggle});

  final bool checked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appearance = theme.appearance;

    Widget box({OutlinedBorder? shape, Color? edge, Color? fill}) => Checkbox(
          value: checked,
          onChanged: (_) => onToggle(),
          shape: shape ?? _pastelShape(theme, scale: 0.25),
          side: edge == null
              ? theme.checkboxTheme.side
              : BorderSide(color: edge, width: 1),
          fillColor: appearance == AppTheme.pastel
              ? const WidgetStatePropertyAll(Colors.transparent)
              : fill == null
                  ? null
                  : WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? fill
                          : Colors.transparent,
                    ),
          checkColor:
              appearance == AppTheme.cyberpunk || appearance == AppTheme.pastel
                  ? Colors.transparent
                  : null,
          materialTapTargetSize: MaterialTapTargetSize.padded,
          visualDensity: VisualDensity.standard,
        );

    if (appearance == AppTheme.cyberpunk) {
      return _CyberpunkActivation(
        active: checked,
        builder: (colour, lit) => _CheckboxGlow(
          colour: colour,
          enabled: lit,
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              box(
                shape: const BeveledRectangleBorder(
                  borderRadius:
                      BorderRadius.only(bottomRight: Radius.circular(4)),
                ),
                edge: colour,
                fill: colour,
              ),
              if (checked)
                IgnorePointer(
                  child: Center(
                    child: _cyberpunkTick(_contrastingInk(colour), 18),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    if (appearance == AppTheme.pixel) {
      return _CheckboxGlow(
        colour: theme.colorScheme.primary,
        enabled: checked,
        child: box(),
      );
    }
    if (appearance == AppTheme.pastel) {
      return Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          Center(child: _MilkTaskMark(checked: checked)),
          box(),
        ],
      );
    }
    return box();
  }
}

class _MilkTaskMark extends StatelessWidget {
  const _MilkTaskMark({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(7));
    final face =
        Theme.of(context).custom(_ThemeColour.panel) ?? _milkBackground;
    return SizedBox.square(
      key: const ValueKey('milk-task-mark'),
      dimension: 24,
      child: CustomPaint(
        painter: _PastelFacePainter(radius, 1, face),
        child: AnimatedOpacity(
          opacity: checked ? 1 : 0,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 170),
          curve: Curves.easeInOut,
          child: const DecoratedBox(
            decoration: BoxDecoration(
                gradient: _milkAccentGradient, borderRadius: radius),
            child:
                Icon(Icons.check_rounded, size: 19, color: Color(0xFF35235A)),
          ),
        ),
      ),
    );
  }
}

Widget _cyberpunkTick(Color colour, double size) => CustomPaint(
      key: const ValueKey('cyberpunk-thin-tick'),
      size: Size.square(size),
      painter: _CyberpunkTickPainter(colour),
    );

class _CyberpunkTickPainter extends CustomPainter {
  const _CyberpunkTickPainter(this.colour);

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final check = Path()
      ..moveTo(size.width * .22, size.height * .49)
      ..lineTo(size.width * .43, size.height * .68)
      ..lineTo(size.width * .79, size.height * .32);
    canvas.drawPath(
      check,
      Paint()
        ..color = colour
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = .9,
    );
  }

  @override
  bool shouldRepaint(_CyberpunkTickPainter oldDelegate) =>
      oldDelegate.colour != colour;
}

class _CheckboxGlow extends StatelessWidget {
  const _CheckboxGlow({
    required this.colour,
    required this.enabled,
    required this.child,
  });

  final Color colour;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          if (enabled)
            Center(
              child: SizedBox.square(
                dimension: 14,
                child: DecoratedBox(
                  key: const ValueKey('task-checkbox-glow'),
                  decoration: BoxDecoration(boxShadow: [
                    BoxShadow(
                        color: colour.withValues(alpha: 0.57), blurRadius: 8),
                  ]),
                ),
              ),
            ),
          child,
        ],
      );
}

class _CyberpunkActivation extends StatefulWidget {
  const _CyberpunkActivation({required this.active, required this.builder});

  final bool active;
  final Widget Function(Color colour, bool lit) builder;

  @override
  State<_CyberpunkActivation> createState() => _CyberpunkActivationState();
}

class _CyberpunkActivationState extends State<_CyberpunkActivation>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
    value: 1,
  );

  @override
  void didUpdateWidget(covariant _CyberpunkActivation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active) {
      _pulse.value = 1;
    } else if (!oldWidget.active && !MediaQuery.disableAnimationsOf(context)) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final flashing = widget.active &&
              _pulse.isAnimating &&
              !MediaQuery.disableAnimationsOf(context);
          final flash = flashing ? math.sin(math.pi * _pulse.value) : 0.0;
          final colour = Color.lerp(_cyberpunkRed, _brandYellow, flash)!;
          final glyph = widget.builder(colour, widget.active);
          final frame = (_pulse.value * 15).floor();
          return CustomPaint(
            key: const ValueKey('cyberpunk-control-glitch'),
            foregroundPainter: _CyberpunkSlices(flashing ? frame % 9 : null),
            child: Transform.translate(
              offset: Offset(flashing ? (frame.isEven ? 1.4 : -1.4) : 0, 0),
              transformHitTests: false,
              child: glyph,
            ),
          );
        },
      );
}
