enum ProjectImportance { low, normal, high }

class ChecklistTask {
  ChecklistTask({
    required this.id,
    required this.text,
    this.isDone = false,
    this.linkedNoteId,
  });

  final String id;
  String text;
  bool isDone;
  String? linkedNoteId;

  Map<String, Object?> toJson() => {
        'id': id,
        'text': text,
        'isDone': isDone,
        'linkedNoteId': linkedNoteId,
      };

  factory ChecklistTask.fromJson(Map<String, dynamic> json) => ChecklistTask(
        id: json['id'] as String,
        text: json['text'] as String,
        isDone: json['isDone'] as bool? ?? false,
        linkedNoteId: json['linkedNoteId'] as String?,
      );
}

class ChecklistProject {
  ChecklistProject({
    required this.id,
    required this.name,
    required this.createdAt,
    this.importance = ProjectImportance.normal,
    this.coverImagePath,
    this.reminderAt,
    List<ChecklistTask>? tasks,
  }) : tasks = tasks ?? [];

  final String id;
  String name;
  final DateTime createdAt;
  ProjectImportance importance;
  String? coverImagePath;
  DateTime? reminderAt;
  final List<ChecklistTask> tasks;

  int get completedTaskCount => tasks.where((task) => task.isDone).length;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'importance': importance.name,
        'coverImagePath': coverImagePath,
        'reminderAt': reminderAt?.toIso8601String(),
        'tasks': tasks.map((task) => task.toJson()).toList(),
      };

  factory ChecklistProject.fromJson(Map<String, dynamic> json) {
    final importanceName = json['importance'] as String?;
    final importance = ProjectImportance.values.firstWhere(
      (value) => value.name == importanceName,
      orElse: () => ProjectImportance.normal,
    );

    return ChecklistProject(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      importance: importance,
      coverImagePath: json['coverImagePath'] as String?,
      reminderAt: switch (json['reminderAt']) {
        final String value when value.isNotEmpty => DateTime.tryParse(value),
        _ => null,
      },
      tasks: (json['tasks'] as List<dynamic>? ?? [])
          .map((task) => ChecklistTask.fromJson(task as Map<String, dynamic>))
          .toList(),
    );
  }
}
