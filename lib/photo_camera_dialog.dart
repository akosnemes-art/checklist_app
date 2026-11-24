part of 'main.dart';

Future<void> _deleteCameraPhoto(String path) async {
  try {
    await File(path).delete();
  } on FileSystemException {
    // Camera temporary-file cleanup is best effort.
  }
}

class _PhotoCameraDialog extends StatefulWidget {
  const _PhotoCameraDialog({
    required this.ocrService,
    this.forCover = false,
    this.onOpenLink,
  });

  final OcrService ocrService;
  final bool forCover;
  final ValueChanged<Uri>? onOpenLink;

  @override
  State<_PhotoCameraDialog> createState() => _PhotoCameraDialogState();
}

class _PhotoCameraDialogState extends State<_PhotoCameraDialog>
    with WidgetsBindingObserver {
  CameraDescription? _front;
  CameraDescription? _back;
  CameraDescription? _selectedCamera;
  CameraController? _controller;
  Future<void> _cameraOperation = Future<void>.value();
  String? _error;
  bool _foreground = true;
  bool _opening = true;
  bool _capturing = false;
  bool _scanning = false;
  Timer? _scanDelay;
  Timer? _linkExpiry;
  ({Uri uri, bool fromQr})? _detectedLink;

  double get _aspectRatio => widget.forCover ? _coverAspectRatio : 3 / 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _findCameras();
  }

  Future<void> _findCameras() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) {
        setState(() {
          _opening = false;
          _error = 'No camera is available.';
        });
        return;
      }
      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.back) _back ??= camera;
        if (camera.lensDirection == CameraLensDirection.front) {
          _front ??= camera;
        }
      }
      _selectedCamera = _back ?? _front ?? cameras.first;
      if (_foreground) _openSelectedCamera();
    } catch (error) {
      if (mounted) _showCameraError(error);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_foreground) return;
      _foreground = true;
      if (_selectedCamera != null) _openSelectedCamera();
    } else if (state != AppLifecycleState.inactive && _foreground) {
      _foreground = false;
      _cameraOperation = _cameraOperation.then((_) => _closeCamera());
    }
  }

  void _openSelectedCamera() {
    setState(() {
      _opening = true;
      _error = null;
      _clearDetectedLink();
    });
    final selected = _selectedCamera!;
    _cameraOperation = _cameraOperation.then((_) async {
      await _closeCamera();
      if (!mounted || !_foreground || selected != _selectedCamera) return;
      final controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      try {
        await controller.initialize();
        if (!mounted || !_foreground) {
          await _releaseCamera(controller);
          return;
        }
        setState(() {
          _controller = controller;
          _opening = false;
        });
        await _startScanning(controller);
      } catch (error) {
        await _releaseCamera(controller);
        if (mounted) _showCameraError(error);
      }
    });
  }

  Future<void> _closeCamera() async {
    final controller = _controller;
    _controller = null;
    _clearDetectedLink();
    _scanDelay?.cancel();
    if (controller == null) return;
    if (mounted) setState(() {});
    await _releaseCamera(controller);
  }

  Future<void> _releaseCamera(CameraController controller) async {
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (error) {
      debugPrint('Could not stop camera preview scanning: $error');
    }
    try {
      await controller.dispose();
    } catch (error) {
      debugPrint('Could not release camera: $error');
    }
  }

  void _showCameraError(Object error) {
    final permissionDenied = error is CameraException &&
        (error.code == 'CameraAccessDenied' ||
            error.code == 'cameraPermission');
    setState(() {
      _opening = false;
      _error = permissionDenied
          ? widget.forCover
              ? 'Camera permission is needed to take a cover photo.'
              : 'Camera permission is needed to take a photo.'
          : 'The camera could not be opened.';
    });
  }

  Future<void> _startScanning(CameraController controller) async {
    if (!mounted ||
        Theme.of(context).platform != TargetPlatform.android ||
        !controller.supportsImageStreaming()) {
      return;
    }
    try {
      await controller
          .startImageStream((image) => _scanFrame(controller, image));
    } catch (error) {
      debugPrint('Could not start camera preview scanning: $error');
    }
  }

  bool _isPreviewing(CameraController controller) =>
      mounted &&
      _foreground &&
      !_opening &&
      !_capturing &&
      identical(_controller, controller);

  Future<void> _scanFrame(
      CameraController controller, CameraImage image) async {
    if (!_isPreviewing(controller) ||
        _scanning ||
        (_scanDelay?.isActive ?? false) ||
        image.planes.isEmpty) {
      return;
    }
    _scanning = true;
    _scanDelay = Timer(const Duration(milliseconds: 650), () {});
    try {
      final result = await widget.ocrService.scanFrame(
        image,
        rotation: controller.description.sensorOrientation,
        aspectRatio: _aspectRatio,
      );
      if (!_isPreviewing(controller)) return;
      final link = result.qrLink ?? result.textLinks.firstOrNull?.uri;
      if (link == null) return;
      final detection = (uri: link, fromQr: result.qrLink != null);
      if (_detectedLink != detection) setState(() => _detectedLink = detection);
      _linkExpiry?.cancel();
      _linkExpiry = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(_clearDetectedLink);
      });
    } catch (error) {
      debugPrint('Could not scan camera preview: $error');
    } finally {
      _scanning = false;
    }
  }

  void _clearDetectedLink() {
    _linkExpiry?.cancel();
    _detectedLink = null;
  }

  void _takePicture() {
    final controller = _controller;
    if (controller == null || !_isPreviewing(controller)) return;
    setState(() {
      _capturing = true;
      _clearDetectedLink();
    });
    _cameraOperation = _cameraOperation.then((_) async {
      try {
        if (!mounted || !_foreground) return;
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
        final photo = await controller.takePicture();
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.pop(context, photo.path);
        } else {
          await _deleteCameraPhoto(photo.path);
        }
      } catch (error) {
        if (mounted) {
          _showCameraError(error);
        }
      } finally {
        if (mounted) setState(() => _capturing = false);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clearDetectedLink();
    _scanDelay?.cancel();
    unawaited(_cameraOperation.then((_) => _closeCamera()));
    super.dispose();
  }

  Widget _cameraFrame(Widget child) {
    return AspectRatio(
      key: ValueKey(
          widget.forCover ? 'cover-camera-frame' : 'note-camera-frame'),
      aspectRatio: _aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: _defaultNoteBlue, width: 3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: ClipRect(child: child),
        ),
      ),
    );
  }

  Widget _preview(CameraController controller) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return const SizedBox.shrink();
    final portrait = MediaQuery.orientationOf(context) == Orientation.portrait;
    final link = _detectedLink;
    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: portrait ? previewSize.height : previewSize.width,
            height: portrait ? previewSize.width : previewSize.height,
            child: CameraPreview(controller),
          ),
        ),
        if (link != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: Semantics(
              liveRegion: true,
              child: ColoredBox(
                color: _backgroundDark.withValues(alpha: 0.9),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    key: const ValueKey('camera-link-detected'),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppText(
                        link.fromQr ? 'QR link detected' : 'link detected',
                        style: const TextStyle(
                          color: _borderWhite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.onOpenLink case final open?)
                        InkWell(
                          key: const ValueKey('open-camera-link'),
                          onTap: () => open(link.uri),
                          child: Text(
                            link.uri.toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _noteLinkColour(Theme.of(context), true),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        )
                      else
                        Text(
                          link.uri.toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _borderWhite),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final alternate = _selectedCamera == _front ? _back : _front;
    return _popupAlert(
      context,
      key: ValueKey(
          widget.forCover ? 'cover-camera-dialog' : 'note-camera-dialog'),
      title: const AppText('camera'),
      content: SizedBox(
        width: widget.forCover ? 560 : 320,
        child: _cameraFrame(
          _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: AppText(_error!, textAlign: TextAlign.center),
                  ),
                )
              : controller == null || _opening
                  ? const Center(child: CircularProgressIndicator())
                  : _preview(controller),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _capturing ? null : () => Navigator.pop(context),
          child: const AppText('cancel'),
        ),
        if (_front != null && _back != null)
          IconButton(
            key: const ValueKey('switch-camera'),
            tooltip: localizeText(
              context,
              alternate == _front
                  ? 'switch to front camera'
                  : 'switch to back camera',
            ),
            onPressed: _capturing || _opening
                ? null
                : () {
                    _selectedCamera = alternate;
                    _openSelectedCamera();
                  },
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
        FilledButton.icon(
          key: ValueKey(
              widget.forCover ? 'take-cover-photo' : 'take-note-photo'),
          onPressed:
              controller == null || _opening || _error != null || _capturing
                  ? null
                  : _takePicture,
          icon: _capturing
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.camera_alt_outlined),
          label: const AppText('take photo'),
        ),
      ],
    );
  }
}
