import 'package:checklist_app/app_version.dart';
import 'package:checklist_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _notes = '''[
  {"id":"first","name":"First note","createdAt":"2026-11-20T10:00:00.000Z","content":"Earlier note","categoryId":null},
  {"id":"second","name":"new note","createdAt":"2026-11-21T10:00:00.000Z","content":"New line of text\\nhttps://example.org","categoryId":"plans"}
]''';
const _categories = '[{"id":"plans","name":"Plans","colorValue":4294442357}]';
const _projects = '''[
  {"id":"first-project","name":"First list","createdAt":"2026-11-20T10:00:00.000Z","tasks":[]},
  {"id":"second-project","name":"Second list","createdAt":"2026-11-21T10:00:00.000Z","tasks":[
    {"id":"first-task","text":"First task","isDone":false},
    {"id":"second-task","text":"Second task","isDone":false},
    {"id":"third-task","text":"Third task","isDone":false}
  ]}
]''';

Future<void> _pumpApp(WidgetTester tester,
    [Map<String, Object> saved = const {}]) async {
  SharedPreferences.setMockInitialValues({
    'checklist.welcome.v1': true,
    'checklist.lastSeenVersion.v1': checklistRelease,
    'checklist.notes.v1': _notes,
    'checklist.noteCategories.v1': _categories,
    'checklist.selectedNote.v1': 'first',
    'checklist.projects.v1': _projects,
    'checklist.selectedProject.v1': 'first-project',
    ...saved,
  });
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
      const RepaintBoundary(key: ValueKey('app-paint'), child: ChecklistApp()));
  await tester.pumpAndSettle();
}

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _selectNotes(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('NOTES'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('typed stars stay visible and pending edits save on pause',
      (tester) async {
    await _pumpApp(tester);
    await _selectNotes(tester);
    final field = _key('note-content-field');
    const literal = '* milk\n2 * 3 **strong** *italics* 😀';
    await tester.enterText(field, literal);
    final controller = tester.widget<TextField>(field).controller!;
    final span = controller.buildTextSpan(
        context: tester.element(field), withComposing: false);
    final body = span.children!.whereType<TextSpan>().single;
    expect(body.text, literal);
    expect(body.style!.fontStyle, isNot(FontStyle.italic));
    expect(body.style!.fontWeight, isNot(FontWeight.w700));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final saved = await SharedPreferences.getInstance();
    expect(saved.getString('checklist.notes.v1'),
        contains('2 * 3 **strong** *italics*'));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    controller.selection =
        TextSelection(baseOffset: 0, extentOffset: literal.length);
    await tester.tap(_key('note-format-bold'));
    await tester.pumpAndSettle();
    final formatted = controller.buildTextSpan(
        context: tester.element(field), withComposing: false);
    expect(
        formatted.children!
            .whereType<TextSpan>()
            .singleWhere((s) => s.text == literal)
            .style!
            .fontWeight,
        FontWeight.w700);
  });

  testWidgets(
      'selection fades note content downwards and staggers checklist tasks',
      (tester) async {
    await _pumpApp(tester, {'checklist.theme.v1': 'pastel'});
    await tester.tap(_key('sidebar-project-second-project'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 190));

    double taskOpacity(String taskId) => tester
        .widget<FadeTransition>(
          find
              .descendant(
                  of: _key('reorder-task-$taskId'),
                  matching: find.byType(FadeTransition))
              .first,
        )
        .opacity
        .value;
    expect(taskOpacity('first-task'), greaterThan(taskOpacity('second-task')));
    expect(taskOpacity('third-task'), 0);
    await tester.pumpAndSettle();
    expect(taskOpacity('third-task'), 1);

    await _selectNotes(tester);
    await tester.tap(_key('sidebar-note-second'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final reveal = tester.renderObject(_key('note-body-reveal'));
    expect(reveal.debugLayer, isA<ShaderMaskLayer>());
    expect(_key('pastel-workspace-backdrop'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(reveal.debugLayer, isNull);
  });

  testWidgets(
      'dropdown edges follow the theme and Pastel sidebar entries stay flat',
      (tester) async {
    await _pumpApp(tester);
    Future<void> expectMenuFrame(BorderSide side, {double radius = 0}) async {
      await tester.tap(find.byTooltip('sort checklists'));
      await tester.pumpAndSettle();
      final menu =
          tester.widgetList<Material>(find.byType(Material)).where((material) {
        final shape = material.shape;
        return material.type == MaterialType.card &&
            shape is RoundedRectangleBorder &&
            shape.borderRadius == BorderRadius.circular(radius) &&
            shape.side == side;
      });
      expect(menu, hasLength(1));
      Navigator.of(tester.element(find.text('date · newest'))).pop();
      await tester.pumpAndSettle();
    }

    await expectMenuFrame(const BorderSide(color: Color(0xFF5A9BFF), width: 2));
    await tester.tap(_key('settings-toggle'));
    await tester.pumpAndSettle();
    await tester.tap(_key('settings-themes'));
    await tester.pumpAndSettle();
    await tester.tap(_key('theme-pencil'));
    await tester.pumpAndSettle();
    await expectMenuFrame(const BorderSide(color: Color(0xFF858C94), width: 2));
    await tester.tap(_key('theme-pastel'));
    await tester.pumpAndSettle();
    await expectMenuFrame(BorderSide.none, radius: 18);
    final divider = _key('pastel-sidebar-divider');
    expect(divider, findsOneWidget);
    expect(tester.getSize(divider).height, 3);
    final priority = tester.widget<Container>(find.descendant(
      of: _key('pastel-sidebar-priority').first,
      matching: find.byType(Container),
    ));
    final priorityFace = priority.decoration! as BoxDecoration;
    expect(priorityFace.shape, BoxShape.circle);
    expect(priorityFace.color, const Color(0xFF00978D));

    void expectFlatRow(String name) {
      final row = _key(name);
      final face = tester.widget<Material>(
          find.descendant(of: row, matching: find.byType(Material)).first);
      expect(face.color, Colors.transparent);
      final relief =
          find.descendant(of: row, matching: _key('pastel-press-depth'));
      expect(relief, findsOneWidget);
      final menu = tester.widget<TweenAnimationBuilder<double>>(relief);
      expect(menu.tween.end, .78);
    }

    expectFlatRow('sidebar-project-first-project');
    await _selectNotes(tester);
    await tester.tap(_key('sidebar-note-second'));
    await tester.pumpAndSettle();
    expectFlatRow('sidebar-note-second');
    expect(divider, findsOneWidget);
  });

  testWidgets(
      'formatting combinations toggle independently on a selection or at the cursor',
      (tester) async {
    await _pumpApp(tester, {
      'checklist.notes.v1':
          '[{"id":"first","name":"Format","content":"**a😀** *bc*","createdAt":"2026-11-21T10:00:00.000Z","categoryId":"plans"}]',
    });
    await _selectNotes(tester);
    final field = tester.widget<TextField>(_key('note-content-field'));
    final controller = field.controller!;
    final toolbar = tester.getRect(_key('note-format-toolbar'));
    final category =
        find.descendant(of: _key('note-editor'), matching: find.text('Plans'));
    expect(tester.getCenter(category).dy, toolbar.center.dy);
    expect(toolbar.right, tester.getTopRight(_key('note-header-settings')).dx);
    expect(tester.getTopLeft(_key('note-content-field')).dy,
        greaterThan(toolbar.bottom));

    final formats = ['bold', 'italic', 'underline'];
    await tester.tap(_key('note-content-field'));
    controller.selection =
        TextSelection(baseOffset: controller.text.length, extentOffset: 0);
    await tester.pump();
    Future<void> toggle(int index) async {
      await tester.tap(_key('note-format-${formats[index]}'));
      await tester.pump();
    }

    void expectActive(int bits) {
      for (var index = 0; index < formats.length; index++) {
        final button =
            tester.widget<IconButton>(_key('note-format-${formats[index]}'));
        expect(
            button.style!.foregroundColor!.resolve({}),
            bits & (1 << index) != 0
                ? const Color(0xFFF3ED23)
                : const Color(0xFF5A9BFF));
      }
    }

    // Toggle each style through all eight combinations without reselecting.
    var active = 0;
    for (final index in [0, 1, 0, 2, 0, 1, 0, 2]) {
      await toggle(index);
      active ^= 1 << index;
      expectActive(active);
      expect(controller.selection.baseOffset,
          greaterThan(controller.selection.extentOffset));
      expect(
          controller.selection
              .textInside(controller.text)
              .replaceAll(RegExp(r'[\uE000-\uE005]'), ''),
          'a😀 bc');
    }
    expect(controller.text, 'a😀 bc');

    controller.selection = const TextSelection.collapsed(offset: 0);
    await tester.pump();
    for (final index in [2, 0, 1, 0]) {
      await toggle(index);
      active ^= 1 << index;
      expectActive(active);
    }
    final offset = controller.selection.start;
    controller.value = TextEditingValue(
        text: controller.text.replaceRange(offset, offset, 'X'),
        selection: TextSelection.collapsed(offset: offset + 1));
    await tester.pump();
    final spans = controller.buildTextSpan(
        context: tester.element(_key('note-content-field')),
        withComposing: false);
    final typed = spans.children!
        .whereType<TextSpan>()
        .singleWhere((part) => part.text == 'X');
    expect(typed.style!.fontStyle, FontStyle.italic);
    expect(typed.style!.decoration, TextDecoration.underline);
    expect(typed.style!.fontWeight, isNot(FontWeight.w700));
    expect(field.focusNode!.hasFocus, isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets(
      'Pastel link flashes before opening while ordinary body text stays black',
      (tester) async {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      calls.add(call);
      return true;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await _pumpApp(tester, {
      'checklist.theme.v1': 'pastel',
      'checklist.selectedNote.v1': 'second'
    });
    await _selectNotes(tester);
    final finder = find.byType(EditableText);
    final editable = tester.state<EditableTextState>(finder);
    final editor = editable.renderEditable;
    List<TextSpan> spans() => editable.widget.controller
        .buildTextSpan(
          context: tester.element(finder),
          style: editable.widget.style,
          withComposing: false,
        )
        .children!
        .whereType<TextSpan>()
        .toList();
    const url = 'https://example.org';
    expect(spans().first.style!.color, const Color(0xFF324256));
    expect(spans().last.style!.color, const Color(0xFF1553A3));
    final text = editable.widget.controller.text;
    final box = editor
        .getBoxesForSelection(TextSelection(
            baseOffset: text.indexOf(url), extentOffset: text.length))
        .single;
    await tester.tapAt(editor.localToGlobal(box.toRect().center));
    await tester.pump();
    expect(spans().last.style!.color, const Color(0xFF5A9BFF));
    expect(spans().last.style!.shadows, isNull);
    expect(calls, isEmpty);
    await tester.pump(const Duration(milliseconds: 100));
    expect(calls.single.arguments['url'], url);
    expect(spans().last.style!.color, const Color(0xFF1553A3));
    await tester.pumpAndSettle();
  });

  testWidgets(
      'Settings lights pressed text, points the chevron correctly and persists both new languages',
      (tester) async {
    await _pumpApp(tester);
    final arrow = find.descendant(
        of: _key('settings-chevron'), matching: find.byType(AnimatedRotation));
    expect(tester.widget<AnimatedRotation>(arrow).turns, 0.5);
    await tester.tap(_key('settings-toggle'));
    await tester.pump();
    expect(
        tester.widget<Text>(find.text('settings')).style!.shadows, isNotEmpty);
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedRotation>(arrow).turns, 0);
    final language = _key('settings-language');
    expect(
        find.descendant(
            of: language, matching: find.byIcon(Icons.translate_rounded)),
        findsOneWidget);
    await tester.tap(language);
    await tester.pump();
    expect(
        tester.widget<Text>(find.text('language')).style!.shadows, isNotEmpty);
    await tester.pumpAndSettle();
    for (final name in ['english', 'hungarian', 'french', 'czech']) {
      expect(
          find.descendant(
              of: _key('language-$name'), matching: find.byType(Icon)),
          findsNothing);
    }
    final preferences = await SharedPreferences.getInstance();
    await tester.tap(_key('language-french'));
    await tester.pumpAndSettle();
    expect(find.text('paramètres'), findsOneWidget);
    expect(find.text('VOS LISTES'), findsOneWidget);
    expect(find.textContaining('21 nov. 2026'), findsOneWidget);
    expect(preferences.getString('checklist.language.v1'), 'french');

    Future<void> restartApp() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(const ChecklistApp());
      await tester.pumpAndSettle();
    }

    await restartApp();
    expect(find.text('VOS LISTES'), findsOneWidget);
    await tester.tap(_key('settings-toggle'));
    await tester.pumpAndSettle();
    await tester.tap(_key('settings-language'));
    await tester.pumpAndSettle();
    await tester.tap(_key('language-czech'));
    await tester.pumpAndSettle();
    expect(find.text('nastavení'), findsOneWidget);
    expect(find.text('VAŠE SEZNAMY'), findsOneWidget);
    expect(find.textContaining('21. 11. 2026'), findsOneWidget);
    expect(preferences.getString('checklist.language.v1'), 'czech');
    await tester.tap(_key('settings-chevron'));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedRotation>(arrow).turns, 0.5);
    await _selectNotes(tester);
    expect(find.text('VAŠE POZNÁMKY'), findsOneWidget);
    expect(find.text('nová poznámka'), findsOneWidget);
    expect(find.text('new note'), findsOneWidget);
    await restartApp();
    expect(find.text('VAŠE SEZNAMY'), findsOneWidget);
  });
}
