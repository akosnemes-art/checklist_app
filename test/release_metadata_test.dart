import 'dart:io';

import 'package:checklist_app/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('welcome release metadata stays aligned with pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final release = RegExp(
      r'^version:\s*([^+\s]+)\+(\d+)\s*$',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(release, isNotNull);
    expect(checklistVersion, release!.group(1));
    expect(checklistBuildNumber, release.group(2));
  });

  test('Android is the only packaged platform', () {
    final metadata = File('.metadata').readAsStringSync();
    expect(metadata, contains('platform: android'));
    expect(metadata, isNot(contains('platform: linux')));
    expect(Directory('linux').existsSync(), isFalse);
    final app = File('lib/main.dart').readAsStringSync();
    expect(app, isNot(contains('checklist/window')));
    final previews =
        File('lib/services/website_previews.dart').readAsStringSync();
    expect(previews, contains('checklist/website_previews'));
    expect(previews, isNot(contains('Process.start')));
  });

  test('Android launcher icon and edge-to-edge system UI stay configured', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final lightStyles =
        File('android/app/src/main/res/values/styles.xml').readAsStringSync();
    final darkStyles = File('android/app/src/main/res/values-night/styles.xml')
        .readAsStringSync();
    final iconBytes = File('Checklist_app_icon_safe.png').readAsBytesSync();

    expect(iconBytes.take(8), <int>[137, 80, 78, 71, 13, 10, 26, 10]);
    expect(
      gradle,
      contains('rootProject.file("../Checklist_app_icon_safe.png")'),
    );
    expect(manifest, contains('android:icon="@mipmap/checklist_logo"'));
    expect(mainSource, contains('SystemUiMode.edgeToEdge'));
    expect(
      mainSource,
      contains('systemNavigationBarColor: Colors.transparent'),
    );
    expect(mainSource, contains('systemNavigationBarContrastEnforced: false'));
    expect(mainSource, contains("ValueKey('edge-to-edge-system-ui')"));
    for (final styles in [lightStyles, darkStyles]) {
      expect(
        styles,
        contains(
          '<item name="android:navigationBarColor">@android:color/transparent</item>',
        ),
      );
    }
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
    expect(File('lib/note_formatting.dart').readAsStringSync(),
        contains('class _FormattedNoteController'));
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
    expect(mainSource, contains("ValueKey('mobile-sidebar-safe-area')"));
    expect(mainSource, contains("ValueKey('main-content-safe-area')"));
    expect(mainSource, contains("ValueKey('note-format-tap-region')"));
    expect(
      mainSource,
      contains('onTapOutside: (_) => _noteFocusNode.unfocus()'),
    );
    expect(mainSource, contains('Color(0xFFD9EAF7)'));
    expect(mainSource, contains('usePaleBackground: true'));
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
