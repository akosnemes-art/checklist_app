import 'package:checklist_app/services/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('theme selection persists independently of legacy dark mode', () async {
    SharedPreferences.setMockInitialValues({'checklist.darkMode.v1': false});
    final store = LocalStore();

    expect(await store.loadTheme(), isNull);
    expect(await store.loadDarkMode(), isFalse);

    await store.saveTheme('pastel');
    expect(await store.loadTheme(), 'pastel');
  });

  test('language selection persists', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore();

    expect(await store.loadLanguage(), isNull);
    await store.saveLanguage('hungarian');
    expect(await store.loadLanguage(), 'hungarian');
  });

  test(
    'backup restores checklists notes and categories on a fresh install',
    () async {
      SharedPreferences.setMockInitialValues({
        'checklist.projects.v1':
            '[{"id":"project","name":"Travel","createdAt":"2026-11-20T10:00:00.000Z","importance":"high","coverImagePath":"/private/old-cover.png","reminderAt":null,"tasks":[{"id":"task","text":"Passport","isDone":true,"linkedNoteId":"note"}]}]',
        'checklist.notes.v1':
            '[{"id":"note","name":"Ideas","createdAt":"2026-11-20T11:00:00.000Z","content":"Budapest","categoryId":"category"}]',
        'checklist.noteCategories.v1':
            '[{"id":"category","name":"Places","colorValue":4280391411}]',
        'checklist.selectedProject.v1': 'project',
        'checklist.selectedNote.v1': 'note',
      });
      final source = LocalStore();
      final bytes = await source.createBackupBytes();
      final backup = source.decodeBackup(bytes);

      expect(backup.projects.single.coverImagePath, isNull);
      expect(backup.projects.single.tasks.single.linkedNoteId, 'note');

      SharedPreferences.setMockInitialValues({});
      final destination = LocalStore();
      await destination.restoreBackup(backup);

      expect((await destination.loadProjects()).single.name, 'Travel');
      expect((await destination.loadNotes()).single.content, 'Budapest');
      expect((await destination.loadNoteCategories()).single.name, 'Places');
      expect(await destination.loadSelectedProjectId(), 'project');
      expect(await destination.loadSelectedNoteId(), 'note');
    },
  );

  test(
    'heart animation defaults off and persists its hidden setting',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = LocalStore();

      expect(await store.loadHeartAnimationEnabled(), isFalse);

      await store.saveHeartAnimationEnabled(true);
      expect(await store.loadHeartAnimationEnabled(), isTrue);

      await store.saveHeartAnimationEnabled(false);
      expect(await store.loadHeartAnimationEnabled(), isFalse);
    },
  );
}
