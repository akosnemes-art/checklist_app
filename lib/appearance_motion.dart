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

/// Schedules a slow crawl without keeping a ticker active while the CRT is idle.
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
    duration: const Duration(milliseconds: 4200),
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
        painter: _PixelNoisePainter(
            _sweep, _pattern, Theme.of(context).scaffoldBackgroundColor),
      );
}

class _PixelNoisePattern {
  _PixelNoisePattern(math.Random random)
      : down = random.nextBool(),
        streaks = [
          for (var i = 0; i < 144; i++)
            (
              random.nextDouble(),
              random.nextDouble(),
              1 + random.nextDouble() * 6
            ),
        ];

  final bool down;
  final List<(double, double, double)> streaks;
}

class _PixelNoisePainter extends CustomPainter {
  _PixelNoisePainter(this.sweep, this.pattern, this.background)
      : super(repaint: sweep);

  final Animation<double> sweep;
  final _PixelNoisePattern? pattern;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final pass = pattern;
    final phase = sweep.value;
    if (pass == null || phase <= 0 || phase >= 1 || size.isEmpty) return;
    final travel = pass.down ? phase : 1 - phase;
    const bandHeight = 26.0;
    final y = travel * (size.height + bandHeight) - bandHeight;
    final band = Rect.fromLTWH(0, y, size.width, bandHeight)
        .intersect(Offset.zero & size);
    if (band.isEmpty) return;
    final power = math.sin(math.pi * phase);
    final step = (phase * 56).floor();
    final ink = Paint();
    canvas.save();
    canvas.clipRect(band);
    // Cover the straight scanlines only within the moving strip, then redraw
    // their broken, vertically displaced segments through the noise.
    ink.color = background.withValues(alpha: 0.78 * power);
    canvas.drawRect(band, ink);
    for (var row = (y / 5).floor(); row * 5.0 < band.bottom; row++) {
      for (var segment = 0; segment < 9; segment++) {
        final shift = (row * 7 + segment * 3 + step) % 5 - 2;
        final x = segment * size.width / 9;
        final line = row * 5.0 + 1 + shift;
        ink.color = const Color(0xFF72FFA0)
            .withValues(alpha: (0.03 + shift.abs() * 0.012) * power);
        canvas.drawRect(Rect.fromLTWH(x, line, size.width / 9 - 2, 1), ink);
      }
    }
    for (var i = 0; i < pass.streaks.length; i++) {
      final (left, row, width) = pass.streaks[i];
      final x = ((left + step * (i.isEven ? 0.009 : 0.021)) % 1) * size.width;
      final grainY = y + row * bandHeight;
      ink.color = (i.isEven ? const Color(0xFFB7FFCD) : Colors.black)
          .withValues(alpha: (0.04 + ((i + step) % 5) * 0.015) * power);
      canvas.drawRect(Rect.fromLTWH(x, grainY, width, 1), ink);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PixelNoisePainter oldDelegate) =>
      oldDelegate.sweep != sweep ||
      oldDelegate.pattern != pattern ||
      oldDelegate.background != background;
}
