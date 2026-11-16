import 'dart:io';
import 'dart:typed_data';

import 'package:checklist_app/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
    return _PickedImage(filePath);
  }
}

void main() {
  testWidgets('checklist launches with a dated starter checklist',
      (tester) async {
    SharedPreferences.setMockInitialValues({'checklist.welcome.v1': true});
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );

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
    expect(find.byTooltip('minimize'), findsOneWidget);
    expect(find.byTooltip('maximize or restore'), findsOneWidget);
    expect(find.byTooltip('close'), findsOneWidget);
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

    await tester.tap(find.byKey(const ValueKey('task-settings')));
    await tester.pumpAndSettle();
    expect(find.text('edit'), findsOneWidget);
    expect(find.text('delete'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checklist reminder opens from sidebar and stays with selection',
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

    await tester.tap(find.byKey(const ValueKey('sidebar-checklist-settings')));
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
    final reminderDialog = find.byKey(
      const ValueKey('checklist-reminder-dialog'),
    );
    final cancelButton = find.descendant(
      of: reminderDialog,
      matching: find.widgetWithText(TextButton, 'cancel'),
    );
    final removeButton = find.byKey(
      const ValueKey('remove-checklist-reminder'),
    );
    final saveButton = find.byKey(
      const ValueKey('save-checklist-reminder'),
    );
    expect(
        tester.getCenter(cancelButton).dy, tester.getCenter(removeButton).dy);
    expect(tester.getCenter(removeButton).dy, tester.getCenter(saveButton).dy);
    expect(find.text('remove reminder'), findsNothing);
    await tester.tap(
      removeButton,
    );
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
  });

  testWidgets('reminder bells are white when upcoming and grey when past',
      (tester) async {
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
                find.byKey(
                  const ValueKey('checklist-reminder-bell-upcoming'),
                ),
              )
              .dx,
      2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('cover choices use matching framed camera and crop ratios',
      (tester) async {
    SharedPreferences.setMockInitialValues({'checklist.welcome.v1': true});
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final originalPicker = FilePickerPlatform.instance;
    final imagePicker = _ImageFilePicker(
      File('Checklist_app_logo.png').absolute.path,
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
      find.descendant(
        of: cameraFrame,
        matching: find.byType(DecoratedBox),
      ),
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
      (tester) async {
    final coverPath = File('Checklist_app_logo.png').absolute.path;
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

  testWidgets('Android task composer omits the done instruction',
      (tester) async {
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

  testWidgets('tasks link to notes and open a scrollable note popup',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.projects.v1':
          '[{"id":"project-1","name":"Linked work","createdAt":"2026-11-13T10:00:00.000Z","importance":"normal","coverImagePath":null,"tasks":[{"id":"task-1","text":"Read the linked details and keep wrapping this task text","isDone":false}]}]',
      'checklist.selectedProject.v1': 'project-1',
      'checklist.notes.v1':
          '[{"id":"note-1","name":"Useful note","createdAt":"2026-11-13T11:00:00.000Z","content":"A long note body that is available inside the task popup.","categoryId":null}]',
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

    await tester.tap(find.byKey(const ValueKey('task-settings')));
    await tester.pumpAndSettle();
    expect(find.text('+ note'), findsOneWidget);
    await tester.tap(find.text('+ note'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('task-note-picker-list')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('task-note-choice-note-1')));
    await tester.pumpAndSettle();

    final noteIcon = tester.widget<Icon>(
      find.byKey(const ValueKey('task-note-icon-task-1')),
    );
    expect(noteIcon.color, const Color(0xFF5A9BFF));
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('checklist.projects.v1'),
      contains('"linkedNoteId":"note-1"'),
    );

    await tester.tap(find.byKey(const ValueKey('task-note-opener-task-1')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('task-linked-note-dialog')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('task-linked-note-scroll')), findsOneWidget);
    expect(find.text('Useful note'), findsOneWidget);
    expect(find.textContaining('A long note body'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wordmark switches layouts and appearance only uses the switch',
      (tester) async {
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

    await tester.tap(find.text('dark'));
    await tester.pumpAndSettle();
    expect(find.text('dark'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('light'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('seven hidden taps toggle the persisted heart animation',
      (tester) async {
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

  testWidgets('sort button offers A-Z, date, and priority choices',
      (tester) async {
    SharedPreferences.setMockInitialValues({'checklist.welcome.v1': true});
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );

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

  testWidgets('new checklist priorities share one coloured row',
      (tester) async {
    SharedPreferences.setMockInitialValues({'checklist.welcome.v1': true});
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('new checklist'));
    await tester.pumpAndSettle();

    final low = find.widgetWithText(ChoiceChip, 'low');
    final medium = find.widgetWithText(ChoiceChip, 'medium');
    final high = find.widgetWithText(ChoiceChip, 'high');
    expect(find.text('name it'), findsOneWidget);
    expect(find.text('priority'), findsOneWidget);
    expect(tester.getCenter(low).dy, tester.getCenter(medium).dy);
    expect(tester.getCenter(medium).dy, tester.getCenter(high).dy);
    final priorityGap =
        tester.getTopLeft(medium).dx - tester.getTopRight(low).dx;
    final actionGap =
        tester.getTopLeft(find.widgetWithText(FilledButton, 'create')).dx -
            tester.getTopRight(find.widgetWithText(TextButton, 'cancel')).dx;
    expect(priorityGap, actionGap);

    final lowChip = tester.widget<ChoiceChip>(low);
    final mediumChip = tester.widget<ChoiceChip>(medium);
    expect(lowChip.selected, isFalse);
    expect(lowChip.backgroundColor, const Color(0xFF55505B));
    expect(mediumChip.selected, isTrue);
    expect(mediumChip.selectedColor, const Color(0xFF922FD0));

    await tester.tap(high);
    await tester.pumpAndSettle();
    expect(
        tester.widget<ChoiceChip>(high).selectedColor, const Color(0xFFF3ED23));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile drawer stays open across modes and opens by edge swipe',
      (tester) async {
    SharedPreferences.setMockInitialValues({'checklist.welcome.v1': true});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );

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
    final newChecklistButton =
        find.widgetWithText(FilledButton, 'new checklist');
    expect(wordmark, findsOneWidget);
    expect(brandCheck, findsOneWidget);
    expect(tester.getTopLeft(brandText).dy, greaterThanOrEqualTo(55));
    expect(
      tester.getTopLeft(newChecklistButton).dy -
          tester.getBottomRight(brandText).dy,
      inInclusiveRange(6, 12),
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
      find.widgetWithText(
        CheckedPopupMenuItem<NoteSort>,
        'category · a–z',
      ),
    );
    await tester.pumpAndSettle();

    var modeTheme = Theme.of(tester.element(find.byType(Scaffold).first));
    expect(modeTheme.colorScheme.primary, const Color(0xFF5A9BFF));
    final darkSwitch = tester.widget<Switch>(find.byType(Switch));
    expect(
      darkSwitch.thumbColor?.resolve({WidgetState.selected}),
      const Color(0xFF5A9BFF),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'new note'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('note-details-dialog')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('note-category-selector')), findsOneWidget);
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
      ((filterFrame.decoration! as BoxDecoration).border! as Border).top.color,
      const Color(0xFFF8F7FF),
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    modeTheme = Theme.of(tester.element(find.byType(Scaffold).first));
    expect(modeTheme.brightness, Brightness.light);
    expect(modeTheme.colorScheme.primary, const Color(0xFF1553A3));
    expect(find.text('light'), findsOneWidget);
    final lightSwitch = tester.widget<Switch>(find.byType(Switch));
    expect(
      lightSwitch.thumbColor?.resolve({}),
      const Color(0xFF9AA0AA),
    );
    final notesLightSidebar = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('sidebar-surface')),
    );
    expect(
      (notesLightSidebar.decoration! as BoxDecoration).color,
      const Color(0xFF315B88),
    );

    await tester.tap(find.bySemanticsLabel('CHECKLIST'));
    await tester.pumpAndSettle();
    final checklistLightSidebar = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('sidebar-surface')),
    );
    expect(
      (checklistLightSidebar.decoration! as BoxDecoration).color,
      const Color(0xFF6B3A7D),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('category settings edit and animate category removal',
      (tester) async {
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

    final sidebarSettings = find.byKey(
      const ValueKey('sidebar-note-settings'),
    );
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
    final categoryActionRow = find.byKey(
      const ValueKey('category-action-row'),
    );
    final newCategoryButton = find.descendant(
      of: categoryActionRow,
      matching: find.widgetWithText(FilledButton, 'new'),
    );
    final removeCategoryButton = find.descendant(
      of: categoryActionRow,
      matching: find.widgetWithText(FilledButton, 'remove'),
    );
    final cancelButton = find.byKey(
      const ValueKey('category-cancel-button'),
    );
    expect(
      tester.getCenter(newCategoryButton).dy,
      tester.getCenter(removeCategoryButton).dy,
    );
    expect(
      tester.getCenter(removeCategoryButton).dy,
      tester.getCenter(cancelButton).dy,
    );
    final cancel = tester.widget<TextButton>(cancelButton);
    expect(
      cancel.style?.backgroundColor?.resolve({}),
      Colors.transparent,
    );
    expect(
      cancel.style?.foregroundColor?.resolve({}),
      const Color(0xFF9AA0AA),
    );
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
