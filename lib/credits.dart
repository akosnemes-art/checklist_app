part of 'main.dart';

const _designerName = 'Ákos Nemes';
const _designerEmail = 'akosnemes@proton.me';

class _CreditsDialog extends StatefulWidget {
  const _CreditsDialog({required this.onOpenLink});

  final ValueChanged<Uri> onOpenLink;

  @override
  State<_CreditsDialog> createState() => _CreditsDialogState();
}

class _CreditsDialogState extends State<_CreditsDialog> {
  final _scroll = ScrollController();
  Timer? _startTimer;
  bool? _reducedMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion == reduced) return;
    _reducedMotion = reduced;
    _startTimer?.cancel();
    if (reduced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
      });
    } else {
      _startTimer = Timer(const Duration(milliseconds: 700), _roll);
    }
  }

  void _roll() {
    if (!_scroll.hasClients) return;
    final end = _scroll.position.maxScrollExtent;
    if (end <= _scroll.offset) return;
    unawaited(_scroll.animateTo(
      end,
      duration:
          Duration(milliseconds: ((end - _scroll.offset) * 1000 / 22).round()),
      curve: Curves.linear,
    ));
  }

  void _pause() {
    _startTimer?.cancel();
    if (_scroll.hasClients && _scroll.position.isScrollingNotifier.value) {
      _scroll.jumpTo(_scroll.offset);
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Widget _credit(String role, String name,
      {Map<String, Object> arguments = const {}, Widget? link}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        children: [
          AppText(role,
              arguments: arguments,
              style: theme.textTheme.labelMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 5),
          Text(name,
              textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
          if (link != null) link,
        ],
      ),
    );
  }

  Widget _link(Key key, String label, Uri uri) => TextButton(
        key: key,
        style: TextButton.styleFrom(
          side: BorderSide.none,
          foregroundColor: _noteLinkColour(Theme.of(context)),
        ),
        onPressed: () => widget.onOpenLink(uri),
        child: AppText(label,
            textAlign: TextAlign.center,
            style: const TextStyle(decoration: TextDecoration.underline)),
      );

  Widget _fontCredit(String theme, String font, String designer) => _credit(
        '{font} font design for {theme}',
        designer,
        arguments: {'font': font, 'theme': theme},
        link: _link(
          ValueKey('credits-font-$font'),
          'font source · Google Fonts',
          Uri.https(
              'fonts.google.com', '/specimen/${font.replaceAll(' ', '+')}'),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final height =
        (MediaQuery.sizeOf(context).height * 0.44).clamp(120.0, 328.0);
    final reduced = _reducedMotion ?? false;
    return _popupAlert(
      context,
      key: const ValueKey('credits-dialog'),
      title: const AppText('credits'),
      content: SizedBox(
        width: 360,
        height: height,
        child: Listener(
          onPointerDown: (_) => _pause(),
          child: SingleChildScrollView(
            key: const ValueKey('credits-roll'),
            controller: _scroll,
            padding: EdgeInsets.only(
              top: reduced ? 8 : height * 0.60,
              bottom: reduced ? 0 : height * 0.22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _credit(
                  'design',
                  _designerName,
                  link: _link(
                    const ValueKey('credits-email'),
                    _designerEmail,
                    Uri(scheme: 'mailto', path: _designerEmail),
                  ),
                ),
                _credit('development', 'Codex AI'),
                _fontCredit('Milk', _pastelDisplayFont, 'Marcelo Magalhães'),
                _fontCredit('Milk', _pastelReadingFont,
                    'Vernon Adams, Cyreal, Jacques Le Bailly'),
                _fontCredit('Pixel', _pixelFont, 'Stefie Justprince'),
                _fontCredit('SV', _svButtonFont, 'CodeMan38'),
                _fontCredit('SV', _svTextFont, 'Peter Hull'),
                _fontCredit('Cyberpunk', _cyberpunkFont, 'Indian Type Foundry'),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const AppText('close'),
        ),
      ],
    );
  }
}
