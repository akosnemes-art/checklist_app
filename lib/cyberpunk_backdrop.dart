part of 'main.dart';

const _cyberpunkRed = Color(0xFFFF2349);
const _cyberpunkCyan = Color(0xFF56F1EA);

class _CyberpunkBackdrop extends StatefulWidget {
  const _CyberpunkBackdrop({required this.sidebar});

  final bool sidebar;

  @override
  State<_CyberpunkBackdrop> createState() => _CyberpunkBackdropState();
}

class _CyberpunkBackdropState extends State<_CyberpunkBackdrop> {
  final _frame = ValueNotifier<int>(0);
  Timer? _clock;
  late final AppLifecycleListener _lifecycle;
  bool _visible = true;
  bool _motion = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onStateChange: (state) {
      _visible = state == AppLifecycleState.resumed;
      _updateClock();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ignore: deprecated_member_use
    final tickerEnabled = TickerMode.of(context);
    _motion = tickerEnabled && !MediaQuery.disableAnimationsOf(context);
    _updateClock();
  }

  void _updateClock() {
    if (_visible && _motion) {
      _clock ??= Timer.periodic(const Duration(milliseconds: 160), (_) {
        _frame.value = (_frame.value + 1) % 360;
      });
    } else {
      _clock?.cancel();
      _clock = null;
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    _lifecycle.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(
          key: const ValueKey('cyberpunk-circuit-background'),
          painter: _CircuitBoard(
            Theme.of(context).scaffoldBackgroundColor,
            sidebar: widget.sidebar,
          ),
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _CircuitSignals(_frame, sidebar: widget.sidebar),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
}

class _CircuitBoard extends CustomPainter {
  const _CircuitBoard(this.background, {required this.sidebar});

  final Color background;
  final bool sidebar;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          radius: 0.92,
          center: const Alignment(0.72, -0.24),
          colors: [
            Color.lerp(background, const Color(0xFF133037), 0.53)!,
            background,
            Color.lerp(background, const Color(0xFF03070A), 0.67)!,
          ],
          stops: const [0, 0.58, 1],
        ).createShader(bounds),
    );

    final width = size.width;
    final height = size.height;
    final random = math.Random(712);
    canvas.save();
    canvas.clipRect(bounds);
    canvas.translate(0, -width * 0.04);
    canvas.rotate(0.165);

    final ink = Paint()..strokeWidth = 0.8;
    for (var line = 0; line < 44; line++) {
      final x = random.nextDouble() * (width + height * 0.18) - width * 0.10;
      final y = random.nextDouble() * height;
      final length = 10 + random.nextDouble() * width * 0.4;
      final angle = (line.isEven ? 1 : -1) * (10 + random.nextDouble() * 28);
      final wire = Path()
        ..moveTo(x, y)
        ..relativeLineTo(length * 0.48, 0)
        ..relativeLineTo(angle.abs(), angle)
        ..relativeLineTo(length * 0.28, 0);
      final hue = line % 4 == 0 ? _cyberpunkRed : _cyberpunkCyan;
      ink
        ..style = PaintingStyle.stroke
        ..color = hue.withValues(alpha: 0.11 + random.nextDouble() * 0.15);
      canvas.drawPath(wire, ink);
      ink.style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(x - 2, y - 1, 3, 2), ink);
    }

    final span = width + height * 0.2;
    _lightRail(canvas, span, height * 0.24, _cyberpunkRed, strength: 0.68);
    _lightRail(canvas, span, height * 0.47, _cyberpunkCyan, strength: 0.80);
    _lightRail(canvas, span, height * 0.498, _cyberpunkCyan, strength: 0.42);
    _lightRail(canvas, span, height * 0.68, _cyberpunkRed, strength: 0.53);
    _lightRail(canvas, span, height * 0.88, _cyberpunkCyan, strength: 0.30);
    canvas.restore();

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            background.withValues(alpha: sidebar ? 0.56 : 0.26),
            background.withValues(alpha: sidebar ? 0.28 : 0.07),
            background.withValues(alpha: sidebar ? 0.65 : 0.53),
          ],
          stops: const [0, 0.49, 1],
        ).createShader(bounds),
    );
  }

  void _lightRail(Canvas canvas, double span, double y, Color colour,
      {required double strength}) {
    final halo = Rect.fromLTWH(-span * 0.14, y - 13, span, 26);
    canvas.drawRect(
      halo,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colour.withValues(alpha: 0),
            colour.withValues(alpha: strength * 0.26),
            colour.withValues(alpha: 0),
          ],
        ).createShader(halo),
    );
    final beam = Rect.fromLTWH(-span * 0.14, y, span, 2);
    canvas.drawRect(
      beam,
      Paint()
        ..shader = LinearGradient(
          colors: [
            colour.withValues(alpha: strength * 0.18),
            colour.withValues(alpha: strength),
            colour.withValues(alpha: strength * 0.23),
          ],
        ).createShader(beam),
    );
  }

  @override
  bool shouldRepaint(_CircuitBoard oldDelegate) =>
      oldDelegate.background != background || oldDelegate.sidebar != sidebar;
}

class _CircuitSignals extends CustomPainter {
  _CircuitSignals(this.frame, {required this.sidebar}) : super(repaint: frame);

  final ValueNotifier<int> frame;
  final bool sidebar;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(0, -size.width * 0.04);
    canvas.rotate(0.165);
    final tracks = [0.24, 0.47, 0.498, 0.68, 0.88];
    for (var i = 0; i < tracks.length; i++) {
      final distance = (frame.value * (3 + i % 3) + i * 29) % 120 / 120;
      final x = size.width * (distance * 1.4 - 0.20);
      final y = size.height * tracks[i];
      final colour = i == 0 || i == 3 ? _cyberpunkRed : _cyberpunkCyan;
      final alpha = sidebar ? 0.18 : 0.39;
      final tail = Rect.fromLTWH(x - 44, y - 1, 49, 4);
      canvas.drawRect(
        tail,
        Paint()
          ..shader = LinearGradient(colors: [
            colour.withValues(alpha: 0),
            colour.withValues(alpha: alpha),
          ]).createShader(tail),
      );
      canvas.drawRect(Rect.fromLTWH(x + 5, y, 8, 2),
          Paint()..color = colour.withValues(alpha: alpha));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CircuitSignals oldDelegate) =>
      oldDelegate.frame != frame || oldDelegate.sidebar != sidebar;
}
