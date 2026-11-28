part of 'main.dart';

enum _NoteFormat {
  bold,
  italic,
  underline;

  int get bit => 1 << index;
  String marker(bool enabled) =>
      String.fromCharCode(0xe000 + index * 2 + (enabled ? 0 : 1));
}

void _writeNoteStyleChanges(StringBuffer output, int from, int to) {
  final changed = from ^ to;
  for (final format in _NoteFormat.values) {
    if ((changed & format.bit) != 0) {
      output.write(format.marker((to & format.bit) != 0));
    }
  }
}

class _NoteFormatting {
  _NoteFormatting(String text, List<NoteLink> links)
      : offsets = List.filled(text.length + 1, 0),
        rawStyles = List.filled(text.length + 1, 0) {
    final visible = StringBuffer();
    var style = 0;
    var linkIndex = 0;
    var index = 0;
    while (index < text.length) {
      while (linkIndex < links.length && index >= links[linkIndex].end) {
        linkIndex++;
      }
      final inLink =
          linkIndex < links.length && index >= links[linkIndex].start;
      final code = text.codeUnitAt(index) - 0xe000;
      final legacyUnderline = !inLink && text.startsWith('__', index);
      final markerLength =
          code >= 0 && code < 6 ? 1 : (legacyUnderline ? 2 : 0);
      if (markerLength == 0) {
        offsets[index] = styles.length;
        rawStyles[index++] = style;
        styles.add(style);
        visible.writeCharCode(text.codeUnitAt(index - 1));
        continue;
      }
      markers[index] = markerLength;
      for (var end = index + markerLength; index < end; index++) {
        offsets[index] = styles.length;
        rawStyles[index] = style;
      }
      if (legacyUnderline) {
        style ^= _NoteFormat.underline.bit;
      } else {
        final bit = 1 << (code ~/ 2);
        style = code.isEven ? style | bit : style & ~bit;
      }
    }
    offsets[index] = styles.length;
    rawStyles[index] = style;
    plainText = visible.toString();
  }

  late final String plainText;
  final List<int> offsets;
  final List<int> rawStyles;
  final styles = <int>[];
  final markers = <int, int>{};

  (int, int, int) _range(TextSelection selection) {
    final rawStart = selection.isValid
        ? selection.start.clamp(0, offsets.length - 1)
        : offsets.length - 1;
    final rawEnd = selection.isValid
        ? selection.end.clamp(rawStart, offsets.length - 1)
        : rawStart;
    return (offsets[rawStart], offsets[rawEnd], rawStyles[rawStart]);
  }

  int activeStyles(TextSelection selection) {
    final (start, end, cursorStyle) = _range(selection);
    if (start == end) return cursorStyle;
    var active = styles[start];
    for (var index = start + 1; index < end && active != 0; index++) {
      active &= styles[index];
    }
    return active;
  }

  TextEditingValue toggle(TextSelection selection, _NoteFormat format) {
    final (start, end, cursorStyle) = _range(selection);
    final enable = (activeStyles(selection) & format.bit) == 0;
    final output = StringBuffer();
    var style = 0;
    var selectionStart = 0;
    var selectionEnd = 0;

    void writeMarkers(int nextStyle) {
      _writeNoteStyleChanges(output, style, nextStyle);
      style = nextStyle;
    }

    for (var index = 0; index <= styles.length; index++) {
      if (index == end) selectionEnd = output.length;
      if (index == start && start == end) {
        writeMarkers(cursorStyle ^ format.bit);
        selectionStart = selectionEnd = output.length;
      }
      if (index == styles.length) break;

      var next = styles[index];
      if (index >= start && index < end) {
        next = enable ? next | format.bit : next & ~format.bit;
      }
      writeMarkers(next);
      if (index == start && start != end) selectionStart = output.length;
      output.writeCharCode(plainText.codeUnitAt(index));
    }
    writeMarkers(0);

    final reversed =
        selection.isValid && selection.baseOffset > selection.extentOffset;
    return TextEditingValue(
      text: output.toString(),
      selection: TextSelection(
        baseOffset: reversed ? selectionEnd : selectionStart,
        extentOffset: reversed ? selectionStart : selectionEnd,
        affinity: selection.affinity,
        isDirectional: selection.isDirectional,
      ),
    );
  }

  TextSpan buildTextSpan(
    String text,
    List<NoteLink> linkRanges, {
    required TextStyle base,
    required ThemeData theme,
    bool keepMarkerOffsets = false,
    NoteLink? highlightedLink,
    Map<int, TapGestureRecognizer> linkTaps = const {},
  }) {
    final hiddenMarkerStyle = base.copyWith(
      color: Colors.transparent,
      fontSize: 0.01,
      height: 0.01,
      letterSpacing: 0,
    );
    final children = <InlineSpan>[];
    var linkIndex = 0;
    var index = 0;
    while (index < text.length) {
      final markerLength = markers[index];
      if (markerLength != null) {
        final end = index + markerLength;
        if (keepMarkerOffsets) {
          children.add(TextSpan(
              text: text.substring(index, end), style: hiddenMarkerStyle));
        }
        index = end;
        continue;
      }
      while (
          linkIndex < linkRanges.length && index >= linkRanges[linkIndex].end) {
        linkIndex++;
      }
      final range =
          linkIndex < linkRanges.length ? linkRanges[linkIndex] : null;
      final link = range != null && index >= range.start ? range : null;
      final linkBoundary = link?.end ?? range?.start ?? text.length;
      final flags = rawStyles[index];
      var end = index + 1;
      while (end < linkBoundary && !markers.containsKey(end)) {
        end++;
      }
      final highlighted = link != null && link.start == highlightedLink?.start;
      final color =
          link == null ? base.color : _noteLinkColour(theme, highlighted);
      children.add(TextSpan(
        text: text.substring(index, end),
        recognizer: link == null ? null : linkTaps[link.start],
        style: base.copyWith(
          color: color,
          fontWeight: (flags & _NoteFormat.bold.bit) != 0
              ? FontWeight.w700
              : base.fontWeight,
          fontStyle: (flags & _NoteFormat.italic.bit) != 0
              ? FontStyle.italic
              : base.fontStyle,
          decoration: link != null || (flags & _NoteFormat.underline.bit) != 0
              ? TextDecoration.underline
              : base.decoration,
          shadows: highlighted && theme.appearance != AppTheme.pastel
              ? [Shadow(color: color ?? _defaultNoteBlue, blurRadius: 4)]
              : base.shadows,
        ),
      ));
      index = end;
    }
    return TextSpan(style: base, children: children);
  }
}

class _FormattedNoteController extends TextEditingController {
  String? _parsedText;
  List<NoteLink> _links = const [];
  late _NoteFormatting _formatting;
  NoteLink? _highlightedLink;

  _NoteFormatting get formatting {
    if (_parsedText != text) {
      _parsedText = text;
      _links = findNoteLinks(text);
      _formatting = _NoteFormatting(text, _links);
    }
    return _formatting;
  }

  List<NoteLink> get links {
    // The same parse keeps link and formatting offsets in the same text.
    formatting;
    return _links;
  }

  void highlightLink(NoteLink? link) {
    _highlightedLink = link;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) =>
      formatting.buildTextSpan(
        text,
        _links,
        base: style ?? const TextStyle(),
        theme: Theme.of(context),
        keepMarkerOffsets: true,
        highlightedLink: _highlightedLink,
      );
}

Color _noteLinkColour(ThemeData theme, [bool highlighted = false]) {
  if (theme.custom(_ThemeColour.links) case final link?) {
    return highlighted ? Color.lerp(link, _contrastingInk(link), 0.18)! : link;
  }
  if (theme.appearance?._modernPalette case final palette?) {
    return highlighted ? palette.checklistAccent : palette.notesAccent;
  }
  if (theme.metalPalette case final palette?) {
    return highlighted ? palette.checklistAccent : palette.notesAccent;
  }
  if (theme.appearance == AppTheme.pastel) {
    return highlighted ? _defaultNoteBlue : _deepBlueButton;
  }
  return theme.brightness == Brightness.dark ? _brandYellow : _defaultNoteBlue;
}
