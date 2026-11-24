class NoteLink {
  const NoteLink(this.start, this.end, this.uri);

  final int start;
  final int end;
  final Uri uri;
}

const _label = r'[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?';
const _domain = '(?:$_label\\.)+[a-z]{2,63}(?![a-z0-9-]|\\.[a-z0-9])';
const _linkCharacters = r'''[^\s<>"“”‘’`*]''';
final _linkPattern = RegExp(
  r'(?<![a-z0-9@:/.-])(?:'
  r'([a-z][a-z0-9+.-]*://|(?:mailto|tel|sms|smsto|geo|market|spotify):)'
  '$_linkCharacters+|$_domain(?::[0-9]+)?(?:[/?#]$_linkCharacters*)?)',
  caseSensitive: false,
);
final _richMarkers = RegExp(r'[\uE000-\uE005]');
const _blockedSchemes = {
  'about',
  'android.resource',
  'blob',
  'chrome',
  'chrome-extension',
  'content',
  'data',
  'file',
  'intent',
  'javascript',
  'vbscript',
};

List<NoteLink> findNoteLinks(String text) {
  final visible = text.replaceAll(_richMarkers, '');
  final offsets = visible.length == text.length
      ? null
      : [
          for (var i = 0; i < text.length; i++)
            if (!_richMarkers.hasMatch(text[i])) i,
        ];
  final links = <NoteLink>[];
  for (final match in _linkPattern.allMatches(visible)) {
    var link = _trimLinkEnd(match[0]!);
    if (match.start >= 2 &&
        visible.startsWith('__', match.start - 2) &&
        link.endsWith('__')) {
      link = link.substring(0, link.length - 2);
    }
    final uri = Uri.tryParse(match[1] == null ? 'https://$link' : link);
    if (uri == null || !uri.hasScheme || _blockedSchemes.contains(uri.scheme)) {
      continue;
    }
    if ((uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isEmpty) {
      continue;
    }
    final end = match.start + link.length;
    links.add(NoteLink(
      offsets?[match.start] ?? match.start,
      offsets == null ? end : offsets[end - 1] + 1,
      uri,
    ));
  }
  return links;
}

String _trimLinkEnd(String link) {
  const closing = {')': '(', ']': '[', '}': '{'};
  while (link.isNotEmpty) {
    final last = link[link.length - 1];
    final opening = closing[last];
    if (!'.,!?:;\''.contains(last) &&
        (opening == null ||
            last.allMatches(link).length <= opening.allMatches(link).length)) {
      break;
    }
    link = link.substring(0, link.length - 1);
  }
  return link;
}

final _ocrAddress = RegExp(
  r'(?<![a-z0-9@:/.-])'
  r'(?:https?[ \t]*[:：]\s*[/／]\s*[/／]\s*|(?=www[ \t]*[.．])|'
  '(?=$_label[ \\t]+[.．]))'
  '$_label[ \\t]*[.．]\\s*'
  '(?:$_label(?:[.．]|[ \\t]+[.．][ \\t]*))*[a-z]{2,63}(?![a-z0-9-])'
  r'(?::[0-9]+)?(?:[ \t]*[/／][ \t]*[^\s<>"“”‘’]+|[?#][^\s<>"“”‘’]+)?',
  caseSensitive: false,
);
final _ocrUrlPunctuation = RegExp(r'\s+|[：．／]');

String restorePhotoWebLinks(
  String text, {
  void Function(int start, int end, String replacement)? onRewrite,
}) =>
    text.replaceAllMapped(
      _ocrAddress,
      (match) {
        final original = match[0]!;
        final repaired = original.replaceAllMapped(
          _ocrUrlPunctuation,
          (punctuation) => switch (punctuation[0]) {
            '：' => ':',
            '．' => '.',
            '／' => '/',
            _ => '',
          },
        );
        if (repaired != original) {
          onRewrite?.call(match.start, match.end, repaired);
        }
        return repaired;
      },
    );
