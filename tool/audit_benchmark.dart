import 'dart:convert';
import 'dart:io';

import 'package:checklist_app/services/note_links.dart';
import 'package:checklist_app/models/checklist_project.dart';

int medianMicros(void Function() work) {
  final samples = <int>[];
  for (var i = 0; i < 9; i++) {
    final timer = Stopwatch()..start();
    work();
    if (i >= 2) samples.add(timer.elapsedMicroseconds);
  }
  return (samples..sort())[3];
}

void main() {
  for (final n in [10, 100, 1000, 10000]) {
    final link = "https://example.org/page${')' * n}";
    final list = ChecklistProject(
        id: 'p',
        name: 'Test',
        createdAt: DateTime.utc(2026),
        tasks: List.generate(
            n,
            (i) => ChecklistTask(
                id: 't$i', text: 'Buy item $i', isDone: i.isEven)));
    final parse = medianMicros(() {
      if (findNoteLinks(link).single.uri.path != '/page') {
        throw StateError('link');
      }
    });
    final roundTrip = medianMicros(() {
      final saved = ChecklistProject.fromJson(
          jsonDecode(jsonEncode(list.toJson())) as Map<String, dynamic>);
      if (saved.completedTaskCount != (n + 1) ~/ 2) throw StateError('tasks');
    });
    stdout.writeln('$n $parse $roundTrip');
  }
}
