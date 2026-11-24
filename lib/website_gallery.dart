part of 'main.dart';

class _WebsiteGallery extends StatefulWidget {
  const _WebsiteGallery({
    required this.links,
    required this.previews,
    required this.onOpenLink,
  });

  final List<Uri> links;
  final WebsitePreviews previews;
  final ValueChanged<Uri> onOpenLink;

  @override
  State<_WebsiteGallery> createState() => _WebsiteGalleryState();
}

class _WebsiteGalleryState extends State<_WebsiteGallery> {
  final _images = <Uri, Future<Uint8List?>>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _popupAlert(
      context,
      key: const ValueKey('website-gallery-dialog'),
      title: const AppText('website links'),
      content: widget.links.isEmpty
          ? const AppText('no website links yet')
          : SizedBox(
              width: 440,
              height: 420,
              child: ListView.separated(
                itemCount: widget.links.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final link = widget.links[index];
                  return InkWell(
                    key: ValueKey(link),
                    onTap: () => widget.onOpenLink(link),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<Uint8List?>(
                            future: _images.putIfAbsent(
                                link, () => widget.previews.load(link)),
                            builder: (context, snapshot) {
                              if (snapshot.data case final image?) {
                                return Image.memory(
                                  image,
                                  fit: BoxFit.contain,
                                  height: 144,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const AppText('preview unavailable'),
                                );
                              }
                              return AppText(
                                snapshot.connectionState == ConnectionState.done
                                    ? 'preview unavailable'
                                    : 'loading preview…',
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          Text(
                            link.toString(),
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: _noteLinkColour(theme),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const AppText('close'),
        ),
      ],
    );
  }
}
