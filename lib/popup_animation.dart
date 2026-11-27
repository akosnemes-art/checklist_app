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
  final cyberpunk = base.appearance == AppTheme.cyberpunk;
  final surface = base.dialogTheme.backgroundColor ?? base.colorScheme.surface;
  final frame = base.dialogTheme.shape! as RoundedRectangleBorder;
  return AnimatedBuilder(
    animation: animation,
    child: TimePickerDialog(initialTime: initialTime, helpText: helpText),
    builder: (context, child) => Theme(
      data: base.copyWith(
        dialogTheme: cyberpunk
            ? base.dialogTheme.copyWith(clipBehavior: Clip.antiAlias)
            : null,
        timePickerTheme: base.timePickerTheme.copyWith(
          backgroundColor: surface,
          shape: cyberpunk
              ? _CyberpunkPopupFrame(
                  side: _cyberpunkReminderFrame.side,
                  accent: _cyberpunkReminderFrame.accent,
                  progress: animation.value,
                  surface: surface,
                  reminder: true,
                )
              : (base.appearance == AppTheme.pastel ||
                          base.appearance == AppTheme.sv) &&
                      animation.isCompleted
                  ? frame
                  : _DrawnPopupFrame(
                      frame.side,
                      animation.value,
                      surface: surface,
                      borderRadius: frame.borderRadius,
                    ),
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
  EdgeInsetsGeometry? contentPadding,
  EdgeInsets? insetPadding,
  bool scrollable = false,
}) {
  final theme = Theme.of(context);
  final cyberpunk = theme.appearance == AppTheme.cyberpunk;
  final milk = theme.appearance == AppTheme.pastel;
  final frame = shape ?? theme.dialogTheme.shape! as RoundedRectangleBorder;
  final animation = ModalRoute.of(context)?.animation ??
      const AlwaysStoppedAnimation<double>(1);
  final contents = animation.drive(CurveTween(
    curve: cyberpunk
        ? const Interval(_cyberpunkContentStart, 1, curve: Curves.easeOut)
        : const Interval(_popupContentsStart, 1, curve: Curves.easeOut),
  ));

  Widget? fade(Widget? child) =>
      child == null ? null : FadeTransition(opacity: contents, child: child);

  return AnimatedBuilder(
    animation: animation,
    builder: (context, _) => AlertDialog(
      key: key,
      backgroundColor: backgroundColor,
      titlePadding: milk ? const EdgeInsets.fromLTRB(22, 20, 22, 0) : null,
      contentPadding: contentPadding ??
          (milk ? const EdgeInsets.fromLTRB(22, 16, 22, 18) : null),
      insetPadding: insetPadding ??
          (milk
              ? const EdgeInsets.symmetric(horizontal: 20, vertical: 20)
              : null),
      scrollable: scrollable || milk,
      clipBehavior: cyberpunk || milk ? Clip.antiAlias : null,
      shape: cyberpunk
          ? (frame is _CyberpunkPopupFrame
                  ? frame
                  : _CyberpunkPopupFrame(
                      side: frame.side, accent: theme.colorScheme.primary))
              .copyWith(progress: animation.value)
          : milk
              ? _PastelSoftBorder(borderRadius: frame.borderRadius)
              : theme.appearance == AppTheme.sv && animation.isCompleted
                  ? frame
                  : _DrawnPopupFrame(
                      frame.side,
                      animation.value,
                      borderRadius: frame.borderRadius,
                    ),
      title: fade(title),
      content: fade(content),
      // Keep each action's normal layout and overflow behaviour.
      actions: actions?.map((child) => fade(child)!).toList(),
      actionsPadding: actionsPadding ??
          (milk ? const EdgeInsets.fromLTRB(16, 2, 16, 16) : null),
      actionsOverflowButtonSpacing: milk ? 8 : null,
    ),
  );
}

class _DrawnPopupFrame extends RoundedRectangleBorder {
  const _DrawnPopupFrame(BorderSide side, this.progress,
      {this.surface, super.borderRadius})
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
      canvas.drawRRect(
        borderRadius.resolve(textDirection).toRRect(rect),
        Paint()..color = colour.withValues(alpha: 1 - reveal),
      );
    }
    if (frameProgress == 0 || side.style == BorderStyle.none) return;
    if (frameProgress == 1) {
      super.paint(canvas, rect, textDirection: textDirection);
      return;
    }

    final inset = rect.deflate(side.width / 2);
    final corners = borderRadius.resolve(textDirection);
    final outline = (corners == BorderRadius.zero
            ? (Path()
              ..moveTo(inset.left, inset.bottom)
              ..lineTo(inset.left, inset.top)
              ..lineTo(inset.right, inset.top)
              ..lineTo(inset.right, inset.bottom)
              ..close())
            : (Path()..addRRect(corners.toRRect(inset))))
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
      other.borderRadius == borderRadius &&
      other.progress == progress &&
      other.surface == surface;

  @override
  int get hashCode => Object.hash(side, borderRadius, progress, surface);
}
