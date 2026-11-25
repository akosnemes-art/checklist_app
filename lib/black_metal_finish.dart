part of 'main.dart';

Widget _blackMetalButtonFinish(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) =>
    states.contains(WidgetState.disabled)
        ? (child ?? const SizedBox.shrink())
        : CustomPaint(
            key: const ValueKey('black-metal-button-finish'),
            painter: const _CrimsonButtonPatina(),
            child: child,
          );

class _CrimsonButtonPatina extends CustomPainter {
  const _CrimsonButtonPatina();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final stain = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x55090004), Colors.transparent, Color(0x9424000F)],
        stops: [0, 0.55, 1],
      ).createShader(bounds);
    canvas.drawRect(bounds, stain);
    final fleck = Paint()..color = const Color(0x5BE45A67);
    final scratch = Paint()..color = const Color(0x6B27000C);
    final random = math.Random(51);
    for (var i = 0; i < 27; i++) {
      final x = (0.55 + random.nextDouble() * 0.45) * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 0.35 + random.nextDouble() * 2.1;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: radius * 3.1,
          height: radius,
        ),
        i.isEven ? fleck : scratch,
      );
    }
  }

  @override
  bool shouldRepaint(_CrimsonButtonPatina oldDelegate) => false;
}

class _BlackMetalPanel extends StatelessWidget {
  const _BlackMetalPanel({
    required this.enabled,
    required this.initialDelay,
    required this.child,
  });

  final bool enabled;
  final Duration initialDelay;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          child,
          if (enabled)
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const RepaintBoundary(
                      child: CustomPaint(
                        key: ValueKey('black-metal-texture'),
                        painter: _DistressedMetal(),
                      ),
                    ),
                    if (!MediaQuery.disableAnimationsOf(context))
                      _PanelSheen(initialDelay: initialDelay),
                  ],
                ),
              ),
            ),
        ],
      );
}

class _DistressedMetal extends CustomPainter {
  const _DistressedMetal();

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(2185);
    final dust = Paint()..color = const Color(0x14DDD8D9);
    final abrasion = Paint()..strokeWidth = 0.7;
    final pits = (size.width * size.height / 110).clamp(0, 2600).round();
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var i = 0; i < pits; i++) {
      final x = random.nextDouble();
      final y = random.nextDouble();
      final point = Offset(x * size.width, y * size.height);
      canvas.drawCircle(point, 0.25 + random.nextDouble() * 0.6, dust);
      // The finish is most visibly worn where the plate meets its frame.
      final edge = math.min(math.min(x, 1 - x), math.min(y, 1 - y));
      if (i % 13 == 0 && edge < 0.19) {
        abrasion.color =
            i.isEven ? const Color(0x22C7B0B5) : const Color(0x42000000);
        final length = 3 + random.nextDouble() * 25;
        canvas.drawLine(
            point, point + Offset(length, -length * 0.23), abrasion);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DistressedMetal oldDelegate) => false;
}

class _PanelSheen extends StatefulWidget {
  const _PanelSheen({required this.initialDelay});

  final Duration initialDelay;

  @override
  State<_PanelSheen> createState() => _PanelSheenState();
}

class _PanelSheenState extends State<_PanelSheen>
    with SingleTickerProviderStateMixin {
  late final _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 640),
  );
  Timer? _nextSweep;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The boolean API also supports the Flutter version floor in pubspec.
    // ignore: deprecated_member_use
    final running = TickerMode.of(context);
    if (running && _nextSweep == null) {
      _scheduleSweep(widget.initialDelay);
    } else if (!running && _nextSweep != null) {
      _nextSweep!.cancel();
      _nextSweep = null;
      _sweep.reset();
    }
  }

  void _scheduleSweep(Duration delay) {
    _nextSweep = Timer(delay, () {
      _sweep.forward(from: 0);
      _scheduleSweep(const Duration(seconds: 11));
    });
  }

  @override
  void dispose() {
    _nextSweep?.cancel();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
          key: const ValueKey('black-metal-sheen'),
          painter: _MetalSheen(_sweep),
        ),
      );
}

class _MetalSheen extends CustomPainter {
  _MetalSheen(this.progress) : super(repaint: progress);

  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = progress.value;
    if (phase == 0 || phase == 1) return;
    final band = math.max(28.0, size.width * 0.075);
    final margin = band + size.height * 0.22;
    final centre = Offset(
      ui.lerpDouble(-margin, size.width + margin, phase)!,
      size.height * 0.5,
    );
    final slope = Offset(band, -band * 0.40);
    final light = Paint()
      ..shader = ui.Gradient.linear(centre - slope, centre + slope, const [
        Colors.transparent,
        Color(0x22BBCDDD),
        Color(0x08D9E6F2),
        Color(0x32C8DFEF),
        Color(0x9AFFF5F8),
        Color(0x22D6E8F4),
        Colors.transparent,
      ], const [
        0,
        0.22,
        0.32,
        0.46,
        0.50,
        0.55,
        1
      ]);
    canvas.drawRect(Offset.zero & size, light);
  }

  @override
  bool shouldRepaint(_MetalSheen oldDelegate) =>
      oldDelegate.progress != progress;
}
