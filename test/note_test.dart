import 'dart:io';

import 'package:flutter/services.dart';
import 'package:checklist_app/models/note.dart';
import 'package:checklist_app/services/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('cover removal only deletes regular files directly in the covers folder',
      () async {
    final root = await Directory.systemTemp.createTemp('checklist-cover-test');
    addTearDown(() => root.delete(recursive: true));
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async => root.path);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final covers = await Directory('${root.path}/covers').create();
    final own = await File('${covers.path}/photo.jpg').create();
    final other = await File('${root.path}/preferences').create();
    final link = await Link('${covers.path}/alias').create(other.path);
    final store = LocalStore();
    await store.deleteCover('${covers.path}/../preferences');
    await store.deleteCover(link.path);
    await store.deleteCover(own.path);
    expect(await other.exists(), isTrue);
    expect(await link.exists(), isTrue);
    expect(await own.exists(), isFalse);
  });

  test('notes and categories round-trip through their models', () {
    final category = NoteCategory(
      id: 'category-1',
      name: 'Ideas',
      colorValue: 0xFFE85D75,
    );
    final note = NoteEntry(
      id: 'note-1',
      name: 'Game loop',
      createdAt: DateTime.utc(2026, 11, 7),
      content: 'Explore, gather, return.',
      categoryId: category.id,
    );

    final restoredCategory = NoteCategory.fromJson(category.toJson());
    final restoredNote = NoteEntry.fromJson(note.toJson());

    expect(restoredCategory.name, 'Ideas');
    expect(restoredCategory.colorValue, 0xFFE85D75);
    expect(restoredNote.name, 'Game loop');
    expect(restoredNote.content, 'Explore, gather, return.');
    expect(restoredNote.categoryId, category.id);
    expect(restoredNote.createdAt, DateTime.utc(2026, 11, 7));
  });

  test('legacy star styles migrate once and new stars survive a backup',
      () async {
    SharedPreferences.setMockInitialValues({
      'checklist.projects.v1':
          '[{"id":"p","name":"List","createdAt":"2026-01-01"}]',
      'checklist.notes.v1':
          '[{"id":"n","name":"Note","createdAt":"2026-01-01","content":"**bold** *italic*"}]',
    });
    final store = LocalStore();
    final note = (await store.loadNotes()).single;
    expect(note.content, '\uE000bold\uE001 \uE002italic\uE003');
    note.content += ' * 2 ** 3 *';
    await store.saveNotes([note]);
    final backup = store.decodeBackup(await store.createBackupBytes());
    await store.restoreBackup(backup);
    expect((await store.loadNotes()).single.content, note.content);
  });

  test('local store persists notes, categories, and selected note', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore();
    final category = NoteCategory(
      id: 'category-1',
      name: 'Research',
      colorValue: 0xFF05E1E6,
    );
    final note = NoteEntry(
      id: 'note-1',
      name: 'References',
      createdAt: DateTime.utc(2026, 11, 7),
      content: 'Read later',
      categoryId: category.id,
    );

    await store.saveNoteCategories([category]);
    await store.saveNotes([note]);
    await store.saveSelectedNoteId(note.id);

    expect((await store.loadNoteCategories()).single.name, 'Research');
    expect((await store.loadNotes()).single.content, 'Read later');
    expect(await store.loadSelectedNoteId(), note.id);

    await store.saveSelectedNoteId(null);
    expect(await store.loadSelectedNoteId(), isNull);
  });
}
