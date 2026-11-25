import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as image;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_version.dart';
import '../models/checklist_project.dart';
import '../models/note.dart';

class ChecklistBackup {
  const ChecklistBackup({
    required this.projects,
    required this.notes,
    required this.noteCategories,
    required this.selectedProjectId,
    required this.selectedNoteId,
  });

  final List<ChecklistProject> projects;
  final List<NoteEntry> notes;
  final List<NoteCategory> noteCategories;
  final String? selectedProjectId;
  final String? selectedNoteId;
}

class LocalStore {
  static const _projectsKey = 'checklist.projects.v1';
  static const _darkModeKey = 'checklist.darkMode.v1';
  static const _themeKey = 'checklist.theme.v1';
  static const _themeColoursKey = 'checklist.themeColours.v1';
  static const _languageKey = 'checklist.language.v1';
  static const _sortKey = 'checklist.sort.v1';
  static const _noteSortKey = 'checklist.noteSort.v1';
  static const _selectedProjectKey = 'checklist.selectedProject.v1';
  static const _heartAnimationKey = 'checklist.heartAnimation.v1';
  static const _notesKey = 'checklist.notes.v1';
  static const _noteCategoriesKey = 'checklist.noteCategories.v1';
  static const _selectedNoteKey = 'checklist.selectedNote.v1';
  static const _welcomeShownKey = 'checklist.welcome.v1';
  static const _lastSeenVersionKey = 'checklist.lastSeenVersion.v1';

  Future<List<ChecklistProject>> loadProjects() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_projectsKey);
    if (encoded == null) return [];

    final decoded = jsonDecode(encoded) as List<dynamic>;
    return decoded
        .map(
          (project) =>
              ChecklistProject.fromJson(project as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveProjects(List<ChecklistProject> projects) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _projectsKey,
      jsonEncode(projects.map((project) => project.toJson()).toList()),
    );
    if (!saved) throw StateError('Could not save your projects.');
  }

  Future<List<NoteEntry>> loadNotes() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_notesKey);
    if (encoded == null) return [];

    final decoded = jsonDecode(encoded) as List<dynamic>;
    return decoded
        .map((note) => NoteEntry.fromJson(note as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveNotes(List<NoteEntry> notes) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _notesKey,
      jsonEncode(notes.map((note) => note.toJson()).toList()),
    );
    if (!saved) throw StateError('Could not save your notes.');
  }

  Future<List<NoteCategory>> loadNoteCategories() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_noteCategoriesKey);
    if (encoded == null) return [];

    final decoded = jsonDecode(encoded) as List<dynamic>;
    return decoded
        .map(
          (category) => NoteCategory.fromJson(category as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveNoteCategories(List<NoteCategory> categories) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _noteCategoriesKey,
      jsonEncode(categories.map((category) => category.toJson()).toList()),
    );
    if (!saved) throw StateError('Could not save your note categories.');
  }

  Future<bool> loadDarkMode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_darkModeKey) ?? true;
  }

  Future<void> saveDarkMode(bool isDark) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(_darkModeKey, isDark);
    if (!saved) throw StateError('Could not save the appearance setting.');
  }

  Future<String?> loadTheme() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_themeKey);
  }

  Future<void> saveTheme(String theme) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_themeKey, theme);
    if (!saved) throw StateError('Could not save the theme setting.');
  }

  Future<Map<String, Map<String, int>>> loadThemeColours() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_themeColoursKey);
    if (encoded == null) return {};
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) return {};
      return {
        for (final theme in decoded.entries)
          if (theme.value case final Map<String, dynamic> values)
            theme.key: {
              for (final colour in values.entries)
                if (colour.value case final int argb
                    when argb >= 0xff000000 && argb <= 0xffffffff)
                  colour.key: argb,
            },
      };
    } on FormatException {
      return {};
    }
  }

  Future<void> saveThemeColours(Map<String, Map<String, int>> colours) async {
    final preferences = await SharedPreferences.getInstance();
    final saved =
        await preferences.setString(_themeColoursKey, jsonEncode(colours));
    if (!saved) throw StateError('Could not save the theme colours.');
  }

  Future<String?> loadLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_languageKey);
  }

  Future<void> saveLanguage(String language) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_languageKey, language);
    if (!saved) throw StateError('Could not save the language setting.');
  }

  Future<Uint8List> createBackupBytes() async {
    final results = await Future.wait<Object?>([
      loadProjects(),
      loadNotes(),
      loadNoteCategories(),
      loadSelectedProjectId(),
      loadSelectedNoteId(),
    ]);
    final projects = results[0]! as List<ChecklistProject>;
    final notes = results[1]! as List<NoteEntry>;
    final categories = results[2]! as List<NoteCategory>;
    final payload = <String, Object?>{
      'format': 'checklist-backup',
      'schemaVersion': 1,
      'appVersion': checklistVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'projects': projects.map((project) => project.toJson()).toList(),
      'notes': notes.map((note) => note.toJson()).toList(),
      'noteCategories':
          categories.map((category) => category.toJson()).toList(),
      'selectedProjectId': results[3] as String?,
      'selectedNoteId': results[4] as String?,
    };
    return Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
    );
  }

  ChecklistBackup decodeBackup(Uint8List bytes) {
    if (bytes.isEmpty) throw const FormatException('The backup file is empty.');
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != 'checklist-backup' ||
        decoded['schemaVersion'] != 1) {
      throw const FormatException('This is not a supported CHECKLIST backup.');
    }

    List<Map<String, dynamic>> mapsFor(String key) {
      final value = decoded[key];
      if (value is! List<dynamic>) {
        throw FormatException('The backup is missing $key.');
      }
      return value.map((item) {
        if (item is! Map<String, dynamic>) {
          throw FormatException('The backup contains invalid $key data.');
        }
        return item;
      }).toList();
    }

    final projects = mapsFor('projects').map((json) {
      // Cover files live in app-private storage and are deliberately not
      // restored as broken paths on another installation.
      return ChecklistProject.fromJson({...json, 'coverImagePath': null});
    }).toList();
    if (projects.isEmpty) {
      throw const FormatException('The backup does not contain a checklist.');
    }
    final notes = mapsFor('notes').map(NoteEntry.fromJson).toList();
    final categories =
        mapsFor('noteCategories').map(NoteCategory.fromJson).toList();
    final selectedProjectId = decoded['selectedProjectId'] as String?;
    final selectedNoteId = decoded['selectedNoteId'] as String?;
    return ChecklistBackup(
      projects: projects,
      notes: notes,
      noteCategories: categories,
      selectedProjectId: projects.any((item) => item.id == selectedProjectId)
          ? selectedProjectId
          : projects.first.id,
      selectedNoteId: notes.any((item) => item.id == selectedNoteId)
          ? selectedNoteId
          : (notes.isEmpty ? null : notes.first.id),
    );
  }

  Future<void> restoreBackup(ChecklistBackup backup) async {
    await Future.wait([
      saveProjects(backup.projects),
      saveNotes(backup.notes),
      saveNoteCategories(backup.noteCategories),
      saveSelectedProjectId(
        backup.selectedProjectId ?? backup.projects.first.id,
      ),
      saveSelectedNoteId(backup.selectedNoteId),
    ]);
  }

  Future<bool> loadHeartAnimationEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_heartAnimationKey) ?? false;
  }

  Future<void> saveHeartAnimationEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(_heartAnimationKey, enabled);
    if (!saved) throw StateError('could not save the heart animation setting.');
  }

  Future<String?> loadSort() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_sortKey);
  }

  Future<void> saveSort(String sort) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_sortKey, sort);
    if (!saved) throw StateError('Could not save the project sort order.');
  }

  Future<String?> loadNoteSort() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_noteSortKey);
  }

  Future<void> saveNoteSort(String sort) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_noteSortKey, sort);
    if (!saved) throw StateError('Could not save the note sort order.');
  }

  Future<bool> loadWelcomeShown() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_welcomeShownKey) ?? false;
  }

  Future<void> saveWelcomeShown() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(_welcomeShownKey, true);
    if (!saved) throw StateError('Could not save the welcome setting.');
  }

  Future<String?> loadLastSeenVersion() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_lastSeenVersionKey);
  }

  Future<void> saveLastSeenVersion(String version) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_lastSeenVersionKey, version);
    if (!saved) throw StateError('Could not save the last seen version.');
  }

  Future<String?> loadSelectedProjectId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_selectedProjectKey);
  }

  Future<void> saveSelectedProjectId(String projectId) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_selectedProjectKey, projectId);
    if (!saved) throw StateError('Could not save the selected checklist.');
  }

  Future<String?> loadSelectedNoteId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_selectedNoteKey);
  }

  Future<void> saveSelectedNoteId(String? noteId) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = noteId == null
        ? await preferences.remove(_selectedNoteKey)
        : await preferences.setString(_selectedNoteKey, noteId);
    if (!saved) throw StateError('Could not save the selected note.');
  }

  Future<String?> pickCoverSource() async {
    final selection = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'],
    );
    if (selection == null) return null;

    final sourcePath = selection.path;
    if (sourcePath == null) {
      throw StateError('The selected image could not be opened.');
    }
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('The selected image is no longer available.');
    }
    return source.path;
  }

  Future<String> saveCoverBytes(
    Uint8List bytes, {
    String extension = '.png',
  }) async {
    if (bytes.isEmpty) throw StateError('The selected image is empty.');
    final coversDirectory = await _coverDirectory();
    final safeExtension = extension == '.jpg' ? '.jpg' : '.png';
    final destination = File(
      '${coversDirectory.path}/cover_${DateTime.now().microsecondsSinceEpoch}$safeExtension',
    );
    await destination.writeAsBytes(bytes, flush: true);
    return destination.path;
  }

  Future<String> cropAndSaveCameraCover(
    String sourcePath, {
    required double aspectRatio,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('The camera photo is no longer available.');
    }
    if (await source.length() > 40 * 1024 * 1024) {
      throw StateError('Choose an image smaller than 40 MB.');
    }
    final decoded = image.decodeImage(await source.readAsBytes());
    if (decoded == null) {
      throw StateError('The camera photo could not be opened.');
    }
    final oriented = image.bakeOrientation(decoded);
    var cropWidth = oriented.width;
    var cropHeight = (cropWidth / aspectRatio).round();
    if (cropHeight > oriented.height) {
      cropHeight = oriented.height;
      cropWidth = (cropHeight * aspectRatio).round();
    }
    final cropped = image.copyCrop(
      oriented,
      x: ((oriented.width - cropWidth) / 2).round(),
      y: ((oriented.height - cropHeight) / 2).round(),
      width: cropWidth,
      height: cropHeight,
    );
    return saveCoverBytes(
      Uint8List.fromList(image.encodeJpg(cropped, quality: 92)),
      extension: '.jpg',
    );
  }

  Future<void> deleteCover(String? path) async {
    if (path == null || path.isEmpty) return;

    final supportDirectory = await getApplicationSupportDirectory();
    final coversDirectory = Directory('${supportDirectory.path}/covers');
    final coversPath = coversDirectory.absolute.path;
    final coverPath = File(path).absolute.path;

    // Only delete files created inside this app's own cover directory.
    if (coverPath != coversPath &&
        !coverPath.startsWith('$coversPath${Platform.pathSeparator}')) {
      return;
    }

    final cover = File(coverPath);
    if (await cover.exists()) await cover.delete();
  }

  Future<Directory> _coverDirectory() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final coversDirectory = Directory('${supportDirectory.path}/covers');
    await coversDirectory.create(recursive: true);
    return coversDirectory;
  }
}
