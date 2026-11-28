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

// Older releases interpreted every star outside a link as a formatting toggle.
// Stars terminate links in the legacy parser, so they can be converted directly.
final _legacyStarMarkers = RegExp(r'[\uE000-\uE003]|\*\*?');

String _readNoteContent(Map<String, dynamic> json) {
  final text = json['content'] as String? ?? '';
  if (json['contentFormat'] == 2 || !text.contains('*')) return text;
  var styles = 0;
  return text.replaceAllMapped(_legacyStarMarkers, (match) {
    final token = match[0]!;
    if (token.startsWith('*')) {
      final index = token.length == 2 ? 0 : 1;
      final bit = 1 << index;
      styles ^= bit;
      return String.fromCharCode(
          0xe000 + index * 2 + ((styles & bit) == 0 ? 1 : 0));
    }
    final marker = token.codeUnitAt(0) - 0xe000;
    final bit = 1 << (marker ~/ 2);
    styles = marker.isEven ? styles | bit : styles & ~bit;
    return token;
  });
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
        'contentFormat': 2,
        'categoryId': categoryId,
      };

  factory NoteEntry.fromJson(Map<String, dynamic> json) => NoteEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        content: _readNoteContent(json),
        categoryId: json['categoryId'] as String?,
      );
}
