part of 'main.dart';

const _cyberpunkFont = 'Rajdhani';
const _cyberpunkCreateRed = Color(0xFFD91432);
const _cyberpunkCreateBlue = Color(0xFF165AC8);
const _cyberpunkProgressBlue = Color(0xFF379BFF);
const _cyberpunkBevel = BeveledRectangleBorder(
  borderRadius: BorderRadius.only(bottomRight: Radius.circular(16)),
);
const _cyberpunkPalette = _ModernPalette(
  background: Color(0xFF110B18),
  panel: Color(0xFF211726),
  checklistSidebar: Color(0xE81C101C),
  notesSidebar: Color(0xE8131A27),
  ink: Color(0xFFFFECE7),
  border: Color(0xFFAB5D78),
  checklistAccent: Color(0xFFFF7881),
  notesAccent: Color(0xFF6EE5EB),
  buttonInk: Color(0xFF200F20),
  priorities: [Color(0xFF69CEE7), Color(0xFFF184C5), Color(0xFFFFCD72)],
);

ThemeData _buildCyberpunkTheme(ThemeData dark, {required bool notes}) {
  final base =
      _buildModernTheme(dark, _cyberpunkPalette, notes: notes, pixel: false);
  final accent = _cyberpunkPalette.accent(notes);
  final text = base.textTheme;
  TextStyle? technical(TextStyle? style, {double tracking = 0.6}) =>
      style?.copyWith(
        fontFamily: _cyberpunkFont,
        fontFamilyFallback: const ['sans-serif'],
        fontWeight: FontWeight.w700,
        letterSpacing: tracking,
      );
  final style = ButtonStyle(
    shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
    side: WidgetStatePropertyAll(
        BorderSide(color: accent.withValues(alpha: 0.78))),
    backgroundBuilder: _cyberpunkButtonLayer,
  );
  return base.copyWith(
    textTheme: text.copyWith(
      headlineMedium: technical(text.headlineMedium, tracking: 0.25),
      headlineSmall: technical(text.headlineSmall, tracking: 0.25),
      titleLarge: technical(text.titleLarge),
      titleMedium: technical(text.titleMedium),
      labelLarge: technical(text.labelLarge, tracking: 0.9),
      labelMedium: technical(text.labelMedium),
      labelSmall: technical(text.labelSmall, tracking: 1.15),
    ),
    tooltipTheme: base.tooltipTheme.copyWith(
      decoration: const BoxDecoration(color: Color(0xFF342437)),
    ),
    filledButtonTheme: FilledButtonThemeData(style: style),
    outlinedButtonTheme: OutlinedButtonThemeData(style: style),
    textButtonTheme: TextButtonThemeData(style: style),
  );
}

Widget _cyberpunkButtonLayer(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) {
  return _CyberpunkButtonGlitch(
    enabled: !states.contains(WidgetState.disabled),
    hovered: states.contains(WidgetState.hovered),
    child: child ?? const SizedBox.shrink(),
  );
}

class _CyberpunkButtonGlitch extends StatefulWidget {
  const _CyberpunkButtonGlitch({
    required this.enabled,
    required this.hovered,
    required this.child,
    this.ambient,
  });

  final bool enabled;
  final bool hovered;
  final Widget child;
  final bool? ambient;

  @override
  State<_CyberpunkButtonGlitch> createState() => _CyberpunkButtonGlitchState();
}

class _CyberpunkButtonGlitchState extends State<_CyberpunkButtonGlitch>
    with SingleTickerProviderStateMixin {
  final _random = math.Random();
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: 1,
  );
  Timer? _idle;
  AppLifecycleListener? _lifecycle;
  bool _motion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ignore: deprecated_member_use
    final tickerEnabled = TickerMode.of(context);
    _motion = tickerEnabled && !MediaQuery.disableAnimationsOf(context);
    _updateAmbient();
  }

  @override
  void didUpdateWidget(covariant _CyberpunkButtonGlitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAmbient();
    if (widget.hovered && !oldWidget.hovered) _flash();
  }

  void _updateAmbient() {
    if (widget.ambient != null) {
      _lifecycle ??=
          AppLifecycleListener(onStateChange: (_) => _updateAmbient());
    } else if (_lifecycle != null) {
      _lifecycle?.dispose();
      _lifecycle = null;
    }
    final state = WidgetsBinding.instance.lifecycleState;
    final foreground = state == null || state == AppLifecycleState.resumed;
    if (_motion && foreground && widget.enabled && widget.ambient == true) {
      _idle ??=
          Timer(Duration(milliseconds: 5000 + _random.nextInt(10001)), () {
        _idle = null;
        _flash();
        _updateAmbient();
      });
    } else {
      _idle?.cancel();
      _idle = null;
    }
  }

  void _flash() {
    if (!widget.enabled || !_motion) return;
    _pulse.duration =
        Duration(milliseconds: widget.ambient == null ? 280 : 620);
    _pulse.forward(from: 0);
  }

  @override
  void dispose() {
    _idle?.cancel();
    _lifecycle?.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _flash(),
      child: AnimatedBuilder(
        animation: _pulse,
        child: widget.child,
        builder: (context, child) {
          final step = (_pulse.value * 9).floor();
          final active = _pulse.isAnimating && _motion;
          // Short, displaced frames evoke a signal glitch without looping.
          const offsets = [2.0, -2.5, 1.0, 0.0, 2.5, -1.5, 0.5, -0.5, 0.0];
          final dx = active ? offsets[math.min(step, offsets.length - 1)] : 0.0;
          if (widget.ambient != null) {
            return _CyberpunkCreateSlices(
              frame: active ? step : null,
              child: child!,
            );
          }
          return CustomPaint(
            key: const ValueKey('cyberpunk-button-glitch'),
            foregroundPainter: _CyberpunkSlices(active ? step : null),
            child: Transform.translate(
              offset: Offset(dx, 0),
              transformHitTests: false,
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class _CyberpunkCreateSlices extends StatelessWidget {
  const _CyberpunkCreateSlices({required this.frame, required this.child});

  final int? frame;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final step = frame;
    final direction = step == null || step.isEven ? 1.0 : -1.0;
    return CustomPaint(
      key: const ValueKey('cyberpunk-create-glitch'),
      foregroundPainter: _CyberpunkSlices(step),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          child,
          if (step != null)
            Positioned.fill(
              key: const ValueKey('cyberpunk-create-ghost'),
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      for (final (hue, top, height, offset) in [
                        (_cyberpunkCyan, 0.32 + (step % 3) * 0.05, 0.11, 4.0),
                        (_cyberpunkRed, 0.45 + (step % 3) * 0.04, 0.10, -5.0),
                        (
                          const Color(0xFFFFF3DE),
                          0.58 - (step % 3) * 0.04,
                          0.08,
                          6.0
                        ),
                      ])
                        ClipRect(
                          clipper: _CyberpunkGlitchBand(top, height),
                          child: Transform.translate(
                            offset: Offset(offset * direction, 0),
                            child: ColorFiltered(
                              colorFilter:
                                  ColorFilter.mode(hue, BlendMode.srcIn),
                              child: child,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CyberpunkGlitchBand extends CustomClipper<Rect> {
  const _CyberpunkGlitchBand(this.top, this.height);

  final double top;
  final double height;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, size.height * top, size.width, size.height * height);

  @override
  bool shouldReclip(_CyberpunkGlitchBand oldClipper) =>
      oldClipper.top != top || oldClipper.height != height;
}

class _CyberpunkSlices extends CustomPainter {
  const _CyberpunkSlices(this.step);

  final int? step;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = step;
    if (frame == null || size.isEmpty) return;
    final cyan = Paint()..color = const Color(0x826EE5EB);
    final coral = Paint()..color = const Color(0xA4FF7881);
    final y = size.height * (0.12 + (frame * 3 % 7) * 0.095);
    final change = frame.isEven ? 0.58 : 0.31;
    canvas.drawRect(
        Rect.fromLTWH(size.width * change, y, size.width * (0.9 - change), 2),
        cyan);
    canvas.drawRect(
        Rect.fromLTWH(
            1, math.min(y + 4, size.height), size.width * (change - 0.08), 1),
        coral);
  }

  @override
  bool shouldRepaint(_CyberpunkSlices oldDelegate) => oldDelegate.step != step;
}
