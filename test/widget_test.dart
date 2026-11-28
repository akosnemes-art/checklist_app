import 'dart:io';

import 'package:checklist_app/app_version.dart';
import 'package:checklist_app/main.dart';
import 'package:checklist_app/services/ocr_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

base class _PickedImage extends PlatformFile {
  _PickedImage(this.filePath);

  final String filePath;

  @override
  String get name => filePath.split(Platform.pathSeparator).last;

  @override
  Uri get uri => Uri.file(filePath);

  @override
  Never get xFile => throw UnimplementedError();

  @override
  int? lengthSync() => File(filePath).lengthSync();

  @override
  Future<int?> length() async => File(filePath).length();

  @override
  Future<Uint8List> readAsBytes() => File(filePath).readAsBytes();

  @override
  Stream<Uint8List> readAsByteStream() =>
      File(filePath).openRead().map(Uint8List.fromList);
}

class _ImageFilePicker extends FilePickerPlatform {
  _ImageFilePicker(this.filePath);

  final String filePath;
  bool picked = false;
  FileType? pickedType;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    picked = true;
    pickedType = type;
    return _PickedImage(filePath);
  }
}

void main() {
  testWidgets('iPhone Notes sends a picked image to native OCR',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.lastSeenVersion.v1': checklistRelease,
      'checklist.notes.v1':
          '[{"id":"note","name":"Scan","createdAt":"2026-11-12T10:00:00Z","content":"","categoryId":null}]',
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final oldPicker = FilePickerPlatform.instance;
    final picker = _ImageFilePicker('/picked/letter.heic');
    FilePickerPlatform.instance = picker;
    addTearDown(() => FilePickerPlatform.instance = oldPicker);
    const channel = MethodChannel(OcrService.channelName);
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'recognisePhoto');
      expect(call.arguments, {'path': '/picked/letter.heic'});
      return {'text': 'Train tickets'};
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    final presentation = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byKey(const ValueKey('edge-to-edge-system-ui')),
    );
    expect(presentation.value.statusBarBrightness, Brightness.dark);
    await tester.tap(find.byTooltip('open menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('NOTES'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(375, 135));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('note-ocr-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('add picture'));
    await tester.pumpAndSettle();
    expect(picker.pickedType, FileType.image);
    expect(find.text('Train tickets'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    final saved = await SharedPreferences.getInstance();
    expect(saved.getString('checklist.notes.v1'), contains('Train tickets'));
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('checklist launches with a dated starter checklist', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'checklist.welcome.v1': true});
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('CHECKLIST'), findsOneWidget);
    expect(find.bySemanticsLabel('NOTES'), findsOneWidget);
    final checklistWord = tester.widget<AnimatedDefaultTextStyle>(
      find.byKey(const ValueKey('checklist-word-style')),
    );
    final notesWord = tester.widget<AnimatedDefaultTextStyle>(
      find.byKey(const ValueKey('notes-word-style')),
    );
    expect(checklistWord.style.color, const Color(0xFFF8F7FF));
    expect(notesWord.style.color, const Color(0xFF8C8791));
    expect(checklistWord.style.shadows, isNull);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('checklist-check-slot')),
        matching: find.byKey(const ValueKey('selected-mode-check')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('notes-check-slot')),
        matching: find.byKey(const ValueKey('selected-mode-check')),
      ),
      findsNothing,
    );
    final checkAlignment = tester.widget<Align>(
      find.byKey(const ValueKey('selected-mode-check-alignment')),
    );
    expect(checkAlignment.alignment, Alignment.center);
    final checkOffset = tester.widget<Transform>(
      find.byKey(const ValueKey('selected-mode-check-offset')),
    );
    expect(checkOffset.transform.storage[13], -1.5);
    final checklistSidebar = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('sidebar-surface')),
    );
    expect(
      (checklistSidebar.decoration! as BoxDecoration).color,
      const Color(0xFF26102F),
    );
    expect(find.text('my first checklist'), findsWidgets);
    expect(find.text('new checklist'), findsOneWidget);
    expect(find.textContaining(DateTime.now().year.toString()), findsWidgets);
    expect(find.text('medium'), findsOneWidget);
    expect(find.byTooltip('minimize'), findsNothing);
    expect(find.byTooltip('maximize or restore'), findsNothing);
    expect(find.byTooltip('close'), findsNothing);
    expect(find.text('your list starts here'), findsOneWidget);
    expect(find.textContaining('Write a task below'), findsNothing);
    expect(find.textContaining('add a task…'), findsOneWidget);
    final taskComposer = tester.widget<TextField>(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            (widget.decoration?.hintText?.startsWith('add a task…') ?? false),
      ),
    );
    expect(taskComposer.decoration?.hintStyle?.color, const Color(0xFF9AA0AA));

    final addCover = find.text('Add a cover image');
    await tester.tap(addCover);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cover-camera-option')), findsOneWidget);
    expect(find.byKey(const ValueKey('cover-browse-option')), findsOneWidget);
    expect(find.text('camera'), findsOneWidget);
    expect(find.text('browse'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('cover-camera-option'))).dy,
      greaterThan(tester.getBottomLeft(addCover).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('checklist progress bar remains brand yellow', (tester) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.projects.v1':
          '[{"id":"project-1","name":"Progress","createdAt":"2026-11-11T10:00:00.000Z","importance":"normal","coverImagePath":null,"tasks":[{"id":"task-1","text":"Keep the colour","isDone":false}]}]',
      'checklist.selectedProject.v1': 'project-1',
    });
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();

    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(progress.color, const Color(0xFFF3ED23));
    for (final key in ['sidebar-checklist-settings', 'task-settings']) {
      final settings = find.byKey(ValueKey(key));
      expect(settings, findsOneWidget);
      expect(
        find.descendant(
          of: settings,
          matching: find.byIcon(Icons.more_vert_rounded),
        ),
        findsOneWidget,
      );
    }
    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
    expect(find.byKey(const ValueKey('white-menu-frame')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('task-settings')).first);
    await tester.pumpAndSettle();
    expect(find.text('edit'), findsOneWidget);
    expect(find.text('delete'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('light mode uses warm grey surfaces and black progress', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.darkMode.v1': false,
      'checklist.projects.v1':
          '[{"id":"light","name":"Light greys","createdAt":"2026-11-20T10:00:00.000Z","importance":"normal","coverImagePath":null,"tasks":[{"id":"done","text":"Black text","isDone":true},{"id":"open","text":"Cold lines","isDone":false}]}]',
      'checklist.selectedProject.v1': 'light',
    });
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(Scaffold).first));
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF7F5F2));
    expect(theme.colorScheme.surface, const Color(0xFFE7E6E3));
    expect(theme.dividerColor, const Color(0xFF858C94));
    expect(theme.colorScheme.onSurface, const Color(0xFF101010));
    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(progress.color, const Color(0xFF101010));
    expect(progress.backgroundColor, const Color(0xFFD8D8D6));
    expect(
      (tester
              .widget<AnimatedContainer>(
                find.byKey(const ValueKey('sidebar-surface')),
              )
              .decoration! as BoxDecoration)
          .color,
      const Color(0xFFD5D4D1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'checklist reminder opens from sidebar and stays with selection',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'checklist.welcome.v1': true,
        'checklist.projects.v1':
            '[{"id":"reminder-project","name":"Remember me","createdAt":"2026-11-13T10:00:00.000Z","importance":"normal","coverImagePath":null,"tasks":[]}]',
        'checklist.selectedProject.v1': 'reminder-project',
      });
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const ChecklistApp());
      await tester.pumpAndSettle();

      final reminderButton = find.byKey(
        const ValueKey('checklist-reminder-button'),
      );
      expect(reminderButton, findsOneWidget);
      expect(
        find.descendant(
          of: reminderButton,
          matching: find.byIcon(Icons.calendar_month_outlined),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('sidebar-checklist-settings')),
      );
      await tester.pumpAndSettle();
      final reminderMenuItem = find.widgetWithText(
        PopupMenuItem<String>,
        'reminder',
      );
      expect(reminderMenuItem, findsOneWidget);
      await tester.tap(reminderMenuItem);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('checklist-reminder-dialog')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('checklist-reminder-calendar')),
        findsOneWidget,
      );
      final reminderDialog = find.byKey(
        const ValueKey('checklist-reminder-dialog'),
      );
      final reminderTitle = tester.widget<Text>(
        find.descendant(of: reminderDialog, matching: find.text('reminder')),
      );
      expect(reminderTitle.style?.fontWeight, FontWeight.w700);
      final dialogShape = Theme.of(tester.element(reminderDialog))
          .dialogTheme
          .shape! as RoundedRectangleBorder;
      expect(dialogShape.side.color, const Color(0xFF5A9BFF));
      expect(dialogShape.side.width, 2);
      expect(find.text('Remember me'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('save-checklist-reminder')));
      await tester.pumpAndSettle();

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString('checklist.projects.v1'),
        contains('"reminderAt":"'),
      );
      expect(
        find.descendant(
          of: reminderButton,
          matching: find.byIcon(Icons.event_available_outlined),
        ),
        findsOneWidget,
      );

      await tester.tap(reminderButton);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('remove-checklist-reminder')),
        findsOneWidget,
      );
      final openReminderDialog = find.byKey(
        const ValueKey('checklist-reminder-dialog'),
      );
      final cancelButton = find.descendant(
        of: openReminderDialog,
        matching: find.widgetWithText(TextButton, 'cancel'),
      );
      final removeButton = find.byKey(
        const ValueKey('remove-checklist-reminder'),
      );
      final saveButton = find.byKey(const ValueKey('save-checklist-reminder'));
      expect(
        tester.getCenter(cancelButton).dy,
        tester.getCenter(removeButton).dy,
      );
      expect(
        tester.getCenter(removeButton).dy,
        tester.getCenter(saveButton).dy,
      );
      expect(find.text('remove reminder'), findsNothing);
      await tester.tap(removeButton);
      await tester.pumpAndSettle();
      expect(
        preferences.getString('checklist.projects.v1'),
        contains('"reminderAt":null'),
      );
      expect(
        find.descendant(
          of: reminderButton,
          matching: find.byIcon(Icons.calendar_month_outlined),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reminder bells are white when upcoming and grey when past', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.projects.v1':
          '[{"id":"upcoming","name":"Upcoming","createdAt":"2026-11-13T10:00:00.000Z","importance":"normal","coverImagePath":null,"reminderAt":"2099-01-02T09:00:00.000","tasks":[]},{"id":"past","name":"Past","createdAt":"2026-11-12T10:00:00.000Z","importance":"normal","coverImagePath":null,"reminderAt":"2001-01-02T09:00:00.000","tasks":[]}]',
      'checklist.selectedProject.v1': 'upcoming',
    });
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();

    final upcomingBell = tester.widget<Icon>(
      find.byKey(const ValueKey('checklist-reminder-bell-upcoming')),
    );
    final pastBell = tester.widget<Icon>(
      find.byKey(const ValueKey('checklist-reminder-bell-past')),
    );
    expect(upcomingBell.icon, Icons.notifications_rounded);
    expect(upcomingBell.size, 18);
    expect(upcomingBell.color, const Color(0xFFF8F7FF));
    expect(pastBell.icon, Icons.notifications_rounded);
    expect(pastBell.size, 18);
    expect(pastBell.color, const Color(0xFF9AA0AA));
    final settings =
        find.byKey(const ValueKey('sidebar-checklist-settings')).first;
    expect(
      tester
          .getCenter(
            find.byKey(const ValueKey('checklist-reminder-bell-upcoming')),
          )
          .dy,
      tester.getCenter(settings).dy,
    );
    expect(
      tester.getTopLeft(settings).dx -
          tester
              .getTopRight(
                find.byKey(const ValueKey('checklist-reminder-bell-upcoming')),
              )
              .dx,
      2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('cover choices use matching framed camera and crop ratios', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'checklist.welcome.v1': true});
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final originalPicker = FilePickerPlatform.instance;
    final imagePicker = _ImageFilePicker(
      File('Checklist_app_icon_safe.png').absolute.path,
    );
    FilePickerPlatform.instance = imagePicker;
    addTearDown(() => FilePickerPlatform.instance = originalPicker);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add a cover image'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('camera'));
    await tester.pump(const Duration(milliseconds: 300));

    final cameraFrame = find.byKey(const ValueKey('cover-camera-frame'));
    expect(cameraFrame, findsOneWidget);
    expect(tester.widget<AspectRatio>(cameraFrame).aspectRatio, 16 / 9);
    final cameraDecoration = tester.widget<DecoratedBox>(
      find.descendant(of: cameraFrame, matching: find.byType(DecoratedBox)),
    );
    expect(
      (cameraDecoration.decoration as BoxDecoration).border,
      Border.all(color: const Color(0xFF5A9BFF), width: 3),
    );
    await tester.tap(find.widgetWithText(TextButton, 'cancel'));
    await tester.pumpAndSettle();

    FilePickerPlatform.instance = imagePicker;
    await tester.tap(find.text('Add a cover image'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('browse'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    for (var attempt = 0;
        attempt < 20 &&
            find.byKey(const ValueKey('cover-crop-frame')).evaluate().isEmpty;
        attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(imagePicker.picked, isTrue);
    expect(find.textContaining('Could not add that image'), findsNothing);
    expect(find.byKey(const ValueKey('cover-crop-dialog')), findsOneWidget);
    final cropFrame = find.byKey(const ValueKey('cover-crop-frame'));
    expect(cropFrame, findsOneWidget);
    final cropDecoration = tester.widget<DecoratedBox>(cropFrame);
    expect(
      (cropDecoration.decoration as BoxDecoration).border,
      Border.all(color: const Color(0xFF922FD0), width: 3),
    );
    final cropAspect = tester.widget<AspectRatio>(
      find.ancestor(of: cropFrame, matching: find.byType(AspectRatio)).first,
    );
    expect(cropAspect.aspectRatio, 16 / 9);
    await tester.tap(find.widgetWithText(TextButton, 'cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('cover remove button hides after two seconds and tap reveals it',
      (
    tester,
  ) async {
    final coverPath = File('Checklist_app_icon_safe.png').absolute.path;
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.projects.v1':
          '[{"id":"covered","name":"Covered","createdAt":"2026-11-13T10:00:00.000Z","importance":"normal","coverImagePath":"$coverPath","tasks":[]}]',
      'checklist.selectedProject.v1': 'covered',
    });
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Remove cover image'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byTooltip('Remove cover image'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byTooltip('Remove cover image'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove cover image'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('cover-image-interaction')));
    await tester.pump();
    expect(find.byTooltip('Remove cover image'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(find.byTooltip('Remove cover image'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byTooltip('Remove cover image'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byTooltip('Remove cover image'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove cover image'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Android task composer omits the done instruction', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'checklist.welcome.v1': true});
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();

    final composer = tester.widget<TextField>(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.hintText == 'add a task…',
      ),
    );
    expect(composer.decoration?.hintText, 'add a task…');
    expect(find.textContaining('tap done to add'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Android bottom controls stay above system navigation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'checklist.welcome.v1': true});
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();

    const navigationTop = 752.0;
    final composer = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == 'add a task…',
    );
    expect(tester.getBottomLeft(composer).dy, lessThan(navigationTop));

    await tester.tap(find.byTooltip('open menu'));
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(find.byKey(const ValueKey('settings-panel'))).dy,
      lessThanOrEqualTo(navigationTop),
    );
    expect(
      find.byKey(const ValueKey('mobile-sidebar-safe-area')),
      findsOneWidget,
    );
    final systemUi = tester
        .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byKey(const ValueKey('edge-to-edge-system-ui')),
        )
        .value;
    expect(systemUi.systemNavigationBarColor, Colors.transparent);
    expect(systemUi.systemNavigationBarContrastEnforced, isFalse);
    expect(systemUi.systemNavigationBarIconBrightness, Brightness.light);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Pastel drawer paints the bottom inset in both workspaces', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.theme.v1': 'pastel',
    });
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('open menu'));
    await tester.pumpAndSettle();

    final surface = find.byKey(const ValueKey('sidebar-surface'));
    final settings = find.byKey(const ValueKey('settings-panel'));
    void expectDrawer(Color color) {
      final decoration = tester.widget<AnimatedContainer>(surface).decoration!
          as BoxDecoration;
      expect(decoration.color, color);
      expect(tester.getBottomLeft(surface).dy, 800);
      expect(tester.getBottomLeft(settings).dy, lessThanOrEqualTo(776));
    }

    expectDrawer(const Color(0xFFE8FDF6));
    await tester.tap(find.bySemanticsLabel('NOTES'));
    await tester.pumpAndSettle();
    expectDrawer(const Color(0xFFE8FDF6));
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('tasks link to notes and open a scrollable note popup', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.projects.v1':
          '[{"id":"project-1","name":"Linked work","createdAt":"2026-11-13T10:00:00.000Z","importance":"normal","coverImagePath":null,"tasks":[{"id":"task-1","text":"Read the linked details and keep wrapping this task text","isDone":false},{"id":"task-2","text":"Ordinary task","isDone":false}]}]',
      'checklist.selectedProject.v1': 'project-1',
      'checklist.notes.v1':
          '[{"id":"note-1","name":"Useful note","createdAt":"2026-11-13T11:00:00.000Z","content":"A long note body that is \\uE000available\\uE001 inside the task popup.","categoryId":null}]',
      'checklist.selectedNote.v1': 'note-1',
    });
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();

    final checkbox = find.byKey(const ValueKey('task-checkbox-task-1'));
    final coverFrame = find.byKey(const ValueKey('cover-source-menu'));
    expect(tester.getTopLeft(checkbox).dx, tester.getTopLeft(coverFrame).dx);

    await tester.tap(find.byKey(const ValueKey('task-settings')).first);
    await tester.pumpAndSettle();
    expect(find.text('+ note'), findsOneWidget);
    await tester.tap(find.text('+ note'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('task-note-picker-list')), findsOneWidget);
    final pickerRow = find.byKey(const ValueKey('task-note-choice-note-1'));
    final subtitle = (tester.widget<ListTile>(pickerRow).subtitle as Text)
        .textSpan! as TextSpan;
    expect(subtitle.toPlainText(),
        'A long note body that is available inside the task popup.');
    expect(
        (subtitle.children![1] as TextSpan).style!.fontWeight, FontWeight.w700);
    await tester.tap(pickerRow);
    await tester.pumpAndSettle();

    final noteIcon = tester.widget<Icon>(
      find.byKey(const ValueKey('task-note-icon-task-1')),
    );
    expect(noteIcon.icon, Icons.sticky_note_2_rounded);
    expect(noteIcon.color, const Color(0xFFF3ED23));
    final ordinaryCheckbox = find.byKey(const ValueKey('task-checkbox-task-2'));
    expect(
      tester.getCenter(checkbox).dx,
      tester.getCenter(ordinaryCheckbox).dx,
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('task-note-button-task-1')))
          .dy,
      greaterThanOrEqualTo(tester.getBottomLeft(checkbox).dy),
    );
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('checklist.projects.v1'),
      contains('"linkedNoteId":"note-1"'),
    );

    await tester.tap(find.byKey(const ValueKey('task-note-button-task-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester
          .widget<Icon>(find.byKey(const ValueKey('task-note-icon-task-1')))
          .color,
      const Color(0xFF922FD0),
    );
    expect(find.byKey(const ValueKey('task-linked-note-dialog')), findsNothing);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('task-linked-note-dialog')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('task-linked-note-scroll')),
      findsOneWidget,
    );
    expect(find.text('Useful note'), findsOneWidget);
    expect(find.textContaining('A long note body'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (theme, buttonColour, frameColour, linkColour) in [
    (
      'boi',
      const Color(0xFFF3ED23),
      const Color(0xFF5A9BFF),
      const Color(0xFFF3ED23)
    ),
    (
      'pencil',
      const Color(0xFF5A9BFF),
      const Color(0xFF858C94),
      const Color(0xFF5A9BFF)
    ),
    ('pastel', const Color(0xFF5A9BFF), null, const Color(0xFF1553A3)),
  ]) {
    testWidgets('linked note formatting and colours in $theme', (tester) async {
      SharedPreferences.setMockInitialValues({
        'checklist.welcome.v1': true,
        'checklist.theme.v1': theme,
        'checklist.projects.v1':
            '[{"id":"project","name":"Read","createdAt":"2026-11-13","tasks":[{"id":"task","text":"Review","linkedNoteId":"note"}]}]',
        'checklist.notes.v1':
            '[{"id":"note","name":"Linked note","createdAt":"2026-11-13","content":"Plain \\uE000\\uE002\\uE004combined\\uE001\\uE003\\uE005 and **legacy bold**, *legacy italic*, __legacy underline__ and https://example.org."}]',
      });
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      final messenger = tester.binding.defaultBinaryMessenger;
      final opened = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        opened.add(call);
        return true;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      await tester.pumpWidget(const ChecklistApp());
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Icon>(find.byKey(const ValueKey('task-note-icon-task')))
            .color,
        buttonColour,
      );
      await tester.tap(find.byKey(const ValueKey('task-note-button-task')));
      await tester.pumpAndSettle();
      final dialog = find.byKey(const ValueKey('task-linked-note-dialog'));
      final shape =
          tester.widget<AlertDialog>(dialog).shape! as RoundedRectangleBorder;
      expect(
        shape.side,
        frameColour == null
            ? BorderSide.none
            : BorderSide(color: frameColour, width: 2),
      );
      expect(shape.borderRadius,
          theme == 'pastel' ? BorderRadius.circular(18) : BorderRadius.zero);

      final noteBody = find.descendant(
        of: dialog,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.textSpan?.toPlainText().startsWith('Plain combined') ??
                  false),
        ),
      );
      final note = tester.widget<Text>(noteBody).textSpan! as TextSpan;
      expect(
        note.toPlainText(),
        'Plain combined and legacy bold, legacy italic, legacy underline and https://example.org.',
      );
      final runs = {
        for (final span in note.children!.cast<TextSpan>())
          span.text!: span.style!,
      };
      expect(runs['combined']!.fontWeight, FontWeight.w700);
      expect(runs['combined']!.fontStyle, FontStyle.italic);
      expect(runs['combined']!.decoration, TextDecoration.underline);
      expect(runs['legacy bold']!.fontWeight, FontWeight.w700);
      expect(runs['legacy italic']!.fontStyle, FontStyle.italic);
      expect(runs['legacy underline']!.decoration, TextDecoration.underline);
      expect(runs['https://example.org']!.decoration, TextDecoration.underline);
      expect(runs['https://example.org']!.color, linkColour);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: noteBody, matching: find.byType(RichText)),
      );
      final urlStart = note.toPlainText().indexOf('https:');
      final box = paragraph
          .getBoxesForSelection(TextSelection(
            baseOffset: urlStart,
            extentOffset: urlStart + 5,
          ))
          .first;
      await tester.tapAt(paragraph.localToGlobal(box.toRect().center));
      await tester.pump();
      expect(opened.single.arguments['url'], 'https://example.org');
      expect(opened.single.arguments['useWebView'], isFalse);
    });
  }

  testWidgets('wordmark switches layouts and settings changes themes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'checklist.welcome.v1': true});
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('NOTES'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AnimatedDefaultTextStyle>(
            find.byKey(const ValueKey('checklist-word-style')),
          )
          .style
          .color,
      const Color(0xFF8C8791),
    );
    expect(
      tester
          .widget<AnimatedDefaultTextStyle>(
            find.byKey(const ValueKey('notes-word-style')),
          )
          .style
          .color,
      const Color(0xFFF8F7FF),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('notes-check-slot')),
        matching: find.byKey(const ValueKey('selected-mode-check')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('checklist-check-slot')),
        matching: find.byKey(const ValueKey('selected-mode-check')),
      ),
      findsNothing,
    );
    expect(find.text('your notes'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'notes'), findsNothing);
    expect(find.text('new note'), findsOneWidget);
    expect(find.text('new checklist'), findsNothing);
    expect(find.text('YOUR NOTES'), findsOneWidget);
    expect(find.byKey(const ValueKey('notes-sidebar-list')), findsOneWidget);
    final sidebar = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('sidebar-surface')),
    );
    expect(
      (sidebar.decoration! as BoxDecoration).color,
      const Color(0xFF0B1D3B),
    );

    expect(find.text('dark'), findsNothing);
    expect(find.text('light'), findsNothing);
    expect(find.byKey(const ValueKey('appearance-switch')), findsNothing);
    final settingsLabel = find.text('settings');
    final settingsVersion = find.byKey(const ValueKey('settings-version'));
    expect(tester.widget<Text>(settingsVersion).data, checklistVersion);
    expect(
      tester.widget<Text>(settingsVersion).style!.fontSize,
      tester.widget<Text>(settingsLabel).style!.fontSize! / 2,
    );
    expect(
      tester.getTopLeft(settingsVersion).dy,
      greaterThan(tester.getBottomLeft(settingsLabel).dy),
    );
    expect(
      tester.getTopLeft(settingsVersion).dx,
      tester.getTopLeft(settingsLabel).dx,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('settings-expanding-line')))
          .width,
      248,
    );

    await tester.tap(find.byKey(const ValueKey('settings-toggle')));
    await tester.pumpAndSettle();
    expect(settingsVersion, findsOneWidget);
    expect(find.byKey(const ValueKey('settings-main')), findsOneWidget);
    expect(find.text('themes'), findsOneWidget);
    expect(find.text('language'), findsOneWidget);
    expect(find.text('import / export'), findsOneWidget);
    expect(find.text('about'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('settings-expanding-line')))
          .width,
      248,
    );

    await tester.tap(find.byKey(const ValueKey('settings-themes')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-main')), findsNothing);
    expect(
      find.byKey(const ValueKey('settings-theme-choices')),
      findsOneWidget,
    );
    expect(find.text('Boi'), findsOneWidget);
    expect(find.text('Pencil'), findsOneWidget);
    expect(find.text('Blue milk'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('theme-pencil')));
    await tester.pumpAndSettle();
    var modeTheme = Theme.of(tester.element(find.byType(Scaffold).first));
    expect(modeTheme.scaffoldBackgroundColor, const Color(0xFFF7F5F2));
    await tester.tap(find.bySemanticsLabel('CHECKLIST'));
    await tester.pumpAndSettle();
    final pencilMediumChip = tester.widget<Container>(
      find.byKey(const ValueKey('priority-chip-normal')),
    );
    expect(
      (pencilMediumChip.decoration! as BoxDecoration).border!.top.color,
      const Color(0xFF64696A),
    );
    await tester.tap(find.byKey(const ValueKey('priority-chip-normal')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Container>(find.byKey(const ValueKey('priority-menu-high')))
          .color,
      const Color(0xFF0E2F44),
    );
    expect(
      tester
          .widget<Container>(find.byKey(const ValueKey('priority-menu-normal')))
          .color,
      const Color(0xFF64696A),
    );
    expect(
      tester
          .widget<Container>(find.byKey(const ValueKey('priority-menu-low')))
          .color,
      const Color(0xFF999999),
    );
    await tester.tapAt(const Offset(1100, 700));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('NOTES'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('theme-pastel')));
    await tester.pumpAndSettle();
    modeTheme = Theme.of(tester.element(find.byType(Scaffold).first));
    expect(modeTheme.scaffoldBackgroundColor, const Color(0xFFE8FDF6));
    expect(modeTheme.colorScheme.surface, const Color(0xFFE8FDF6));
    expect(modeTheme.colorScheme.secondary, const Color(0xFFE4DBF7));
    expect(modeTheme.dividerColor, const Color(0xFFC4D0DC));
    final pastelSidebar = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('sidebar-surface')),
    );
    expect(
      (pastelSidebar.decoration! as BoxDecoration).color,
      const Color(0xFFE8FDF6),
    );
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('checklist.theme.v1'), 'pastel');

    await tester.tap(find.bySemanticsLabel('CHECKLIST'));
    await tester.pumpAndSettle();
    final mediumChip = tester.widget<Container>(
      find.byKey(const ValueKey('priority-chip-normal')),
    );
    expect(mediumChip.decoration, isNull);
    await tester.tap(find.byKey(const ValueKey('priority-chip-normal')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Container>(find.byKey(const ValueKey('priority-menu-high')))
          .decoration,
      BoxDecoration(
          color: const Color(0xFFE31F26),
          borderRadius: BorderRadius.circular(2.5)),
    );
    expect(
      tester
          .widget<Container>(find.byKey(const ValueKey('priority-menu-normal')))
          .decoration,
      BoxDecoration(
          color: const Color(0xFF00978D),
          borderRadius: BorderRadius.circular(2.5)),
    );
    expect(
      tester
          .widget<Container>(find.byKey(const ValueKey('priority-menu-low')))
          .decoration,
      BoxDecoration(
          color: const Color(0xFFB5B1D8),
          borderRadius: BorderRadius.circular(2.5)),
    );
    await tester.tapAt(const Offset(1100, 700));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-language')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('settings-language-page')),
      findsOneWidget,
    );
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Hungarian'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('language-hungarian')));
    await tester.pumpAndSettle();
    expect(find.text('Magyar'), findsOneWidget);
    expect(preferences.getString('checklist.language.v1'), 'hungarian');
    await tester.tap(find.byKey(const ValueKey('settings-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-backup')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-backup-page')), findsOneWidget);
    expect(find.text('adatok exportálása'), findsOneWidget);
    expect(find.text('adatok importálása'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('settings-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-about')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-about-page')), findsOneWidget);
    expect(find.textContaining('Ákos Nemes'), findsOneWidget);
    expect(find.text('akosnemes@proton.me'), findsNothing);
    expect(find.byKey(const ValueKey('about-credits')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('seven hidden taps toggle the persisted heart animation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'checklist.welcome.v1': true});
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    final trigger = find.byKey(const ValueKey('heart-animation-trigger'));

    for (var tap = 0; tap < 7; tap++) {
      await tester.tap(trigger);
    }
    await tester.pumpAndSettle();
    var preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('checklist.heartAnimation.v1'), isTrue);

    for (var tap = 0; tap < 7; tap++) {
      await tester.tap(trigger);
    }
    await tester.pumpAndSettle();
    preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('checklist.heartAnimation.v1'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('three middle taps show version features and maker credits', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'checklist.welcome.v1': true});
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    final trigger = find.byKey(const ValueKey('heart-animation-trigger'));
    await tester.tap(trigger);
    await tester.tap(trigger);
    await tester.tap(trigger);
    await tester.pump(const Duration(milliseconds: 455));

    expect(find.byKey(const ValueKey('version-info-dialog')), findsOneWidget);
    expect(find.text('CHECKLIST $checklistVersion'), findsOneWidget);
    expect(find.text('build $checklistBuildNumber'), findsOneWidget);
    expect(find.textContaining('detected bold, italic, and underlined text'),
        findsOneWidget);
    expect(find.text('Makers: Ákos Nemes · Codex AI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('note formatting renders and selection tools stay borderless', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.notes.v1':
          '[{"id":"note-format","name":"Format me","createdAt":"2026-11-20T10:00:00.000Z","content":"word","categoryId":null}]',
      'checklist.selectedNote.v1': 'note-format',
    });
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('NOTES'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('note-format-toolbar')), findsOneWidget);
    for (final name in ['bold', 'italic', 'underline']) {
      final button = tester.widget<IconButton>(
        find.byKey(ValueKey('note-format-$name')),
      );
      expect(button.style?.side?.resolve({}), BorderSide.none);
      expect(
        button.style?.foregroundColor?.resolve({}),
        const Color(0xFF5A9BFF),
      );
    }

    final editorFinder = find.byKey(const ValueKey('note-content-field'));
    final editor = tester.widget<TextField>(editorFinder);
    await tester.tap(editorFinder);
    await tester.pump();
    expect(editor.focusNode?.hasFocus, isTrue);
    editor.controller!.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 4,
    );
    await tester.tap(find.byKey(const ValueKey('note-format-bold')));
    await tester.pump();
    expect(editor.controller!.text, '\uE000word\uE001');
    final bold = tester.widget<IconButton>(
      find.byKey(const ValueKey('note-format-bold')),
    );
    expect(bold.style?.foregroundColor?.resolve({}), const Color(0xFFF3ED23));
    expect(editor.focusNode?.hasFocus, isTrue);

    editor.controller!.selection = const TextSelection(
      baseOffset: 1,
      extentOffset: 5,
    );
    await tester.tap(find.byKey(const ValueKey('note-format-italic')));
    await tester.pump();
    editor.controller!.selection = const TextSelection(
      baseOffset: 2,
      extentOffset: 6,
    );
    await tester.tap(find.byKey(const ValueKey('note-format-underline')));
    await tester.pump();
    final rendered = editor.controller!.buildTextSpan(
      context: tester.element(editorFinder),
      style: const TextStyle(),
      withComposing: false,
    );
    final wordSpan = rendered.children!.whereType<TextSpan>().firstWhere(
          (span) => span.text == 'word',
        );
    expect(wordSpan.style?.fontWeight, FontWeight.w700);
    expect(wordSpan.style?.fontStyle, FontStyle.italic);
    expect(wordSpan.style?.decoration, TextDecoration.underline);

    final editableState = tester.state<EditableTextState>(
      find.descendant(of: editorFinder, matching: find.byType(EditableText)),
    );
    editableState.widget.focusNode.requestFocus();
    editor.controller!.selection = const TextSelection(
      baseOffset: 3,
      extentOffset: 7,
    );
    await tester.pump();
    final selectionToolbar = editor.contextMenuBuilder!(
      tester.element(editorFinder),
      editableState,
    ) as TextSelectionToolbar;
    expect(selectionToolbar.key, const ValueKey('note-selection-toolbar'));
    final toolbarSurface = selectionToolbar.toolbarBuilder(
      tester.element(editorFinder),
      const SizedBox(),
    ) as Material;
    expect(
      toolbarSurface.key,
      const ValueKey('note-selection-toolbar-surface'),
    );
    expect(
      (toolbarSurface.shape! as RoundedRectangleBorder).side,
      BorderSide.none,
    );
    expect(
      selectionToolbar.children.map((button) => button.key),
      containsAll(const [
        ValueKey('note-selection-format-bold'),
        ValueKey('note-selection-format-italic'),
        ValueKey('note-selection-format-underline'),
      ]),
    );

    editor.controller!.value = const TextEditingValue(
      selection: TextSelection.collapsed(offset: 0),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('note-format-bold')));
    await tester.pump();
    expect(editor.controller!.text, '\uE000\uE001');
    expect(editor.controller!.selection.extentOffset, 1);
    editor.controller!.value = const TextEditingValue(
      text: '\uE000x\uE001',
      selection: TextSelection.collapsed(offset: 2),
    );
    await tester.pump();
    final typedSpan = editor.controller!.buildTextSpan(
      context: tester.element(editorFinder),
      style: const TextStyle(),
      withComposing: false,
    );
    expect(
      typedSpan.children!
          .whereType<TextSpan>()
          .firstWhere((span) => span.text == 'x')
          .style
          ?.fontWeight,
      FontWeight.w700,
    );
    await tester.tap(find.byKey(const ValueKey('note-format-bold')));
    await tester.pump();
    expect(editor.controller!.selection.extentOffset, 3);
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('note-format-bold')))
          .style
          ?.foregroundColor
          ?.resolve({}),
      const Color(0xFF5A9BFF),
    );
    await tester.pump(const Duration(milliseconds: 300));
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('checklist.notes.v1'),
      contains('\uE000x\uE001'),
    );
    final noteTitle = find.descendant(
      of: find.byKey(const ValueKey('note-editor')),
      matching: find.text('Format me'),
    );
    await tester.tap(noteTitle);
    await tester.pump();
    expect(editor.focusNode?.hasFocus, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a 140 ms hold on task text reprioritises checklist items', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.projects.v1':
          '[{"id":"reorder","name":"Order","createdAt":"2026-11-20T10:00:00.000Z","importance":"normal","coverImagePath":null,"tasks":[{"id":"first","text":"First","isDone":false},{"id":"second","text":"Second","isDone":false},{"id":"third","text":"Third","isDone":false}]}]',
      'checklist.selectedProject.v1': 'reorder',
    });
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.drag_indicator_rounded), findsNothing);
    expect(
      find.byKey(const ValueKey('task-reorder-area-third')),
      findsOneWidget,
    );

    final thirdCheckbox = find.byKey(const ValueKey('task-checkbox-third'));
    await tester.tap(thirdCheckbox);
    await tester.pumpAndSettle();
    var preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('checklist.projects.v1'),
      contains('"text":"Third","isDone":true'),
    );
    await tester.tap(thirdCheckbox);
    await tester.pumpAndSettle();

    final checkboxGesture = await tester.startGesture(
      tester.getCenter(thirdCheckbox),
    );
    await tester.pump(const Duration(milliseconds: 141));
    await checkboxGesture.moveTo(tester.getCenter(find.text('First')));
    await tester.pump(const Duration(milliseconds: 300));
    await checkboxGesture.up();
    await tester.pumpAndSettle();
    preferences = await SharedPreferences.getInstance();
    var saved = preferences.getString('checklist.projects.v1')!;
    expect(saved.indexOf('Third'), greaterThan(saved.indexOf('First')));

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Third')),
    );
    await tester.pump(const Duration(milliseconds: 139));
    await tester.pump(const Duration(milliseconds: 2));
    await gesture.moveTo(tester.getCenter(find.text('First')));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();

    preferences = await SharedPreferences.getInstance();
    saved = preferences.getString('checklist.projects.v1')!;
    expect(saved.indexOf('Third'), lessThan(saved.indexOf('First')));
    expect(
      tester.getTopLeft(find.text('Third')).dy,
      lessThan(tester.getTopLeft(find.text('First')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sort button offers A-Z, date, and priority choices', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'checklist.welcome.v1': true});
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('sort checklists'));
    await tester.pumpAndSettle();

    expect(find.text('a–z'), findsOneWidget);
    expect(find.text('date · newest'), findsOneWidget);
    expect(find.text('date · oldest'), findsOneWidget);
    expect(find.text('priority · high first'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new checklist has a neutral name field and medium priority', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'checklist.welcome.v1': true});
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('new checklist'));
    await tester.pumpAndSettle();

    expect(find.text('name it'), findsNothing);
    expect(find.text('priority'), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
    final dialogField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    final nameField = tester.widget<TextField>(dialogField);
    expect(nameField.decoration?.hintText, 'checklist name');
    expect(nameField.decoration?.hintStyle?.color, const Color(0xFF9AA0AA));

    await tester.enterText(dialogField, 'Neutral checklist');
    final create = find.byKey(const ValueKey('create-checklist'));
    final normalButton = tester.widget<FilledButton>(
      find.descendant(of: create, matching: find.byType(FilledButton)),
    );
    final normalColour = normalButton.style?.backgroundColor?.resolve({});
    await tester.tap(create);
    await tester.pump();
    final brightButton = tester.widget<FilledButton>(
      find.descendant(of: create, matching: find.byType(FilledButton)),
    );
    expect(
      brightButton.style?.backgroundColor?.resolve({}),
      isNot(normalColour),
    );
    await tester.pump(const Duration(milliseconds: 59));
    expect(find.text('Neutral checklist'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Neutral checklist'), findsWidgets);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('checklist.projects.v1'),
      contains('"importance":"normal"'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing the mobile drawer resets Settings to its main page',
      (tester) async {
    SharedPreferences.setMockInitialValues({'checklist.welcome.v1': true});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> tap(Finder finder) async {
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    final opener = find.byTooltip('open menu');
    final settings = find.byKey(const ValueKey('settings-toggle'));
    final themes = find.byKey(const ValueKey('settings-themes'));
    await tap(opener);
    await tap(settings);
    await tap(themes);
    expect(find.text('Blue milk'), findsOneWidget);

    await tester.tapAt(const Offset(360, 385));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsNothing);
    await tap(opener);
    expect(find.text('Blue milk'), findsNothing);
    expect(themes, findsNothing);
    await tap(settings);
    expect(themes, findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('mobile drawer stays open across modes and opens by edge swipe', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'checklist.welcome.v1': true});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('open menu'));
    await tester.pumpAndSettle();

    final wordmark = find.bySemanticsLabel('CHECKLIST');
    final sortButton = find.byWidgetPredicate(
      (widget) =>
          widget is PopupMenuButton<ProjectSort> &&
          widget.tooltip == 'sort checklists',
    );
    final sortIcon = find.byIcon(Icons.sort_rounded);
    final filterFrame = find.byKey(const ValueKey('sidebar-filter-frame'));
    final brandCheck = find.byIcon(Icons.check_rounded);
    final brandText = find.text('CHECKLIST');
    final newChecklistButton = find.widgetWithText(
      FilledButton,
      'new checklist',
    );
    expect(wordmark, findsOneWidget);
    expect(brandCheck, findsOneWidget);
    final sidebar = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('sidebar-surface')),
    );
    expect(sidebar.padding!.resolve(TextDirection.ltr).top, 27.5);
    expect(tester.getTopLeft(brandText).dy, inInclusiveRange(27.5, 41.5));
    expect(
      tester.getTopLeft(newChecklistButton).dy -
          tester.getBottomRight(brandText).dy,
      inInclusiveRange(3, 10),
    );
    expect(tester.getTopLeft(sortButton).dy, greaterThanOrEqualTo(32));
    expect(
      tester.getCenter(newChecklistButton).dy,
      tester.getCenter(sortButton).dy,
    );
    expect(
      tester.getTopLeft(filterFrame).dx -
          tester.getTopRight(newChecklistButton).dx,
      8,
    );
    expect(sortIcon, findsOneWidget);
    expect(find.textContaining(DateTime.now().year.toString()), findsWidgets);

    await tester.tap(find.bySemanticsLabel('NOTES'));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text('new note'), findsOneWidget);
    expect(find.text('YOUR NOTES'), findsOneWidget);
    expect(find.byTooltip('sort notes'), findsOneWidget);
    expect(
      tester.getSize(find.widgetWithText(FilledButton, 'new note')).height,
      tester.getSize(find.byKey(const ValueKey('sidebar-filter-frame'))).height,
    );
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);

    await tester.tap(find.bySemanticsLabel('CHECKLIST'));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text('new checklist'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('NOTES'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(360, 400));
    await tester.pumpAndSettle();
    expect(find.byTooltip('open menu'), findsNothing);

    await tester.dragFrom(const Offset(1, 400), const Offset(280, 0));
    await tester.pumpAndSettle();
    expect(find.text('new note'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'notes use blue themes, category creation fields, and note sorting',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'checklist.welcome.v1': true,
        'checklist.noteCategories.v1':
            '[{"id":"ideas","name":"Ideas","colorValue":4278571494}]',
      });
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const ChecklistApp());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('NOTES'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('sort notes'), findsOneWidget);
      await tester.tap(find.byTooltip('sort notes'));
      await tester.pumpAndSettle();
      expect(find.text('date · newest'), findsOneWidget);
      expect(find.text('date · oldest'), findsOneWidget);
      expect(find.text('a–z'), findsOneWidget);
      expect(find.text('category · a–z'), findsOneWidget);
      await tester.tap(
        find.widgetWithText(CheckedPopupMenuItem<NoteSort>, 'category · a–z'),
      );
      await tester.pumpAndSettle();

      var modeTheme = Theme.of(tester.element(find.byType(Scaffold).first));
      expect(modeTheme.colorScheme.primary, const Color(0xFF5A9BFF));
      expect(find.byKey(const ValueKey('appearance-switch')), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'new note'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('note-details-dialog')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('note-category-selector')),
        findsOneWidget,
      );
      final dialogTheme = tester.widget<Theme>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('note-details-dialog')),
              matching: find.byType(Theme),
            )
            .first,
      );
      expect(dialogTheme.data.colorScheme.primary, const Color(0xFF5A9BFF));
      expect(
        (dialogTheme.data.inputDecorationTheme.enabledBorder!
                as OutlineInputBorder)
            .borderSide
            .color,
        const Color(0xFFF8F7FF),
      );

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('note-details-dialog')),
          matching: find.byType(TextField),
        ),
        'Blue note',
      );
      await tester.tap(find.byKey(const ValueKey('note-category-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ideas').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'save'));
      await tester.pumpAndSettle();
      expect(find.text('Blue note'), findsWidgets);
      expect(find.byKey(const ValueKey('white-menu-frame')), findsNothing);
      for (final key in ['sidebar-note-settings', 'note-header-settings']) {
        final settings = find.byKey(ValueKey(key));
        expect(settings, findsOneWidget);
        expect(
          find.descendant(
            of: settings,
            matching: find.byIcon(Icons.more_vert_rounded),
          ),
          findsOneWidget,
        );
      }
      expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);

      final createButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('sidebar-create-button')),
      );
      expect(
        createButton.style?.side?.resolve({})?.color,
        const Color(0xFFF8F7FF),
      );
      final filterFrame = tester.widget<Container>(
        find.byKey(const ValueKey('sidebar-filter-frame')),
      );
      expect(
        ((filterFrame.decoration! as BoxDecoration).border! as Border)
            .top
            .color,
        const Color(0xFFF8F7FF),
      );

      await tester.tap(find.byKey(const ValueKey('settings-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-themes')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('theme-pencil')));
      await tester.pumpAndSettle();
      modeTheme = Theme.of(tester.element(find.byType(Scaffold).first));
      expect(modeTheme.brightness, Brightness.light);
      expect(modeTheme.colorScheme.primary, const Color(0xFF666B70));
      final notesLightSidebar = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('sidebar-surface')),
      );
      expect(
        (notesLightSidebar.decoration! as BoxDecoration).color,
        const Color(0xFFD5D4D1),
      );

      await tester.tap(find.bySemanticsLabel('CHECKLIST'));
      await tester.pumpAndSettle();
      final checklistLightSidebar = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('sidebar-surface')),
      );
      expect(
        (checklistLightSidebar.decoration! as BoxDecoration).color,
        const Color(0xFFD5D4D1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('category settings edit and animate category removal', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.noteCategories.v1':
          '[{"id":"ideas","name":"Ideas","colorValue":4278571494}]',
      'checklist.notes.v1':
          '[{"id":"note-1","name":"Plan","createdAt":"2026-11-10T10:00:00.000Z","content":"Draft","categoryId":"ideas"}]',
      'checklist.selectedNote.v1': 'note-1',
    });
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('NOTES'));
    await tester.pumpAndSettle();

    final sidebarSettings = find.byKey(const ValueKey('sidebar-note-settings'));
    expect(sidebarSettings, findsOneWidget);
    expect(
      find.ancestor(
        of: sidebarSettings,
        matching: find.byKey(const ValueKey('white-menu-frame')),
      ),
      findsNothing,
    );
    await tester.tap(sidebarSettings);
    await tester.pumpAndSettle();
    expect(find.text('category settings'), findsOneWidget);
    await tester.tap(find.text('category settings'));
    await tester.pumpAndSettle();

    final settingsDialog = find.byKey(
      const ValueKey('category-settings-dialog'),
    );
    expect(settingsDialog, findsOneWidget);
    await tester.tap(
      find.descendant(of: settingsDialog, matching: find.text('Ideas')),
    );
    await tester.pumpAndSettle();
    expect(find.text('edit category'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Projects',
    );
    await tester.tap(find.bySemanticsLabel('colour 3'));
    await tester.tap(find.widgetWithText(FilledButton, 'save'));
    await tester.pumpAndSettle();
    expect(find.text('Projects'), findsWidgets);

    await tester.tap(find.byTooltip('note options').last);
    await tester.pumpAndSettle();
    expect(find.text('category settings'), findsOneWidget);
    await tester.tapAt(const Offset(900, 700));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('change category'));
    await tester.pumpAndSettle();
    expect(find.text('remove'), findsOneWidget);
    final categoryActionRow = find.byKey(const ValueKey('category-action-row'));
    final newCategoryButton = find.descendant(
      of: categoryActionRow,
      matching: find.widgetWithText(FilledButton, 'new'),
    );
    final removeCategoryButton = find.descendant(
      of: categoryActionRow,
      matching: find.widgetWithText(FilledButton, 'remove'),
    );
    final cancelButton = find.byKey(const ValueKey('category-cancel-button'));
    expect(
      tester.getCenter(newCategoryButton).dy,
      tester.getCenter(removeCategoryButton).dy,
    );
    expect(
      tester.getCenter(removeCategoryButton).dy,
      tester.getCenter(cancelButton).dy,
    );
    final cancel = tester.widget<TextButton>(cancelButton);
    expect(cancel.style?.backgroundColor?.resolve({}), Colors.transparent);
    expect(cancel.style?.foregroundColor?.resolve({}), const Color(0xFF9AA0AA));
    expect(
      cancel.style?.side?.resolve({}),
      const BorderSide(color: Color(0xFF5A9BFF), width: 2),
    );
    final newButton = tester.widget<FilledButton>(newCategoryButton);
    final removeButton = tester.widget<FilledButton>(removeCategoryButton);
    for (final button in [newButton, removeButton]) {
      expect(
        button.style?.backgroundColor?.resolve({}),
        const Color(0xFF1553A3),
      );
      expect(
        button.style?.foregroundColor?.resolve({}),
        const Color(0xFFF8F7FF),
      );
      expect(
        button.style?.side?.resolve({}),
        const BorderSide(color: Color(0xFFF8F7FF), width: 2),
      );
    }
    expect(
      tester.getCenter(cancelButton).dx,
      lessThan(tester.getCenter(newCategoryButton).dx),
    );
    expect(
      tester.getCenter(newCategoryButton).dx,
      lessThan(tester.getCenter(removeCategoryButton).dx),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'remove'));
    await tester.pumpAndSettle();

    final picker = find.byKey(const ValueKey('category-picker-dialog'));
    final categoryName = find.descendant(
      of: picker,
      matching: find.text('Projects'),
    );
    await tester.tap(categoryName);
    await tester.pump(const Duration(milliseconds: 200));
    final removalIndicator = find.byKey(
      const ValueKey('remove-category-ideas'),
    );
    expect(
      find.descendant(
        of: removalIndicator,
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
    final crossedName = tester.widget<AnimatedDefaultTextStyle>(
      find
          .ancestor(
            of: categoryName,
            matching: find.byType(AnimatedDefaultTextStyle),
          )
          .first,
    );
    expect(crossedName.style.decoration, TextDecoration.lineThrough);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(categoryName, findsNothing);
    await tester.tap(find.widgetWithText(TextButton, 'cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Projects'), findsNothing);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('checklist.noteCategories.v1'), '[]');
    expect(
      preferences.getString('checklist.notes.v1'),
      contains('"categoryId":null'),
    );
    expect(tester.takeException(), isNull);
  });
}
