import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('welcome release metadata stays aligned with pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final mainSource = File('lib/main.dart').readAsStringSync();

    final release = RegExp(
      r'^version:\s*([^+\s]+)\+(\d+)\s*$',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(release, isNotNull);
    expect(mainSource, contains("const _appVersion = '${release!.group(1)}';"));
    expect(
      mainSource,
      contains("const _appBuildNumber = '${release.group(2)}';"),
    );
  });

  test('popup windows retain the five millisecond fade contract', () {
    final mainSource = File('lib/main.dart').readAsStringSync();

    expect(
      mainSource,
      contains('const _popupFadeDuration = Duration(milliseconds: 5);'),
    );
    expect(mainSource, contains('transitionDuration: _popupFadeDuration,'));
    expect(mainSource, contains('FadeTransition(opacity: animation'));
  });

  test('task text uses the 140 millisecond hold reorder contract', () {
    final mainSource = File('lib/main.dart').readAsStringSync();

    expect(
      mainSource,
      contains('const _taskReorderHoldDuration = Duration(milliseconds: 140);'),
    );
    expect(mainSource, contains('DelayedMultiDragGestureRecognizer('));
    expect(mainSource, isNot(contains('Icons.drag_indicator_rounded')));
    expect(
      mainSource,
      contains("key: ValueKey('task-reorder-area-\${task.id}')"),
    );
    expect(mainSource, contains('index: reorderIndex'));
    expect(mainSource, contains("key: ValueKey('task-checkbox-\${task.id}')"));
    expect(mainSource, contains('dimension: 32'));
    expect(
      mainSource,
      contains('materialTapTargetSize: MaterialTapTargetSize.padded'),
    );
  });

  test('linked notes use the sticky-note cue and Pastel priorities', () {
    final mainSource = File('lib/main.dart').readAsStringSync();

    expect(mainSource, contains('Icons.sticky_note_2_rounded'));
    expect(mainSource, contains('const _linkedNoteCueDuration'));
    expect(mainSource, contains('Color(0xFFE31F26)'));
    expect(mainSource, contains('Color(0xFF00978D)'));
    expect(mainSource, contains('Color(0xFFB5B1D8)'));
  });

  test('0.4.8 layout, Pencil priority, and note-format contracts remain', () {
    final mainSource = File('lib/main.dart').readAsStringSync();

    expect(mainSource, contains("ValueKey('selected-mode-check-alignment')"));
    expect(
      mainSource,
      contains("ValueKey('task-note-below-checkbox-\${task.id}')"),
    );
    expect(mainSource, contains('Color(0xFF999999)'));
    expect(mainSource, contains('Color(0xFF64696A)'));
    expect(mainSource, contains('Color(0xFF0E2F44)'));
    expect(mainSource, contains('class _FormattedNoteController'));
    expect(
      mainSource,
      contains('contextMenuBuilder: _buildNoteSelectionToolbar'),
    );
    expect(mainSource, contains('ContextMenuButtonKind.cut'));
    expect(mainSource, contains('ContextMenuButtonKind.copy'));
    expect(mainSource, contains('ContextMenuButtonKind.paste'));
    expect(
      mainSource,
      contains("ValueKey('note-selection-format-\${format.name}')"),
    );
    expect(
      mainSource,
      contains('shape: const RoundedRectangleBorder(side: BorderSide.none)'),
    );
  });

  test('progress and sidebar entries retain their animation contracts', () {
    final mainSource = File('lib/main.dart').readAsStringSync();

    expect(mainSource, contains('class _AnimatedChecklistProgress'));
    expect(mainSource, contains('TweenAnimationBuilder<double>('));
    expect(mainSource, contains('class _SidebarFadeItem'));
    expect(mainSource, contains('AnimatedOpacity('));
    expect(
      mainSource,
      contains(
        'const _sidebarEntryFadeDuration = Duration(milliseconds: 240);',
      ),
    );
  });

  test('settings line stays at a constant full width', () {
    final mainSource = File('lib/main.dart').readAsStringSync();

    expect(
      mainSource,
      contains("key: const ValueKey('settings-expanding-line')"),
    );
    expect(mainSource, contains('width: double.infinity'));
    expect(mainSource, isNot(contains('width: _settingsOpen ? 250 : 54')));
  });
}
