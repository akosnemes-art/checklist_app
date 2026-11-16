class NoteCategory {
  NoteCategory({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  final String id;
  String name;
  final int colorValue;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
      };

  factory NoteCategory.fromJson(Map<String, dynamic> json) => NoteCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        colorValue: json['colorValue'] as int,
      );
}

class NoteEntry {
  NoteEntry({
    required this.id,
    required this.name,
    required this.createdAt,
    this.content = '',
    this.categoryId,
  });

  final String id;
  String name;
  final DateTime createdAt;
  String content;
  String? categoryId;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'content': content,
        'categoryId': categoryId,
      };

  factory NoteEntry.fromJson(Map<String, dynamic> json) => NoteEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        content: json['content'] as String? ?? '',
        categoryId: json['categoryId'] as String?,
      );
}
