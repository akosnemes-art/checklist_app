part of 'main.dart';

class _ThemeBuildReveal extends StatelessWidget {
  const _ThemeBuildReveal({required this.progress, required this.child});

  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = MediaQuery.disableAnimationsOf(context)
        ? const AlwaysStoppedAnimation<double>(1)
        : progress;
    return CustomPaint(
      foregroundPainter: _ThemeBuildTrace(
        animation,
        Theme.of(context).colorScheme.primary,
      ),
      child: ClipRect(
        key: const ValueKey('theme-build-clip'),
        clipper: _ThemeBuildClipper(animation),
        child: child,
      ),
    );
  }
}

double _themeBuildEdge(double progress, Size size) =>
    size.height * (1 - Curves.easeInOutCubic.transform(progress));

class _ThemeBuildClipper extends CustomClipper<Rect> {
  _ThemeBuildClipper(this.progress) : super(reclip: progress);

  final Animation<double> progress;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
        0,
        _themeBuildEdge(progress.value, size),
        size.width,
        size.height,
      );

  @override
  bool shouldReclip(_ThemeBuildClipper oldClipper) =>
      oldClipper.progress != progress;
}

class _ThemeBuildTrace extends CustomPainter {
  _ThemeBuildTrace(this.progress, this.colour) : super(repaint: progress);

  final Animation<double> progress;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = progress.value;
    if (phase <= 0 || phase >= 1) return;
    final edge = _themeBuildEdge(phase, size);
    final intensity = math.sin(math.pi * phase);
    final ink = Paint()..color = colour.withValues(alpha: intensity * 0.44);
    canvas.drawRect(Rect.fromLTWH(0, edge, size.width, 1.5), ink);
    ink.color = colour.withValues(alpha: intensity * 0.13);
    canvas.drawRect(Rect.fromLTWH(0, edge + 4, size.width, 1), ink);
  }

  @override
  bool shouldRepaint(_ThemeBuildTrace oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colour != colour;
}

/// Schedules a short sweep without keeping a ticker active while the CRT is idle.
class _PixelNoise extends StatefulWidget {
  const _PixelNoise();

  @override
  State<_PixelNoise> createState() => _PixelNoiseState();
}

class _PixelNoiseState extends State<_PixelNoise>
    with SingleTickerProviderStateMixin {
  final _random = math.Random();
  late final _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  )..addStatusListener(_onSweep);
  Timer? _idle;
  bool _running = false;
  _PixelNoisePattern? _pattern;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Keep the project's supported Flutter version floor.
    // ignore: deprecated_member_use
    final enabled = TickerMode.of(context);
    if (_running == enabled) return;
    _running = enabled;
    if (enabled) {
      _schedule();
    } else {
      _idle?.cancel();
      _sweep.reset();
    }
  }

  void _onSweep(AnimationStatus status) {
    if (status == AnimationStatus.completed && _running) _schedule();
  }

  void _schedule() {
    _idle = Timer(Duration(milliseconds: 3400 + _random.nextInt(3300)), () {
      setState(() => _pattern = _PixelNoisePattern(_random));
      _sweep.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _running = false;
    _idle?.cancel();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
        key: const ValueKey('pixel-noise-band'),
        painter: _PixelNoisePainter(_sweep, _pattern),
      );
}

class _PixelNoisePattern {
  _PixelNoisePattern(math.Random random)
      : down = random.nextBool(),
        streaks = [
          for (var i = 0; i < 48; i++)
            (random.nextDouble(), 2 + random.nextDouble() * 18),
        ];

  final bool down;
  final List<(double, double)> streaks;
}

class _PixelNoisePainter extends CustomPainter {
  _PixelNoisePainter(this.sweep, this.pattern) : super(repaint: sweep);

  final Animation<double> sweep;
  final _PixelNoisePattern? pattern;

  @override
  void paint(Canvas canvas, Size size) {
    final pass = pattern;
    final phase = sweep.value;
    if (pass == null || phase <= 0 || phase >= 1 || size.isEmpty) return;
    final travel = pass.down ? phase : 1 - phase;
    final y = (travel * (size.height + 8) - 4).roundToDouble();
    final flicker = (phase * 25).floor();
    final backing = Paint()..color = const Color(0x24171919);
    final glow = Paint()..color = const Color(0x2A8CFF9D);
    canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), backing);
    for (var i = 0; i < pass.streaks.length; i++) {
      if ((i + flicker) % 4 == 0) continue;
      final (position, length) = pass.streaks[i];
      final x = position * size.width;
      final width = math.min(length, size.width - x);
      canvas.drawRect(Rect.fromLTWH(x, y + (i.isEven ? 0 : 2), width, 1), glow);
    }
  }

  @override
  bool shouldRepaint(_PixelNoisePainter oldDelegate) =>
      oldDelegate.sweep != sweep || oldDelegate.pattern != pattern;
}
