import 'package:checklist_app/models/checklist_project.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChecklistProject', () {
    test('round-trips all project and task fields', () {
      final createdAt = DateTime.utc(2026, 1, 2, 3, 4, 5);
      final reminderAt = DateTime.utc(2026, 1, 8, 9, 30);
      final project = ChecklistProject(
        id: 'project-1',
        name: 'Launch plan',
        createdAt: createdAt,
        importance: ProjectImportance.high,
        coverImagePath: '/tmp/cover.png',
        reminderAt: reminderAt,
        tasks: [
          ChecklistTask(
            id: 'task-1',
            text: 'Write the release notes',
            isDone: true,
            linkedNoteId: 'note-1',
          ),
        ],
      );

      final restored = ChecklistProject.fromJson(
        Map<String, dynamic>.from(project.toJson()),
      );

      expect(restored.id, project.id);
      expect(restored.name, project.name);
      expect(restored.createdAt, createdAt);
      expect(restored.importance, ProjectImportance.high);
      expect(restored.coverImagePath, '/tmp/cover.png');
      expect(restored.reminderAt, reminderAt);
      expect(restored.completedTaskCount, 1);
      expect(restored.tasks.single.text, 'Write the release notes');
      expect(restored.tasks.single.isDone, isTrue);
      expect(restored.tasks.single.linkedNoteId, 'note-1');
    });

    test('uses normal importance for older saved data', () {
      final restored = ChecklistProject.fromJson({
        'id': 'project-2',
        'name': 'Older project',
        'createdAt': '2026-01-02T03:04:05.000Z',
        'tasks': <Object?>[],
      });

      expect(restored.importance, ProjectImportance.normal);
      expect(restored.reminderAt, isNull);
      expect(restored.tasks, isEmpty);
    });

    test('older tasks remain compatible without a linked note', () {
      final task = ChecklistTask.fromJson({
        'id': 'old-task',
        'text': 'Still works',
        'isDone': false,
      });

      expect(task.linkedNoteId, isNull);
    });
  });
}
