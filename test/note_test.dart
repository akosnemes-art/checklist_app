import 'package:checklist_app/models/note.dart';
import 'package:checklist_app/services/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
