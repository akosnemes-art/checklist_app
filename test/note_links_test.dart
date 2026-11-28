import 'package:checklist_app/app_version.dart';
import 'package:checklist_app/main.dart';
import 'package:checklist_app/services/note_links.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('recognises website and app links with or without formatting', () {
    const text = 'Visit (https://example.org/Places_(UK)), www.example.hu, '
        'example.net/a__b?q=1. Send mailto:name@example.org or open '
        '\uE000myapp://item/\uE00242\uE003\uE001. Call tel:+4412345.';
    final links = findNoteLinks(text);
    expect(links.map((link) => link.uri.toString()), [
      'https://example.org/Places_(UK)',
      'https://www.example.hu',
      'https://example.net/a__b?q=1',
      'mailto:name@example.org',
      'myapp://item/42',
      'tel:+4412345',
    ]);
    expect(
      text.substring(links[4].start, links[4].end),
      'myapp://item/\uE00242',
    );
    expect(
      findNoteLinks('__https://example.org/path__').single.uri.toString(),
      'https://example.org/path',
    );
  });

  test('trims long mixed punctuation while preserving balanced URL brackets',
      () {
    const url = 'https://example.org/A_(UK)';
    final text = '$url${')!]' * 10000} next';
    final link = findNoteLinks(text).single;
    expect(link.uri.toString(), url);
    expect(link.end, url.length);
  });

  test('skips email fragments and local or executable URI schemes', () {
    expect(
      findNoteLinks('name@example.org file://example.org/path '
          'content://example.org/path intent://example.org#Intent;end '
          'javascript://example.org'),
      isEmpty,
    );
  });

  test('repairs common OCR URL spacing and leaves surrounding text intact', () {
    const recognised = 'Magyar szöveg ő és ű\n'
        'https ： ／ ／ example . hu /Docs?x=1\n'
        'www . example.hu\nexample .org\nhttps://example.\ncom/help\n'
        'See https://example.org. Next sentence.';
    expect(
      restorePhotoWebLinks(recognised),
      'Magyar szöveg ő és ű\n'
      'https://example.hu/Docs?x=1\nwww.example.hu\nexample.org\n'
      'https://example.com/help\n'
      'See https://example.org. Next sentence.',
    );
  });

  testWidgets('stored app links open outside edit mode and remain editable', (
    tester,
  ) async {
    const body = 'Find directions at geo:47.4979,19.0402';
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.lastSeenVersion.v1': checklistRelease,
      'checklist.notes.v1':
          '[{"id":"note-1","name":"Directions","createdAt":"2026-11-12T10:00:00.000Z","content":"$body","categoryId":null}]',
      'checklist.selectedNote.v1': 'note-1',
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
      return false;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('NOTES'));
    await tester.pumpAndSettle();
    final finder = find.byType(EditableText);
    final editable = tester.state<EditableTextState>(finder);
    final render = editable.renderEditable;
    final span = editable.widget.controller.buildTextSpan(
      context: tester.element(finder),
      style: editable.widget.style,
      withComposing: false,
    );
    final linkSpan = span.children!.whereType<TextSpan>().last;
    expect(linkSpan.text, 'geo:47.4979,19.0402');
    expect(linkSpan.style!.decoration, TextDecoration.underline);
    expect(linkSpan.style!.color, const Color(0xFFF3ED23));

    final linkStart = body.indexOf('geo:');
    final linkBox = render
        .getBoxesForSelection(
          TextSelection(baseOffset: linkStart, extentOffset: body.length),
        )
        .first;
    final linkPoint = render.localToGlobal(linkBox.toRect().center);
    final blankPoint = render.localToGlobal(
      linkBox.toRect().centerRight + const Offset(30, 0),
    );

    await tester.tapAt(blankPoint, kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(editable.widget.focusNode.hasFocus, isTrue);
    expect(opened, isEmpty);

    await tester.tapAt(linkPoint, kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(editable.widget.focusNode.hasFocus, isTrue);
    expect(editable.widget.controller.selection.extentOffset,
        greaterThan(linkStart));
    expect(opened, isEmpty);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('notes')),
        matching: find.text('Directions'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(linkPoint, kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(opened.single.arguments['url'], 'geo:47.4979,19.0402');
    expect(opened.single.arguments['useWebView'], isFalse);
    expect(find.text('Could not open that link.'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
