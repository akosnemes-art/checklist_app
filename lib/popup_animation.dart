part of 'main.dart';

const _popupDuration = Duration(milliseconds: 280);
const _popupContentsStart = 0.46;

Widget _animatedTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
  required String helpText,
}) {
  final animation = ModalRoute.of(context)!.animation!;
  final base = Theme.of(context);
  final surface = base.dialogTheme.backgroundColor ?? base.colorScheme.surface;
  final side = (base.dialogTheme.shape! as RoundedRectangleBorder).side;
  return AnimatedBuilder(
    animation: animation,
    child: TimePickerDialog(initialTime: initialTime, helpText: helpText),
    builder: (context, child) => Theme(
      data: base.copyWith(
        timePickerTheme: base.timePickerTheme.copyWith(
          backgroundColor: surface,
          shape: _DrawnPopupFrame(side, animation.value, surface: surface),
        ),
      ),
      child: child!,
    ),
  );
}

Widget _popupAlert(
  BuildContext context, {
  Key? key,
  Color? backgroundColor,
  RoundedRectangleBorder? shape,
  Widget? title,
  Widget? content,
  List<Widget>? actions,
  EdgeInsetsGeometry? actionsPadding,
}) {
  final theme = Theme.of(context);
  final frame = shape ?? theme.dialogTheme.shape! as RoundedRectangleBorder;
  final animation = ModalRoute.of(context)?.animation ??
      const AlwaysStoppedAnimation<double>(1);
  final contents = animation.drive(CurveTween(
    curve: const Interval(_popupContentsStart, 1, curve: Curves.easeOut),
  ));

  Widget? fade(Widget? child) =>
      child == null ? null : FadeTransition(opacity: contents, child: child);

  return AnimatedBuilder(
    animation: animation,
    builder: (context, _) => AlertDialog(
      key: key,
      backgroundColor: backgroundColor,
      shape: _DrawnPopupFrame(frame.side, animation.value),
      title: fade(title),
      content: fade(content),
      // Keep each action's normal layout and overflow behaviour.
      actions: actions?.map((child) => fade(child)!).toList(),
      actionsPadding: actionsPadding,
    ),
  );
}

class _DrawnPopupFrame extends RoundedRectangleBorder {
  const _DrawnPopupFrame(BorderSide side, this.progress, {this.surface})
      : super(side: side);

  final double progress;
  final Color? surface;

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (progress >= 1) {
      super.paint(canvas, rect, textDirection: textDirection);
      return;
    }
    final frameProgress = (progress / _popupContentsStart).clamp(0.0, 1.0);
    // The stock time picker owns its content. Blend it over its own surface.
    if (surface case final colour?) {
      final reveal =
          const Interval(_popupContentsStart, 1, curve: Curves.easeOut)
              .transform(progress);
      canvas.drawRect(
          rect, Paint()..color = colour.withValues(alpha: 1 - reveal));
    }
    if (frameProgress == 0) return;
    if (frameProgress == 1) {
      super.paint(canvas, rect, textDirection: textDirection);
      return;
    }

    final inset = rect.deflate(side.width / 2);
    final outline = (Path()
          ..moveTo(inset.left, inset.bottom)
          ..lineTo(inset.left, inset.top)
          ..lineTo(inset.right, inset.top)
          ..lineTo(inset.right, inset.bottom)
          ..close())
        .computeMetrics()
        .single;
    canvas.drawPath(
        outline.extractPath(0, outline.length * frameProgress), side.toPaint());
  }

  // The route supplies the progress directly. Avoid Material tweening it again.
  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => this;

  @override
  bool operator ==(Object other) =>
      other is _DrawnPopupFrame &&
      other.side == side &&
      other.progress == progress &&
      other.surface == surface;

  @override
  int get hashCode => Object.hash(side, progress, surface);
}
