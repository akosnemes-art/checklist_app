import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_library;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_localizations.dart';
import 'app_version.dart';
import 'models/checklist_project.dart';
import 'models/note.dart';
import 'services/local_store.dart';
import 'services/note_links.dart';
import 'services/ocr_service.dart';
import 'services/reminder_service.dart';
import 'services/website_previews.dart';

part 'black_metal_finish.dart';
part 'appearance_motion.dart';
part 'metal_theme.dart';
part 'modern_themes.dart';
part 'theme_colours.dart';
part 'note_formatting.dart';
part 'photo_camera_dialog.dart';
part 'popup_animation.dart';
part 'website_gallery.dart';

const _backgroundDark = Color(0xFF0D0912);
const _surfaceDark = Color(0xFF17101F);
const _brandPurple = Color(0xFF922FD0);
const _brandCyan = Color(0xFF05E1E6);
const _brandMagenta = Color(0xFFF000E6);
const _brandYellow = Color(0xFFF3ED23);
const _borderWhite = Color(0xFFF8F7FF);
const _darkPurpleButton = Color(0xFF4A185F);
const _checklistSidebar = Color(0xFF26102F);
const _notesSidebar = Color(0xFF0B1D3B);
const _deepBlueButton = Color(0xFF1553A3);
const _defaultNoteBlue = Color(0xFF5A9BFF);
const _switchGrey = Color(0xFF9AA0AA);
const _lightBackground = Color(0xFFF7F5F2);
const _lightSurface = Color(0xFFE7E6E3);
const _lightSidebar = Color(0xFFD5D4D1);
const _lightLine = Color(0xFF858C94);
const _lightControl = Color(0xFF666B70);
const _lightText = Color(0xFF101010);
const _pastelPeach = Color(0xFFFBDCC4);
const _pastelWhite = Color(0xFFFFFFFF);
const _pastelYellow = Color(0xFFF8F2C8);
const _pastelGreen = Color(0xFFBED4C7);
const _pastelMauve = Color(0xFFC7B0B8);
const _pastelSelectedNote = _lightBackground;
const _pastelPriorityHigh = Color(0xFFE31F26);
const _pastelPriorityMedium = Color(0xFF00978D);
const _pastelPriorityLow = Color(0xFFB5B1D8);
const _pencilPriorityHigh = Color(0xFF0E2F44);
const _pencilPriorityMedium = Color(0xFF64696A);
const _pencilPriorityLow = Color(0xFF999999);
const _renameNotePastelBlue = Color(0xFFD9EAF7);
const _taskReorderHoldDuration = Duration(milliseconds: 140);
const _linkedNoteCueDuration = Duration(milliseconds: 140);
const _sidebarEntryFadeDuration = Duration(milliseconds: 240);
const _coverAspectRatio = 16 / 9;
const _buildChanges = <String>[
  'Notes extend to the status bar and use a solid writing surface.',
  'Pixel has CRT noise and theme changes draw from bottom to top.',
  'The version fades out when Settings opens.',
];
const _implementedChanges = <String>[
  ..._buildChanges,
  'Added the Pixel and Glass themes.',
  'Added separate colour customisation for each theme.',
  'Gave Black Metal blood-red controls and a faster steel glint.',
  'Added Black Metal with distressed panels and a soft moving shine.',
  'Renamed Goth to Copper and removed the circular artwork.',
  'Photo imports preserve detected bold, italic, and underlined text.',
  'The launcher icon lettering is centred.',
];
const _noteColours = <Color>[
  Color(0xFFE85D75),
  Color(0xFFFF8A5B),
  Color(0xFFF3ED23),
  Color(0xFF70D66B),
  Color(0xFF38B87C),
  Color(0xFF229FE3),
  Color(0xFF3977E3),
  Color(0xFF05E1E6),
  Color(0xFF7D5FFF),
  Color(0xFF922FD0),
  Color(0xFFF000E6),
  Color(0xFFE94BBD),
  Color(0xFFF5A3C7),
  Color(0xFFC8A97E),
  Color(0xFF9EA7B3),
  Color(0xFFF8F7FF),
  Color(0xFF4DD4AC),
  Color(0xFFFF6B6B),
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
    );
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
  runApp(const ChecklistApp());
}

Future<T?> showDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _popupDuration,
    pageBuilder: (dialogContext, animation, secondaryAnimation) =>
        builder(dialogContext),
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
      opacity: animation.drive(CurveTween(curve: const Interval(0, 0.12))),
      child: child,
    ),
  );
}

enum AppTheme {
  boi,
  pencil,
  pastel,
  copper,
  blackMetal,
  pixel,
  glass;

  bool get isDark => this == boi || this == pixel || _metalPalette != null;

  // Builds that call Copper "Goth" use this same saved preference.
  String get _preferenceValue => this == copper ? 'goth' : name;

  _MetalPalette? get _metalPalette => switch (this) {
        copper => _copperPalette,
        blackMetal => _blackMetalPalette,
        _ => null,
      };

  _ModernPalette? get _modernPalette => switch (this) {
        pixel => _pixelPalette,
        glass => _glassPalette,
        _ => null,
      };
}

class ChecklistApp extends StatefulWidget {
  const ChecklistApp({super.key});

  @override
  State<ChecklistApp> createState() => _ChecklistAppState();
}

class _ChecklistAppState extends State<ChecklistApp> {
  final _store = LocalStore();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  AppTheme _appTheme = AppTheme.boi;
  AppLanguage _appLanguage = AppLanguage.english;
  Map<String, Map<String, int>> _themeColours = {};
  bool _notesActive = false;

  @override
  void initState() {
    super.initState();
    _loadAppearance();
  }

  Future<void> _loadAppearance() async {
    try {
      final results = await Future.wait<Object?>([
        _store.loadTheme(),
        _store.loadDarkMode(),
        _store.loadLanguage(),
        _store.loadThemeColours(),
      ]);
      final savedTheme = results[0] as String?;
      final legacyDarkMode = results[1]! as bool;
      final savedLanguage = results[2] as String?;
      final theme = AppTheme.values.where((value) =>
          value._preferenceValue ==
          (savedTheme == 'newsprint' ? 'pixel' : savedTheme));
      final language = AppLanguage.values.where(
        (value) => value.name == savedLanguage,
      );
      if (!mounted) return;
      setState(() {
        _appTheme = theme.isNotEmpty
            ? theme.first
            : legacyDarkMode
                ? AppTheme.boi
                : AppTheme.pencil;
        if (language.isNotEmpty) _appLanguage = language.first;
        _themeColours = results[3]! as Map<String, Map<String, int>>;
      });
      if (savedTheme == 'newsprint') await _setTheme(AppTheme.pixel);
    } catch (error) {
      debugPrint('Could not load appearance setting: $error');
    }
  }

  Future<void> _setLanguage(AppLanguage value) async {
    setState(() => _appLanguage = value);
    try {
      await _store.saveLanguage(value.name);
    } catch (error) {
      debugPrint('Could not save language setting: $error');
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: AppText('Could not save language setting: $error')),
      );
    }
  }

  Future<void> _setTheme(AppTheme value) async {
    setState(() => _appTheme = value);
    try {
      await Future.wait([
        _store.saveTheme(value._preferenceValue),
        _store.saveDarkMode(value.isDark),
      ]);
    } catch (error) {
      debugPrint('Could not save theme setting: $error');
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: AppText('Could not save theme setting: $error')),
      );
    }
  }

  void _setNotesActive(bool value) {
    if (_notesActive != value) setState(() => _notesActive = value);
  }

  Future<void> _setThemeColours(AppTheme theme, Map<String, int> values) async {
    final updated = {..._themeColours};
    if (values.isEmpty) {
      updated.remove(theme._preferenceValue);
    } else {
      updated[theme._preferenceValue] = Map.unmodifiable(values);
    }
    setState(() => _themeColours = updated);
    try {
      await _store.saveThemeColours(updated);
    } catch (error) {
      debugPrint('Could not save theme colours: $error');
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(content: AppText('could not save theme colours')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const squareShape = RoundedRectangleBorder();
    final accent = _notesActive ? _defaultNoteBlue : _brandPurple;
    const lightAccent = _lightControl;
    final dark = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _backgroundDark,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: _notesActive ? _defaultNoteBlue : _brandCyan,
        surface: _surfaceDark,
      ),
      dividerColor: const Color(0xFF5B5264),
      fontFamily: 'Roboto',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: Color(0xFF303552)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(squareShape),
          side: WidgetStatePropertyAll(
            BorderSide(
              color: _notesActive ? _defaultNoteBlue : _borderWhite,
              width: 2,
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(squareShape),
          side: WidgetStatePropertyAll(
            BorderSide(
              color: _notesActive ? _defaultNoteBlue : _borderWhite,
              width: 2,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(squareShape),
          side: WidgetStatePropertyAll(
            BorderSide(
              color: _notesActive ? _defaultNoteBlue : _borderWhite,
              width: 2,
            ),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(squareShape),
          side: WidgetStatePropertyAll(
            BorderSide(
              color: _notesActive ? _defaultNoteBlue : _borderWhite,
              width: 2,
            ),
          ),
        ),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: _defaultNoteBlue, width: 2),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: _defaultNoteBlue, width: 2),
        ),
      ),
      chipTheme: const ChipThemeData(
        shape: squareShape,
        side: BorderSide(color: _borderWhite, width: 2),
      ),
      drawerTheme: const DrawerThemeData(
        shape: squareShape,
        endShape: squareShape,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: squareShape,
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 450),
        decoration: const BoxDecoration(
          color: Color(0xFF4B4353),
          borderRadius: BorderRadius.zero,
        ),
      ),
      useMaterial3: true,
    );
    final light = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBackground,
      colorScheme: const ColorScheme.light(
        primary: lightAccent,
        secondary: _lightLine,
        surface: _lightSurface,
        onSurface: _lightText,
      ),
      dividerColor: _lightLine,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        hintStyle: const TextStyle(color: _switchGrey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: _lightLine),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(squareShape),
          side: WidgetStatePropertyAll(
            BorderSide(color: lightAccent, width: 2),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(squareShape),
          side: WidgetStatePropertyAll(
            BorderSide(color: lightAccent, width: 2),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(squareShape),
          side: WidgetStatePropertyAll(
            BorderSide(color: lightAccent, width: 2),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(squareShape),
          side: WidgetStatePropertyAll(
            BorderSide(color: lightAccent, width: 2),
          ),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: _lightSurface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: _defaultNoteBlue, width: 2),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: _lightSurface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: _lightLine, width: 2),
        ),
      ),
      chipTheme: const ChipThemeData(
        shape: squareShape,
        side: BorderSide(color: _lightLine, width: 2),
      ),
      drawerTheme: const DrawerThemeData(
        shape: squareShape,
        endShape: squareShape,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: squareShape,
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 450),
        decoration: const BoxDecoration(
          color: Color(0xFF272A42),
          borderRadius: BorderRadius.zero,
        ),
      ),
      useMaterial3: true,
    );
    final pastelAccent = _notesActive ? _pastelMauve : _pastelGreen;
    final pastel = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: _pastelPeach,
      colorScheme: ColorScheme.light(
        primary: pastelAccent,
        secondary: _pastelYellow,
        surface: _pastelWhite,
        onSurface: _lightText,
      ),
      dividerColor: _pastelMauve,
      fontFamily: 'Roboto',
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: _pastelWhite,
        hintStyle: TextStyle(color: _lightControl),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _pastelMauve),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(squareShape),
          side: WidgetStatePropertyAll(
            BorderSide(color: pastelAccent, width: 2),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(squareShape),
          side: WidgetStatePropertyAll(
            BorderSide(color: pastelAccent, width: 2),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(squareShape),
          side: WidgetStatePropertyAll(
            BorderSide(color: pastelAccent, width: 2),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(squareShape),
          side: WidgetStatePropertyAll(
            BorderSide(color: pastelAccent, width: 2),
          ),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: _pastelWhite,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: _defaultNoteBlue, width: 2),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: _pastelWhite,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: _pastelYellow, width: 2),
        ),
      ),
      chipTheme: const ChipThemeData(
        shape: squareShape,
        side: BorderSide(color: _pastelMauve, width: 2),
      ),
      drawerTheme: const DrawerThemeData(
        shape: squareShape,
        endShape: squareShape,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: squareShape,
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 450),
        decoration: const BoxDecoration(
          color: _pastelMauve,
          borderRadius: BorderRadius.zero,
        ),
      ),
      useMaterial3: true,
    );

    final selectedTheme = switch (_appTheme) {
      AppTheme.boi => dark,
      AppTheme.pencil => light,
      AppTheme.pastel => pastel,
      AppTheme.copper =>
        _buildMetalTheme(dark, _copperPalette, notesActive: _notesActive),
      AppTheme.blackMetal =>
        _buildMetalTheme(dark, _blackMetalPalette, notesActive: _notesActive),
      AppTheme.pixel => _buildModernTheme(dark, _pixelPalette,
          notes: _notesActive, pixel: true),
      AppTheme.glass => _buildModernTheme(light, _glassPalette,
          notes: _notesActive, pixel: false),
    };
    final colours =
        _themeColours[_appTheme._preferenceValue] ?? const <String, int>{};

    return MaterialApp(
      title: 'Checklist',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme:
          _applyThemeColours(selectedTheme, _appTheme, colours, _notesActive),
      locale: _appLanguage.locale,
      supportedLocales:
          AppLanguage.values.map((language) => language.locale).toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ChecklistHome(
        appTheme: _appTheme,
        appLanguage: _appLanguage,
        onThemeChanged: _setTheme,
        themeColours: colours,
        onThemeColoursChanged: _setThemeColours,
        onLanguageChanged: _setLanguage,
        onNotesModeChanged: _setNotesActive,
      ),
    );
  }
}

enum ProjectSort { newest, oldest, alphabetical, priority }

enum NoteSort { newest, oldest, alphabetical, category }

enum _SettingsPage { main, themes, language, backup, about }

class ChecklistHome extends StatefulWidget {
  const ChecklistHome({
    required this.appTheme,
    required this.appLanguage,
    required this.onThemeChanged,
    required this.themeColours,
    required this.onThemeColoursChanged,
    required this.onLanguageChanged,
    required this.onNotesModeChanged,
    super.key,
  });

  final AppTheme appTheme;
  final AppLanguage appLanguage;
  final ValueChanged<AppTheme> onThemeChanged;
  final Map<String, int> themeColours;
  final void Function(AppTheme, Map<String, int>) onThemeColoursChanged;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ValueChanged<bool> onNotesModeChanged;

  bool get isDark => appTheme.isDark;
  bool get isPastel => appTheme == AppTheme.pastel;

  @override
  State<ChecklistHome> createState() => _ChecklistHomeState();
}

class _ChecklistHomeState extends State<ChecklistHome>
    with TickerProviderStateMixin {
  _MetalPalette? get _metalPalette => widget.appTheme._metalPalette;
  bool get _blackMetal => widget.appTheme == AppTheme.blackMetal;
  _ModernPalette? get _modernPalette => widget.appTheme._modernPalette;

  late final _noteReveal = _newContentReveal();
  late final _projectReveal = _newContentReveal();
  late final _themeBuild = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );

  AnimationController _newContentReveal() => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
        value: 1,
      );

  void _revealContent(AnimationController controller) {
    if (!MediaQuery.disableAnimationsOf(context)) controller.forward(from: 0);
  }

  Widget _contentFade(
      Animation<double> animation, double start, double end, Widget child) {
    return FadeTransition(
      opacity: CurveTween(curve: Interval(start, end, curve: Curves.easeOut))
          .animate(animation),
      child: child,
    );
  }

  final _store = LocalStore();
  final _ocrService = OcrService();
  final _reminderService = ReminderService();
  final _websitePreviews = WebsitePreviews();
  final _pendingWebsiteLinks = <String, Set<Uri>>{};
  final _taskController = TextEditingController();
  final _taskFocusNode = FocusNode();
  final _noteFocusNode = FocusNode();
  late final _FormattedNoteController _noteController;
  NoteLink? _pressedNoteLink;
  bool _noteLinkBusy = false;

  List<ChecklistProject> _projects = [];
  List<NoteEntry> _notes = [];
  List<NoteCategory> _noteCategories = [];
  String? _selectedId;
  String? _selectedNoteId;
  ProjectSort _sort = ProjectSort.newest;
  NoteSort _noteSort = NoteSort.newest;
  bool _loading = true;
  bool _mobileDrawerActive = false;
  bool _showNotes = false;
  bool _heartAnimationEnabled = false;
  String? _loadError;
  Timer? _noteSaveTimer;
  Timer? _websitePreviewTimer;
  Timer? _heartTapResetTimer;
  Timer? _infoTapTimer;
  int _heartTapCount = 0;
  int _heartRestartSignal = 0;
  bool _welcomeScheduled = false;
  bool _ocrBusy = false;
  bool _backupBusy = false;
  bool _settingsOpen = false;
  _SettingsPage _settingsPage = _SettingsPage.main;
  final Set<String> _sidebarExitingIds = <String>{};
  int _activeNoteFormats = 0;

  ChecklistProject? get _selected {
    for (final project in _projects) {
      if (project.id == _selectedId) return project;
    }
    return null;
  }

  NoteEntry? get _selectedNote {
    for (final note in _notes) {
      if (note.id == _selectedNoteId) return note;
    }
    return null;
  }

  NoteCategory? _categoryFor(NoteEntry note) {
    for (final category in _noteCategories) {
      if (category.id == note.categoryId) return category;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _noteController = _FormattedNoteController();
    _noteController.addListener(_syncActiveNoteFormats);
    _load();
  }

  void _syncActiveNoteFormats() {
    final active =
        _noteController.formatting.activeStyles(_noteController.selection);
    if (active == _activeNoteFormats || !mounted) return;
    setState(() => _activeNoteFormats = active);
  }

  @override
  void dispose() {
    _noteReveal.dispose();
    _projectReveal.dispose();
    _themeBuild.dispose();
    _noteSaveTimer?.cancel();
    _websitePreviewTimer?.cancel();
    _heartTapResetTimer?.cancel();
    _infoTapTimer?.cancel();
    _taskController.dispose();
    _taskFocusNode.dispose();
    _noteFocusNode.dispose();
    _noteController.removeListener(_syncActiveNoteFormats);
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final results = await Future.wait<Object?>([
        _store.loadProjects(),
        _store.loadSort(),
        _store.loadSelectedProjectId(),
        _store.loadNotes(),
        _store.loadNoteCategories(),
        _store.loadSelectedNoteId(),
        _store.loadHeartAnimationEnabled(),
        _store.loadNoteSort(),
      ]);
      final projects = results[0]! as List<ChecklistProject>;
      final savedSortName = results[1] as String?;
      final savedSelectedId = results[2] as String?;
      final notes = results[3]! as List<NoteEntry>;
      final noteCategories = results[4]! as List<NoteCategory>;
      final savedSelectedNoteId = results[5] as String?;
      final heartAnimationEnabled = results[6]! as bool;
      final savedNoteSortName = results[7] as String?;
      if (!mounted) return;
      if (projects.isEmpty) {
        final firstProject = ChecklistProject(
          id: _newId(),
          name: 'my first checklist',
          createdAt: DateTime.now(),
        );
        projects.add(firstProject);
        await _store.saveProjects(projects);
      }
      if (!mounted) return;
      final compatibleSortName =
          savedSortName == 'importance' ? 'priority' : savedSortName;
      final savedSort = ProjectSort.values.where(
        (sort) => sort.name == compatibleSortName,
      );
      final savedNoteSort = NoteSort.values.where(
        (sort) => sort.name == savedNoteSortName,
      );
      final selectedId =
          projects.any((project) => project.id == savedSelectedId)
              ? savedSelectedId
              : projects.first.id;
      final selectedNoteId = notes.any((note) => note.id == savedSelectedNoteId)
          ? savedSelectedNoteId
          : (notes.isEmpty ? null : notes.first.id);
      setState(() {
        _projects = projects;
        _notes = notes;
        _noteCategories = noteCategories;
        _selectedId = selectedId;
        _selectedNoteId = selectedNoteId;
        _heartAnimationEnabled = heartAnimationEnabled;
        _noteController.text = _selectedNote?.content ?? '';
        if (savedSort.isNotEmpty) _sort = savedSort.first;
        if (savedNoteSort.isNotEmpty) _noteSort = savedNoteSort.first;
        _loading = false;
      });
      await _syncReminders();
      if (!_welcomeScheduled) {
        _welcomeScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showWelcomeIfNeeded();
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _loading = false;
      });
    }
  }

  Future<bool> _persist() async {
    try {
      await _store.saveProjects(_projects);
      await _syncReminders();
      return true;
    } catch (error) {
      if (mounted) _showMessage('Could not save changes: $error');
      return false;
    }
  }

  Future<void> _syncReminders() async {
    try {
      await _reminderService.sync(_projects);
    } on PlatformException catch (error) {
      debugPrint('Could not schedule checklist reminders: ${error.message}');
    } on MissingPluginException {
      debugPrint('Checklist alarms are available on Android.');
    }
  }

  Future<void> _changeSort(ProjectSort sort) async {
    setState(() => _sort = sort);
    try {
      await _store.saveSort(sort.name);
    } catch (error) {
      if (mounted) _showMessage('Could not save the sort order: $error');
    }
  }

  Future<void> _changeNoteSort(NoteSort sort) async {
    setState(() => _noteSort = sort);
    try {
      await _store.saveNoteSort(sort.name);
    } catch (error) {
      if (mounted) _showMessage('Could not save the note sort order: $error');
    }
  }

  Future<void> _showWelcomeIfNeeded() async {
    try {
      final welcomeShown = await _store.loadWelcomeShown();
      final lastSeenRelease = await _store.loadLastSeenVersion();
      if (!mounted) return;

      // Legacy installs only stored the one-time boolean. Preserve that state
      // while moving them onto release-aware version/build tracking.
      if (welcomeShown && lastSeenRelease == null) {
        await _store.saveLastSeenVersion(checklistRelease);
        return;
      }
      if (welcomeShown && lastSeenRelease == checklistRelease) return;

      await _store.saveWelcomeShown();
      await _store.saveLastSeenVersion(checklistRelease);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _WelcomeDialog(),
      );
    } catch (error) {
      debugPrint('Could not show the welcome window: $error');
    }
  }

  Future<void> _rememberSelectedProject(String projectId) async {
    try {
      await _store.saveSelectedProjectId(projectId);
    } catch (error) {
      if (mounted) _showMessage('Could not remember that selection: $error');
    }
  }

  Future<bool> _persistNotes() async {
    try {
      await _store.saveNotes(_notes);
      return true;
    } catch (error) {
      if (mounted) _showMessage('Could not save your notes: $error');
      return false;
    }
  }

  Future<bool> _persistNoteCategories() async {
    try {
      await _store.saveNoteCategories(_noteCategories);
      return true;
    } catch (error) {
      if (mounted) _showMessage('Could not save note categories: $error');
      return false;
    }
  }

  Future<void> _rememberSelectedNote(String? noteId) async {
    try {
      await _store.saveSelectedNoteId(noteId);
    } catch (error) {
      if (mounted) _showMessage('Could not remember that note: $error');
    }
  }

  void _openNotes() {
    setState(() {
      _showNotes = true;
      _noteController.text = _selectedNote?.content ?? '';
      _activeNoteFormats = 0;
    });
    widget.onNotesModeChanged(true);
  }

  void _openChecklist() {
    setState(() => _showNotes = false);
    widget.onNotesModeChanged(false);
  }

  Future<void> _handleHeartSecretTap() async {
    _heartTapResetTimer?.cancel();
    _heartTapCount += 1;
    if (_heartTapCount == 3) {
      _infoTapTimer?.cancel();
      _infoTapTimer = Timer(const Duration(milliseconds: 450), () {
        if (!mounted || _heartTapCount != 3) return;
        _heartTapCount = 0;
        showDialog<void>(
          context: context,
          builder: (context) => const _VersionInfoDialog(),
        );
      });
    } else if (_heartTapCount > 3) {
      _infoTapTimer?.cancel();
    }
    if (_heartTapCount < 7) {
      _heartTapResetTimer = Timer(const Duration(seconds: 2), () {
        _heartTapCount = 0;
        _infoTapTimer?.cancel();
      });
      return;
    }

    _infoTapTimer?.cancel();
    _heartTapCount = 0;
    final enabled = !_heartAnimationEnabled;
    setState(() {
      _heartAnimationEnabled = enabled;
      if (enabled) _heartRestartSignal += 1;
    });
    try {
      await _store.saveHeartAnimationEnabled(enabled);
    } catch (error) {
      if (mounted) _showMessage('Could not save the heart animation: $error');
    }
  }

  void _restartHeartAnimation() {
    if (!_heartAnimationEnabled) return;
    setState(() => _heartRestartSignal += 1);
  }

  Future<void> _createNote() async {
    final details = await showDialog<_NoteDialogResult>(
      context: context,
      builder: (context) => _NoteDetailsDialog(
        title: 'make a note',
        initialText: '',
        categories: _noteCategories,
      ),
    );
    if (details == null || !mounted) return;

    final note = NoteEntry(
      id: _newId(),
      name: details.name,
      createdAt: DateTime.now(),
      categoryId: details.categoryId,
    );
    setState(() {
      _notes.insert(0, note);
      _selectedNoteId = note.id;
      _showNotes = true;
      _noteController.clear();
    });
    widget.onNotesModeChanged(true);
    await Future.wait([_persistNotes(), _rememberSelectedNote(note.id)]);
  }

  void _selectNote(NoteEntry note) {
    if (_selectedNoteId != note.id) {
      _noteFocusNode.unfocus();
      _noteController.highlightLink(null);
      _revealContent(_noteReveal);
    }
    setState(() {
      _selectedNoteId = note.id;
      _noteController.text = note.content;
      _activeNoteFormats = 0;
    });
    _rememberSelectedNote(note.id);
  }

  void _updateNoteContent(String content) {
    final note = _selectedNote;
    if (note == null) return;
    final previousLinks = _websiteLinks(note.content).toSet();
    note.content = content;
    final nextLinks = _websiteLinks(content).toSet();
    final pending = _pendingWebsiteLinks.putIfAbsent(note.id, () => {});
    pending
      ..retainAll(nextLinks)
      ..addAll(nextLinks.difference(previousLinks));
    if (pending.isEmpty) _pendingWebsiteLinks.remove(note.id);
    _websitePreviewTimer?.cancel();
    if (_pendingWebsiteLinks.isNotEmpty) {
      _websitePreviewTimer =
          Timer(const Duration(seconds: 1), _captureWebsitePreviews);
    }
    setState(() {});
    _noteSaveTimer?.cancel();
    _noteSaveTimer = Timer(const Duration(milliseconds: 250), _persistNotes);
  }

  Iterable<Uri> _websiteLinks(String content) =>
      findNoteLinks(content).map((link) => link.uri).where(isWebsiteLink);

  void _captureWebsitePreviews() {
    for (final note in _notes) {
      final pending = _pendingWebsiteLinks[note.id];
      if (pending == null) continue;
      for (final uri
          in _websiteLinks(note.content).toSet().intersection(pending)) {
        unawaited(_websitePreviews.load(uri));
      }
    }
    _pendingWebsiteLinks.clear();
  }

  Future<void> _openWebsiteGallery() => showDialog<void>(
        context: context,
        builder: (context) => _WebsiteGallery(
          links: _notes
              .expand((note) => _websiteLinks(note.content))
              .toSet()
              .toList(),
          previews: _websitePreviews,
          onOpenLink: _openNoteLink,
        ),
      );

  void _toggleNoteFormat(_NoteFormat format) {
    if (_selectedNote == null) return;
    final updated =
        _noteController.formatting.toggle(_noteController.selection, format);
    _noteController.value = updated;
    _updateNoteContent(updated.text);
  }

  Widget _noteSelectionFormatButton(
    EditableTextState editableTextState,
    _NoteFormat format,
    String label,
    TextStyle labelStyle,
  ) {
    return TextButton(
      key: ValueKey('note-selection-format-${format.name}'),
      onPressed: () {
        editableTextState.hideToolbar(false);
        _toggleNoteFormat(format);
      },
      style: TextButton.styleFrom(
        minimumSize: const Size(40, 44),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: const RoundedRectangleBorder(),
        side: BorderSide.none,
      ),
      child: Text(label, style: labelStyle),
    );
  }

  Widget _buildNoteSelectionToolbar(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    final allowedKinds = <ContextMenuButtonKind>{
      ContextMenuButtonKind.cut,
      ContextMenuButtonKind.copy,
      ContextMenuButtonKind.paste,
    };
    final editItems = editableTextState.contextMenuButtonItems
        .where((item) => allowedKinds.contains(item.kind))
        .toList();
    final buttons = AdaptiveTextSelectionToolbar.getAdaptiveButtons(
      context,
      editItems,
    ).toList();
    buttons.addAll([
      _noteSelectionFormatButton(
        editableTextState,
        _NoteFormat.bold,
        'B',
        const TextStyle(fontWeight: FontWeight.w800),
      ),
      _noteSelectionFormatButton(
        editableTextState,
        _NoteFormat.italic,
        'i',
        const TextStyle(fontStyle: FontStyle.italic),
      ),
      _noteSelectionFormatButton(
        editableTextState,
        _NoteFormat.underline,
        'U',
        const TextStyle(decoration: TextDecoration.underline),
      ),
    ]);
    final anchors = editableTextState.contextMenuAnchors;
    return TextSelectionToolbar(
      key: const ValueKey('note-selection-toolbar'),
      anchorAbove: anchors.primaryAnchor,
      anchorBelow: anchors.secondaryAnchor ?? anchors.primaryAnchor,
      toolbarBuilder: (context, child) => Material(
        key: const ValueKey('note-selection-toolbar-surface'),
        color: Theme.of(context).colorScheme.surface,
        elevation: 4,
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        child: child,
      ),
      children: buttons,
    );
  }

  Widget _noteFormatButton({
    required _NoteFormat format,
    required IconData icon,
    required String tooltip,
  }) {
    final active = (_activeNoteFormats & format.bit) != 0;
    final palette = _metalPalette;
    final accent = Theme.of(context).custom(
          active ? _ThemeColour.checklistAccent : _ThemeColour.notesAccent,
        ) ??
        _modernPalette?.accent(!active);
    return IconButton(
      key: ValueKey('note-format-${format.name}'),
      tooltip: localizeText(context, tooltip),
      onPressed: () => _toggleNoteFormat(format),
      style: IconButton.styleFrom(
        foregroundColor: accent ??
            (active
                ? (palette?.checklistAccent ?? _brandYellow)
                : (palette?.notesAccent ?? _defaultNoteBlue)),
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(),
      ),
      icon: Icon(icon),
    );
  }

  void _trackNoteLinkPress(PointerDownEvent event) {
    _pressedNoteLink = null;
    if (_noteFocusNode.hasFocus || event.buttons != kPrimaryButton) return;

    final editable = _noteFocusNode.context
        ?.findAncestorStateOfType<EditableTextState>()
        ?.renderEditable;
    if (editable == null) return;
    final point = editable.globalToLocal(event.position);
    final offset = editable.getPositionForPoint(event.position).offset;
    for (final link in _noteController.links) {
      if (offset < link.start || offset > link.end) continue;
      final boxes = editable.getBoxesForSelection(
        TextSelection(baseOffset: link.start, extentOffset: link.end),
      );
      if (boxes.any((box) => box.toRect().contains(point))) {
        _pressedNoteLink = link;
        return;
      }
    }
  }

  Future<void> _openPressedNoteLink() async {
    final link = _pressedNoteLink;
    _pressedNoteLink = null;
    if (link == null || _noteLinkBusy) return;
    final noteId = _selectedNoteId;
    _noteFocusNode.unfocus();
    _noteLinkBusy = true;
    _noteController.highlightLink(link);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _noteLinkBusy = false;
    _noteController.highlightLink(null);
    if (!_showNotes || _selectedNoteId != noteId) return;
    await _openNoteLink(link.uri);
  }

  Future<void> _openNoteLink(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } on PlatformException catch (error) {
      debugPrint('Could not open note link: ${error.code}');
    } on MissingPluginException {
      // Link launching is unavailable on this platform.
    }
    if (mounted) _showMessage('Could not open that link.');
  }

  Future<void> _importNoteText(OcrImageSource source) async {
    final noteId = _selectedNoteId;
    if (_ocrBusy || noteId == null) return;
    String? photoPath;
    try {
      if (source == OcrImageSource.camera) {
        photoPath = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _PhotoCameraDialog(
            ocrService: _ocrService,
            onOpenLink: _openNoteLink,
          ),
        );
        if (photoPath == null || !mounted || _selectedNoteId != noteId) return;
      }
      setState(() => _ocrBusy = true);
      final recognised = photoPath == null
          ? await _ocrService.recognisePicture()
          : await _ocrService.recognisePhoto(photoPath);
      if (!mounted || _selectedNoteId != noteId || recognised == null) return;
      if (recognised.noteText.isEmpty) {
        _showMessage('No text was found in that image.');
        return;
      }
      _insertRecognisedText(recognised);
      _showMessage('Text added to your note.');
    } on PlatformException catch (error) {
      if (mounted) {
        _showMessage(error.message ?? 'Could not recognise that image.');
      }
    } on MissingPluginException {
      if (mounted) _showMessage('Photo text is available on Android.');
    } catch (error) {
      if (mounted) _showMessage('Could not recognise that image: $error');
    } finally {
      if (photoPath != null) await _deleteCameraPhoto(photoPath);
      if (mounted && _ocrBusy) setState(() => _ocrBusy = false);
    }
  }

  void _insertRecognisedText(CameraText recognised) {
    final current = _noteController.text;
    final selection = _noteController.selection;
    final start = selection.start >= 0 ? selection.start : current.length;
    final end = selection.end >= 0 ? selection.end : start;
    final prefix = current.substring(0, start);
    final suffix = current.substring(end);
    final leadingBreak =
        prefix.isNotEmpty && !prefix.endsWith('\n') ? '\n' : '';
    final trailingBreak =
        suffix.isNotEmpty && !suffix.startsWith('\n') ? '\n' : '';
    final text = recognised.noteText;
    final formatting = _noteController.formatting;
    var currentStyle = formatting.rawStyles[start];
    final styledText = StringBuffer();
    for (var index = 0; index < text.length; index++) {
      final style = recognised.styleAt(index);
      _writeNoteStyleChanges(styledText, currentStyle, style);
      styledText.writeCharCode(text.codeUnitAt(index));
      currentStyle = style;
    }
    _writeNoteStyleChanges(styledText, currentStyle, formatting.rawStyles[end]);
    final insertion = '$leadingBreak$styledText';
    final updated = '$prefix$insertion$trailingBreak$suffix';
    _noteController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(
        offset: prefix.length + insertion.length,
      ),
    );
    _updateNoteContent(updated);
  }

  Future<void> _renameNote(NoteEntry note) async {
    final details = await showDialog<_NoteDialogResult>(
      context: context,
      builder: (context) => _NoteDetailsDialog(
        title: 'rename note',
        initialText: note.name,
        categories: _noteCategories,
        initialCategoryId: note.categoryId,
        usePaleBackground: true,
      ),
    );
    if (details == null || !mounted) return;
    setState(() {
      note.name = details.name;
      note.categoryId = details.categoryId;
    });
    await _persistNotes();
  }

  Future<void> _deleteNote(NoteEntry note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _popupAlert(
        context,
        title: const AppText('delete note?'),
        content: AppText('“{name}” will be removed.',
            arguments: {'name': note.name}),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const AppText('cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const AppText('delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _sidebarExitingIds.add(note.id));
    await Future<void>.delayed(_sidebarEntryFadeDuration);
    if (!mounted) return;

    setState(() {
      _sidebarExitingIds.remove(note.id);
      _notes.removeWhere((item) => item.id == note.id);
      for (final project in _projects) {
        for (final task in project.tasks) {
          if (task.linkedNoteId == note.id) task.linkedNoteId = null;
        }
      }
      if (_selectedNoteId == note.id) {
        _selectedNoteId = _notes.isEmpty ? null : _notes.first.id;
        _noteController.text = _selectedNote?.content ?? '';
      }
    });
    await Future.wait([
      _persistNotes(),
      _persist(),
      _rememberSelectedNote(_selectedNoteId),
    ]);
  }

  Future<void> _chooseNoteCategory(NoteEntry note) async {
    final choice = await showDialog<String?>(
      context: context,
      builder: (context) => _NoteCategoryPickerDialog(
        categories: _noteCategories,
        onDelete: _removeNoteCategory,
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == '__new__') {
      final category = await showDialog<NoteCategory>(
        context: context,
        builder: (context) => const _NewNoteCategoryDialog(),
      );
      if (category == null || !mounted) return;
      setState(() {
        _noteCategories.add(category);
        note.categoryId = category.id;
      });
      await Future.wait([_persistNoteCategories(), _persistNotes()]);
      return;
    }

    setState(() => note.categoryId = choice.isEmpty ? null : choice);
    await _persistNotes();
  }

  Future<void> _removeNoteCategory(NoteCategory category) async {
    setState(() {
      _noteCategories.removeWhere((item) => item.id == category.id);
      for (final note in _notes) {
        if (note.categoryId == category.id) note.categoryId = null;
      }
    });
    await Future.wait([_persistNoteCategories(), _persistNotes()]);
  }

  Future<void> _openCategorySettings() async {
    final categoryId = await showDialog<String>(
      context: context,
      builder: (context) =>
          _CategorySettingsDialog(categories: _noteCategories),
    );
    if (categoryId == null || !mounted) return;
    NoteCategory? category;
    for (final item in _noteCategories) {
      if (item.id == categoryId) {
        category = item;
        break;
      }
    }
    if (category == null) return;

    final updated = await showDialog<NoteCategory>(
      context: context,
      builder: (context) => _NewNoteCategoryDialog(category: category),
    );
    if (updated == null || !mounted) return;
    final index = _noteCategories.indexWhere((item) => item.id == updated.id);
    if (index < 0) return;
    setState(() => _noteCategories[index] = updated);
    await _persistNoteCategories();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: AppText(message)));
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  List<ChecklistProject> get _sortedProjects {
    final projects = [..._projects];
    switch (_sort) {
      case ProjectSort.newest:
        projects.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ProjectSort.oldest:
        projects.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case ProjectSort.alphabetical:
        projects.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case ProjectSort.priority:
        projects.sort(
          (a, b) => b.importance.index.compareTo(a.importance.index),
        );
        break;
    }
    return projects;
  }

  List<NoteEntry> get _sortedNotes {
    final notes = [..._notes];
    switch (_noteSort) {
      case NoteSort.newest:
        notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case NoteSort.oldest:
        notes.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case NoteSort.alphabetical:
        notes.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case NoteSort.category:
        notes.sort((a, b) {
          final aName = _categoryFor(a)?.name.toLowerCase() ?? '\uffff';
          final bName = _categoryFor(b)?.name.toLowerCase() ?? '\uffff';
          final categoryResult = aName.compareTo(bName);
          return categoryResult == 0
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : categoryResult;
        });
        break;
    }
    return notes;
  }

  Future<void> _createProject() async {
    final project = await showDialog<ChecklistProject>(
      context: context,
      builder: (context) => const _NewProjectDialog(),
    );
    if (project == null || !mounted) return;
    setState(() {
      _projects.add(project);
      _selectedId = project.id;
    });
    await Future.wait([_persist(), _rememberSelectedProject(project.id)]);
    if (mounted) _taskFocusNode.requestFocus();
  }

  void _addTask() {
    final project = _selected;
    final text = _taskController.text.trim();
    if (project == null || text.isEmpty) return;

    setState(() {
      project.tasks.add(ChecklistTask(id: _newId(), text: text));
      _taskController.clear();
    });
    _persist();
    _taskFocusNode.requestFocus();
  }

  KeyEventResult _handleTaskKey(FocusNode node, KeyEvent event) {
    final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (event is! KeyDownEvent || !isEnter) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      final selection = _taskController.selection;
      final start =
          selection.start < 0 ? _taskController.text.length : selection.start;
      final end = selection.end < 0 ? start : selection.end;
      final updatedText = _taskController.text.replaceRange(start, end, '\n');
      _taskController.value = TextEditingValue(
        text: updatedText,
        selection: TextSelection.collapsed(offset: start + 1),
      );
      return KeyEventResult.handled;
    } else {
      _addTask();
      return KeyEventResult.handled;
    }
  }

  Future<void> _toggleTask(ChecklistTask task) async {
    setState(() => task.isDone = !task.isDone);
    await _persist();
  }

  Future<void> _deleteTask(ChecklistTask task) async {
    final project = _selected;
    if (project == null) return;
    setState(() => project.tasks.removeWhere((item) => item.id == task.id));
    await _persist();
  }

  Future<void> _reorderTask(int oldIndex, int newIndex) async {
    final project = _selected;
    if (project == null || oldIndex == newIndex) return;
    setState(() {
      final task = project.tasks.removeAt(oldIndex);
      project.tasks.insert(newIndex, task);
    });
    await _persist();
  }

  Future<void> _editTask(ChecklistTask task) async {
    final text = await showDialog<String>(
      context: context,
      builder: (context) => _TextEntryDialog(
        title: 'Edit task',
        initialText: task.text,
        hintText: 'Task details',
        minLines: 2,
        maxLines: 7,
      ),
    );
    if (text == null || text.isEmpty || !mounted) return;
    setState(() => task.text = text);
    await _persist();
  }

  NoteEntry? _linkedNoteFor(ChecklistTask task) {
    for (final note in _notes) {
      if (note.id == task.linkedNoteId) return note;
    }
    return null;
  }

  Future<void> _linkNoteToTask(ChecklistTask task) async {
    final noteId = await showDialog<String>(
      context: context,
      builder: (context) => _TaskNotePickerDialog(
        notes: _sortedNotes,
        selectedNoteId: task.linkedNoteId,
      ),
    );
    if (noteId == null || !mounted) return;
    setState(() => task.linkedNoteId = noteId);
    await _persist();
  }

  Future<void> _showTaskNote(NoteEntry note) => showDialog<void>(
        context: context,
        builder: (context) => _TaskLinkedNoteDialog(
          note: note,
          onOpenLink: _openNoteLink,
          frameColour: Theme.of(context).custom(_ThemeColour.borders) ??
              switch (widget.appTheme) {
                AppTheme.boi => _defaultNoteBlue,
                AppTheme.pencil => _lightLine,
                AppTheme.pastel => _pastelYellow,
                AppTheme.copper => _copperPalette.checklistAccent,
                AppTheme.blackMetal => _blackMetalPalette.checklistAccent,
                AppTheme.pixel => _pixelPalette.border,
                AppTheme.glass => _glassPalette.border,
              },
        ),
      );

  Future<void> _renameProject(ChecklistProject project) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _TextEntryDialog(
        title: 'Rename checklist',
        initialText: project.name,
        hintText: 'Checklist name',
        maxLength: 48,
        submitOnEnter: true,
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    setState(() => project.name = name);
    await _persist();
  }

  Future<void> _editProjectReminder(ChecklistProject project) async {
    final result = await showDialog<_ChecklistReminderResult>(
      context: context,
      builder: (context) => _ChecklistReminderDialog(
        checklistName: project.name,
        initialReminder: project.reminderAt,
      ),
    );
    if (result == null || !mounted) return;
    setState(() => project.reminderAt = result.reminderAt);
    await _persist();
  }

  Future<void> _deleteProject(ChecklistProject project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _popupAlert(
        context,
        title: const AppText('Delete checklist?'),
        content: AppText('“{name}” and its tasks will be removed.',
            arguments: {'name': project.name}),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const AppText('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const AppText('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final wasSelected = _selectedId == project.id;
    final coverPath = project.coverImagePath;
    setState(() => _sidebarExitingIds.add(project.id));
    await Future<void>.delayed(_sidebarEntryFadeDuration);
    if (!mounted) return;
    setState(() {
      _sidebarExitingIds.remove(project.id);
      _projects.removeWhere((item) => item.id == project.id);
      if (_projects.isEmpty) {
        _projects.add(
          ChecklistProject(
            id: _newId(),
            name: 'my first checklist',
            createdAt: DateTime.now(),
          ),
        );
        _selectedId = _projects.first.id;
      } else if (wasSelected) {
        _selectedId = _projects.first.id;
      }
      if (wasSelected) _taskController.clear();
    });
    final saved = await _persist();
    if (saved) {
      try {
        await _store.deleteCover(coverPath);
      } catch (error) {
        if (mounted) _showMessage('Could not clean up the cover image: $error');
      }
    }
    if (_selectedId != null) {
      await _rememberSelectedProject(_selectedId!);
    }
  }

  Future<void> _setImportance(
    ChecklistProject project,
    ProjectImportance importance,
  ) async {
    setState(() => project.importance = importance);
    await _persist();
  }

  Future<void> _browseForCover(ChecklistProject project) async {
    try {
      final sourcePath = await _store.pickCoverSource();
      if (sourcePath == null || !mounted) return;
      final croppedBytes = await showDialog<Uint8List>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _CoverCropDialog(sourcePath: sourcePath),
      );
      if (croppedBytes == null || !mounted) return;
      final path = await _store.saveCoverBytes(croppedBytes);
      await _replaceCover(project, path);
    } catch (error) {
      if (mounted) _showMessage('Could not add that image: $error');
    }
  }

  Future<void> _takeCoverPhoto(ChecklistProject project) async {
    String? sourcePath;
    try {
      sourcePath = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            _PhotoCameraDialog(ocrService: _ocrService, forCover: true),
      );
      if (sourcePath == null || !mounted) return;
      final path = await _store.cropAndSaveCameraCover(
        sourcePath,
        aspectRatio: _coverAspectRatio,
      );
      if (!mounted) {
        await _store.deleteCover(path);
        return;
      }
      await _replaceCover(project, path);
    } catch (error) {
      if (mounted) _showMessage('Could not take that photo: $error');
    } finally {
      if (sourcePath != null) await _deleteCameraPhoto(sourcePath);
    }
  }

  Future<void> _replaceCover(ChecklistProject project, String path) async {
    if (!mounted) return;
    final previousPath = project.coverImagePath;
    setState(() => project.coverImagePath = path);
    final saved = await _persist();
    if (saved) {
      try {
        await _store.deleteCover(previousPath);
      } catch (_) {
        if (mounted) {
          _showMessage(
            'Cover updated, but the old image could not be removed.',
          );
        }
      }
    } else {
      if (mounted) setState(() => project.coverImagePath = previousPath);
      await _store.deleteCover(path);
    }
  }

  Future<void> _removeCover(ChecklistProject project) async {
    final path = project.coverImagePath;
    setState(() => project.coverImagePath = null);
    final saved = await _persist();
    if (saved) {
      try {
        await _store.deleteCover(path);
      } catch (error) {
        if (mounted) _showMessage('Could not clean up the cover image: $error');
      }
    } else if (mounted) {
      setState(() => project.coverImagePath = path);
    }
  }

  void _selectProject(ChecklistProject project) {
    if (_selectedId != project.id) _revealContent(_projectReveal);
    _taskController.clear();
    setState(() {
      _selectedId = project.id;
      _showNotes = false;
    });
    widget.onNotesModeChanged(false);
    _rememberSelectedProject(project.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 36),
                const SizedBox(height: 12),
                const AppText('Your checklists could not be loaded.'),
                const SizedBox(height: 8),
                AppText(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _load,
                  child: const AppText('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final palette = _metalPalette;
    final wide = MediaQuery.sizeOf(context).width >= 820;
    final sidebar = _buildSidebar(mobile: !wide);
    final mobileSidebar = Platform.isAndroid
        ? Stack(
            fit: StackFit.expand,
            children: [
              sidebar,
              Positioned.fill(
                child: IgnorePointer(
                  child: SafeArea(
                    top: false,
                    left: false,
                    right: false,
                    child: _HeartBubbleLayer(
                      enabled: _heartAnimationEnabled,
                      drawerOpen: _mobileDrawerActive,
                      restartSignal: _heartRestartSignal,
                    ),
                  ),
                ),
              ),
            ],
          )
        : sidebar;
    final workspace = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _showNotes
          ? KeyedSubtree(
              key: const ValueKey('notes'),
              child: _buildNotes(wide: wide),
            )
          : KeyedSubtree(
              key: const ValueKey('checklist'),
              child: _selected == null
                  ? const Center(
                      child: AppText('choose a checklist'),
                    )
                  : _buildMain(_selected!, wide: wide),
            ),
    );
    final systemIconBrightness =
        widget.isDark ? Brightness.light : Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      key: const ValueKey('edge-to-edge-system-ui'),
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: systemIconBrightness,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: systemIconBrightness,
        systemNavigationBarContrastEnforced: false,
      ),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          drawer: wide ? null : Drawer(width: 292, child: mobileSidebar),
          drawerEnableOpenDragGesture: !wide,
          drawerEdgeDragWidth: 40,
          onDrawerChanged: wide
              ? null
              : (isOpen) {
                  if (_mobileDrawerActive != isOpen) {
                    setState(() => _mobileDrawerActive = isOpen);
                  }
                },
          body: SafeArea(
            top: !_showNotes,
            child: Row(
              children: [
                if (wide)
                  SafeArea(
                    top: _showNotes,
                    bottom: false,
                    left: false,
                    right: false,
                    child: SizedBox(width: 282, child: sidebar),
                  ),
                Expanded(
                  child: AnimatedContainer(
                    key: const ValueKey('workspace-surface'),
                    duration: const Duration(milliseconds: 280),
                    decoration: palette != null
                        ? _metalBackdrop(
                            palette,
                            notesActive: _showNotes,
                            background: Theme.of(context)
                                .custom(_ThemeColour.background),
                            sidebar:
                                Theme.of(context).custom(_ThemeColour.sidebar),
                          )
                        : const BoxDecoration(),
                    child: _AppearanceBackdrop(
                      matte: _showNotes,
                      child: _ThemeBuildReveal(
                        progress: _themeBuild,
                        child: SafeArea(
                          key: const ValueKey('main-content-safe-area'),
                          top: _showNotes,
                          bottom: false,
                          left: false,
                          right: false,
                          child: _BlackMetalPanel(
                            enabled: _blackMetal,
                            initialDelay: const Duration(milliseconds: 2300),
                            child: workspace,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportBackup() async {
    if (_backupBusy) return;
    setState(() => _backupBusy = true);
    try {
      _noteSaveTimer?.cancel();
      await Future.wait([
        _store.saveProjects(_projects),
        _store.saveNotes(_notes),
        _store.saveNoteCategories(_noteCategories),
      ]);
      final bytes = await _store.createBackupBytes();
      if (!mounted) return;
      final now = DateTime.now();
      final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      final destination = await FilePicker.saveFile(
        fileName: 'checklist-backup-$date.json',
        bytes: bytes,
        mimeType: 'application/json',
        dialogTitle: localizeText(context, 'export data'),
      );
      if (destination != null && mounted) {
        _showMessage('Backup exported successfully.');
      }
    } catch (error) {
      if (mounted) _showMessage('Could not export your data: $error');
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _importBackup() async {
    if (_backupBusy) return;
    setState(() => _backupBusy = true);
    try {
      final selected = await FilePicker.pickFile(
        dialogTitle: localizeText(context, 'import data'),
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (selected == null) return;
      final bytes = await selected.readAsBytes();
      final backup = _store.decodeBackup(bytes);
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _popupAlert(
          context,
          title: const AppText('import data'),
          content: AppText(
            'Replace this installation with {checklists} checklist(s) and {notes} note(s)?',
            arguments: {
              'checklists': backup.projects.length,
              'notes': backup.notes.length
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const AppText('cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const AppText('import'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await _store.restoreBackup(backup);
      await _load();
      if (mounted) _showMessage('Backup imported successfully.');
    } catch (error) {
      if (mounted) _showMessage('Could not import that backup: $error');
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Widget _settingsOption({
    required String label,
    IconData? icon,
    required VoidCallback onTap,
    Key? key,
    bool selected = false,
    String? trailing,
  }) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.22)
          : Colors.transparent,
      child: _SettingsPress(
        key: key,
        onTap: onTap,
        builder: (pressed) => SizedBox(
          height: 42,
          child: Row(
            children: [
              const SizedBox(width: 8),
              if (icon != null) ...[
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: AppText(
                  label,
                  style: _settingsTextStyle(foreground, pressed).copyWith(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null)
                AppText(
                  trailing,
                  style: _settingsTextStyle(
                          foreground.withValues(alpha: 0.62), pressed)
                      .copyWith(fontSize: 11),
                ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsBack(String title) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return _SettingsPress(
      key: const ValueKey('settings-back'),
      onTap: () => setState(() => _settingsPage = _SettingsPage.main),
      builder: (pressed) => SizedBox(
        height: 36,
        child: Row(
          children: [
            Icon(Icons.arrow_back_rounded, size: 17, color: foreground),
            const SizedBox(width: 8),
            Expanded(
              child: AppText(
                title,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: _settingsTextStyle(foreground, pressed).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeChoice(AppTheme appearance) {
    final (key, label, icon) = switch (appearance) {
      AppTheme.boi => ('boi', 'Boi', Icons.dark_mode_outlined),
      AppTheme.pencil => ('pencil', 'Pencil', Icons.edit_outlined),
      AppTheme.pastel => ('pastel', 'Pastel', Icons.color_lens_outlined),
      AppTheme.copper => ('copper', 'Copper', Icons.nights_stay_outlined),
      AppTheme.blackMetal => (
          'black-metal',
          'Black Metal',
          Icons.bolt_outlined
        ),
      AppTheme.pixel => ('pixel', 'Pixel', Icons.videogame_asset_outlined),
      AppTheme.glass => ('glass', 'Glass', Icons.layers_outlined),
    };
    return _settingsOption(
      key: ValueKey('theme-$key'),
      label: label,
      icon: icon,
      selected: appearance == widget.appTheme,
      onTap: () {
        if (appearance == widget.appTheme) return;
        widget.onThemeChanged(appearance);
        _revealContent(_themeBuild);
      },
    );
  }

  Future<void> _customiseTheme() async {
    final appearance = widget.appTheme;
    final defaults = _themeColourDefaults(appearance, _showNotes);
    final values = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => _ThemeColourDialog(
        defaults: defaults,
        colours: widget.themeColours,
      ),
    );
    if (mounted && values != null) {
      widget.onThemeColoursChanged(appearance, values);
    }
  }

  Widget _settingsContent() {
    switch (_settingsPage) {
      case _SettingsPage.main:
        return Column(
          key: const ValueKey('settings-main'),
          children: [
            _settingsOption(
              key: const ValueKey('settings-themes'),
              label: 'themes',
              icon: Icons.palette_outlined,
              onTap: () => setState(() => _settingsPage = _SettingsPage.themes),
            ),
            _settingsOption(
              key: const ValueKey('settings-language'),
              label: 'language',
              icon: Icons.translate_rounded,
              onTap: () =>
                  setState(() => _settingsPage = _SettingsPage.language),
            ),
            _settingsOption(
              key: const ValueKey('settings-backup'),
              label: 'import / export',
              icon: Icons.import_export_rounded,
              onTap: () => setState(() => _settingsPage = _SettingsPage.backup),
            ),
            _settingsOption(
              key: const ValueKey('settings-about'),
              label: 'about',
              icon: Icons.info_outline_rounded,
              onTap: () => setState(() => _settingsPage = _SettingsPage.about),
            ),
          ],
        );
      case _SettingsPage.themes:
        return ConstrainedBox(
          key: const ValueKey('settings-theme-choices'),
          constraints: BoxConstraints(
            maxHeight: math.max(100, MediaQuery.sizeOf(context).height - 255),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _settingsBack('themes'),
                for (final appearance in AppTheme.values) ...[
                  _themeChoice(appearance),
                  if (appearance == widget.appTheme)
                    Padding(
                      padding: const EdgeInsets.only(left: 22),
                      child: _settingsOption(
                        key: const ValueKey('theme-customise'),
                        label: 'customise',
                        icon: Icons.tune_rounded,
                        onTap: _customiseTheme,
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      case _SettingsPage.language:
        return Column(
          key: const ValueKey('settings-language-page'),
          children: [
            _settingsBack('language'),
            for (final language in AppLanguage.values)
              _settingsOption(
                key: ValueKey('language-${language.name}'),
                label: language.label,
                selected: widget.appLanguage == language,
                trailing: widget.appLanguage == language ? 'current' : null,
                onTap: () => widget.onLanguageChanged(language),
              ),
          ],
        );
      case _SettingsPage.backup:
        return Column(
          key: const ValueKey('settings-backup-page'),
          children: [
            _settingsBack('import / export'),
            _settingsOption(
              key: const ValueKey('settings-export'),
              label: 'export data',
              icon: Icons.file_upload_outlined,
              onTap: _backupBusy ? () {} : _exportBackup,
            ),
            _settingsOption(
              key: const ValueKey('settings-import'),
              label: 'import data',
              icon: Icons.file_download_outlined,
              onTap: _backupBusy ? () {} : _importBackup,
            ),
          ],
        );
      case _SettingsPage.about:
        return Padding(
          key: const ValueKey('settings-about-page'),
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _settingsBack('about'),
              const AppText(
                'CHECKLIST {version} · build {build}',
                arguments: {
                  'version': checklistVersion,
                  'build': checklistBuildNumber
                },
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const AppText(
                'Ákos Nemes · Codex AI',
                style: TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 6),
              const AppText(
                'akosnemes@proton.me',
                style: TextStyle(fontSize: 11),
              ),
            ],
          ),
        );
    }
  }

  Widget _websiteGalleryButton(Color foreground) => IconButton(
        key: const ValueKey('note-website-gallery'),
        tooltip: localizeText(context, 'website links'),
        style: IconButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide.none,
        ),
        icon: const Icon(Icons.language_rounded, size: 18),
        onPressed: _openWebsiteGallery,
      );

  Widget _buildSettingsPanel(Color foreground) {
    const settingsFontSize = 13.0;
    final compactDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    return Column(
      key: const ValueKey('settings-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const ValueKey('settings-expanding-line'),
          width: double.infinity,
          height: 2,
          color: foreground.withValues(alpha: 0.45),
        ),
        AnimatedContainer(
          duration: compactDuration,
          height: _settingsOpen ? 46 : 50,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _SettingsPress(
                  key: const ValueKey('settings-toggle'),
                  onTap: () => setState(() {
                    _settingsOpen = !_settingsOpen;
                    if (!_settingsOpen) _settingsPage = _SettingsPage.main;
                  }),
                  builder: (pressed) => Row(
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        size: 20,
                        color: foreground,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: AppText(
                          'settings',
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: _settingsTextStyle(foreground, pressed)
                              .copyWith(fontSize: settingsFontSize),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  key: const ValueKey('heart-animation-trigger'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _handleHeartSecretTap,
                  onLongPress: _restartHeartAnimation,
                  child: const SizedBox.expand(),
                ),
              ),
              if (_showNotes && _settingsOpen)
                _websiteGalleryButton(foreground),
              IconButton(
                key: const ValueKey('settings-chevron'),
                tooltip: localizeText(
                  context,
                  _settingsOpen ? 'close settings' : 'open settings',
                ),
                onPressed: () => setState(() {
                  _settingsOpen = !_settingsOpen;
                  if (!_settingsOpen) _settingsPage = _SettingsPage.main;
                }),
                style: IconButton.styleFrom(side: BorderSide.none),
                icon: AnimatedRotation(
                  turns: _settingsOpen ? 0 : 0.5,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
              ),
            ],
          ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween(end: _settingsOpen ? 0 : 1),
          duration: compactDuration,
          curve: Curves.easeInOut,
          builder: (context, fraction, child) => ClipRect(
            child: Align(
              key: const ValueKey('settings-version-space'),
              alignment: Alignment.topLeft,
              heightFactor: fraction,
              child: IgnorePointer(
                ignoring: _settingsOpen,
                child: Opacity(
                  key: const ValueKey('settings-version-fade'),
                  opacity: fraction,
                  child: child,
                ),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 27, bottom: 4),
            child: Row(
              children: [
                Text(
                  checklistVersion,
                  key: const ValueKey('settings-version'),
                  style: _settingsTextStyle(foreground, false)
                      .copyWith(fontSize: settingsFontSize / 2),
                ),
                if (_showNotes && !_settingsOpen)
                  _websiteGalleryButton(foreground),
                if (_showNotes && _settingsOpen) const SizedBox(height: 48),
              ],
            ),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _settingsOpen
                ? AnimatedSwitcher(
                    duration: const Duration(milliseconds: 360),
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        alignment: Alignment.topCenter,
                        child: child,
                      ),
                    ),
                    child: _settingsContent(),
                  )
                : const SizedBox.shrink(key: ValueKey('settings-closed')),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar({required bool mobile}) {
    final theme = Theme.of(context);
    final palette = _metalPalette;
    final projects = _sortedProjects;
    final notes = _sortedNotes;
    final modern = _modernPalette;
    final sidebarDefault = _sidebarColour(widget.appTheme, _showNotes);
    final sidebarColor = theme
            .custom(_ThemeColour.sidebar)
            ?.withValues(alpha: sidebarDefault.a) ??
        sidebarDefault;
    final sidebarForeground = theme.custom(_ThemeColour.text) ??
        palette?.ink ??
        modern?.ink ??
        (widget.isDark ? _borderWhite : _lightText);
    final buttonOverride = theme.custom(_ThemeColour.buttons);
    final buttonColour = buttonOverride ??
        (modern == null
            ? null
            : theme.custom(_showNotes
                ? _ThemeColour.notesAccent
                : _ThemeColour.checklistAccent)) ??
        _createButtonColour(widget.appTheme, _showNotes);
    final controlFrame =
        theme.custom(_ThemeColour.borders) ?? sidebarForeground;
    final wordmark = _BrandWordmark(
      notesActive: _showNotes,
      onChecklistPressed: _openChecklist,
      onNotesPressed: _openNotes,
    );
    final sortButton = PopupMenuButton<ProjectSort>(
      tooltip: localizeText(context, 'sort checklists'),
      initialValue: _sort,
      onSelected: _changeSort,
      icon: const Icon(Icons.sort_rounded),
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: ProjectSort.newest,
          checked: _sort == ProjectSort.newest,
          child: const AppText('date · newest'),
        ),
        CheckedPopupMenuItem(
          value: ProjectSort.oldest,
          checked: _sort == ProjectSort.oldest,
          child: const AppText('date · oldest'),
        ),
        CheckedPopupMenuItem(
          value: ProjectSort.alphabetical,
          checked: _sort == ProjectSort.alphabetical,
          child: const AppText('a–z'),
        ),
        CheckedPopupMenuItem(
          value: ProjectSort.priority,
          checked: _sort == ProjectSort.priority,
          child: const AppText('priority · high first'),
        ),
      ],
    );
    final noteSortButton = PopupMenuButton<NoteSort>(
      tooltip: localizeText(context, 'sort notes'),
      initialValue: _noteSort,
      onSelected: _changeNoteSort,
      icon: const Icon(Icons.sort_rounded),
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: NoteSort.newest,
          checked: _noteSort == NoteSort.newest,
          child: const AppText('date · newest'),
        ),
        CheckedPopupMenuItem(
          value: NoteSort.oldest,
          checked: _noteSort == NoteSort.oldest,
          child: const AppText('date · oldest'),
        ),
        CheckedPopupMenuItem(
          value: NoteSort.alphabetical,
          checked: _noteSort == NoteSort.alphabetical,
          child: const AppText('a–z'),
        ),
        CheckedPopupMenuItem(
          value: NoteSort.category,
          checked: _noteSort == NoteSort.category,
          child: const AppText('category · a–z'),
        ),
      ],
    );
    final createButton = FilledButton.icon(
      key: const ValueKey('sidebar-create-button'),
      onPressed: _showNotes ? _createNote : _createProject,
      icon: const Icon(Icons.add_rounded, size: 19),
      label: AppText(_showNotes ? 'new note' : 'new checklist'),
      style: FilledButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: buttonColour,
        foregroundColor: buttonOverride != null
            ? _contrastingInk(buttonColour)
            : modern?.buttonInk ?? sidebarForeground,
        side: BorderSide(color: controlFrame, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
    final sidebar = Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        key: const ValueKey('sidebar-surface'),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: sidebarColor,
          border: Border(
            right: BorderSide(
              color: theme.custom(_ThemeColour.borders) ??
                  palette?.line ??
                  modern?.border ??
                  sidebarForeground,
              width: 2,
            ),
          ),
        ),
        padding: EdgeInsets.fromLTRB(18, mobile ? 55 : 22, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            wordmark,
            SizedBox(height: mobile ? 5 : 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Column(
                  key: ValueKey(_showNotes ? 'notes-sidebar' : 'list-sidebar'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 50,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: createButton),
                          const SizedBox(width: 8),
                          Container(
                            key: const ValueKey('sidebar-filter-frame'),
                            width: 50,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: controlFrame,
                                width: 2,
                              ),
                            ),
                            child: IconButtonTheme(
                              data: const IconButtonThemeData(
                                style: ButtonStyle(
                                  side: WidgetStatePropertyAll(BorderSide.none),
                                ),
                              ),
                              child: IconTheme(
                                data: IconThemeData(color: sidebarForeground),
                                child: _showNotes ? noteSortButton : sortButton,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        AppText(
                          _showNotes ? 'YOUR NOTES' : 'YOUR CHECKLISTS',
                          key: const ValueKey('sidebar-section-title'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.1,
                            color: sidebarForeground.withValues(alpha: 0.68),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        AppText(
                          '${_showNotes ? notes.length : projects.length}',
                          key: const ValueKey('sidebar-item-count'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: sidebarForeground.withValues(alpha: 0.58),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: _showNotes
                          ? ListView.builder(
                              key: const ValueKey('notes-sidebar-list'),
                              itemCount: notes.length,
                              itemBuilder: (context, index) {
                                final note = notes[index];
                                final category = _categoryFor(note);
                                final noteColor = _noteColour(category);
                                final selected = note.id == _selectedNoteId;
                                return _SidebarFadeItem(
                                  key: ValueKey('sidebar-note-${note.id}'),
                                  visible: !_sidebarExitingIds.contains(
                                    note.id,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Material(
                                      color: selected
                                          ? (widget.isPastel
                                              ? _pastelSelectedNote
                                              : noteColor.withValues(
                                                  alpha: 0.2))
                                          : Colors.transparent,
                                      child: ListTile(
                                        dense: true,
                                        shape: const RoundedRectangleBorder(),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 1,
                                        ),
                                        minLeadingWidth: 10,
                                        horizontalTitleGap: 10,
                                        leading: _NoteColourDot(
                                          color: noteColor,
                                        ),
                                        title: Text(
                                          note.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: noteColor,
                                            fontSize: 13,
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: AppText(
                                          _formatDate(context, note.createdAt),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: sidebarForeground.withValues(
                                                alpha: 0.58),
                                          ),
                                        ),
                                        onTap: () => _selectNote(note),
                                        trailing: PopupMenuButton<String>(
                                          tooltip: localizeText(
                                            context,
                                            'note options',
                                          ),
                                          padding: EdgeInsets.zero,
                                          onSelected: (action) {
                                            if (action == 'rename') {
                                              _renameNote(note);
                                            }
                                            if (action == 'delete') {
                                              _deleteNote(note);
                                            }
                                            if (action == 'categories') {
                                              _openCategorySettings();
                                            }
                                          },
                                          itemBuilder: (context) => const [
                                            PopupMenuItem(
                                              value: 'rename',
                                              child: AppText('rename'),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: AppText('delete'),
                                            ),
                                            PopupMenuItem(
                                              value: 'categories',
                                              child: AppText(
                                                'category settings',
                                              ),
                                            ),
                                          ],
                                          child: SizedBox.square(
                                            key: const ValueKey(
                                              'sidebar-note-settings',
                                            ),
                                            dimension: 36,
                                            child: Icon(
                                              Icons.more_vert_rounded,
                                              size: 18,
                                              color: sidebarForeground
                                                  .withValues(alpha: 0.72),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView.builder(
                              key: const ValueKey('checklists-sidebar-list'),
                              itemCount: projects.length,
                              itemBuilder: (context, index) {
                                final project = projects[index];
                                final selected = project.id == _selectedId;
                                return _SidebarFadeItem(
                                  key: ValueKey(
                                    'sidebar-project-${project.id}',
                                  ),
                                  visible: !_sidebarExitingIds.contains(
                                    project.id,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Material(
                                      color: selected
                                          ? (widget.isDark
                                                  ? (palette?.checklistAccent ??
                                                      _brandPurple)
                                                  : widget.isPastel
                                                      ? _pastelMauve
                                                      : _lightLine)
                                              .withValues(alpha: 0.22)
                                          : Colors.transparent,
                                      child: ListTile(
                                        dense: true,
                                        shape: const RoundedRectangleBorder(),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 1,
                                        ),
                                        minLeadingWidth: 10,
                                        horizontalTitleGap: 10,
                                        leading: _ImportanceBar(
                                          importance: project.importance,
                                          isPastel: widget.isPastel,
                                          isPencil: widget.appTheme ==
                                              AppTheme.pencil,
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                project.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: sidebarForeground,
                                                  fontSize: 13,
                                                  fontWeight: selected
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        subtitle: AppText(
                                          '{date}  ·  {done}/{tasks} done',
                                          arguments: {
                                            'date': _formatDate(
                                                context, project.createdAt),
                                            'done': project.completedTaskCount,
                                            'tasks': project.tasks.length
                                          },
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: sidebarForeground.withValues(
                                                alpha: 0.58),
                                          ),
                                        ),
                                        onTap: () => _selectProject(project),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (project.reminderAt != null) ...[
                                              Tooltip(
                                                message: localizeText(
                                                  context,
                                                  project.reminderAt!.isAfter(
                                                    DateTime.now(),
                                                  )
                                                      ? 'upcoming reminder'
                                                      : 'past reminder',
                                                ),
                                                child: Icon(
                                                  Icons.notifications_rounded,
                                                  key: ValueKey(
                                                    'checklist-reminder-bell-${project.id}',
                                                  ),
                                                  size: 18,
                                                  color: project.reminderAt!
                                                          .isAfter(
                                                    DateTime.now(),
                                                  )
                                                      ? sidebarForeground
                                                      : _switchGrey,
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                            ],
                                            PopupMenuButton<String>(
                                              tooltip: localizeText(
                                                context,
                                                'checklist options',
                                              ),
                                              padding: EdgeInsets.zero,
                                              onSelected: (action) {
                                                if (action == 'rename') {
                                                  _renameProject(project);
                                                }
                                                if (action == 'delete') {
                                                  _deleteProject(project);
                                                }
                                                if (action == 'reminder') {
                                                  _editProjectReminder(project);
                                                }
                                              },
                                              itemBuilder: (context) => const [
                                                PopupMenuItem(
                                                  value: 'reminder',
                                                  child: AppText(
                                                    'reminder',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'rename',
                                                  child: AppText('rename'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  child: AppText('delete'),
                                                ),
                                              ],
                                              child: SizedBox.square(
                                                key: const ValueKey(
                                                  'sidebar-checklist-settings',
                                                ),
                                                dimension: 36,
                                                child: Icon(
                                                  Icons.more_vert_rounded,
                                                  size: 18,
                                                  color: sidebarForeground
                                                      .withValues(alpha: 0.72),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (mobile)
              SafeArea(
                key: const ValueKey('mobile-sidebar-safe-area'),
                top: false,
                left: false,
                right: false,
                child: _buildSettingsPanel(sidebarForeground),
              )
            else
              _buildSettingsPanel(sidebarForeground),
          ],
        ),
      ),
    );
    return _AppearanceBackdrop(
      lens: true,
      child: _ThemeBuildReveal(
        progress: _themeBuild,
        child: _BlackMetalPanel(
          enabled: _blackMetal,
          initialDelay: const Duration(milliseconds: 1350),
          child: sidebar,
        ),
      ),
    );
  }

  Color _noteColour(NoteCategory? category) {
    if (category != null && widget.appTheme != AppTheme.pencil) {
      return Color(category.colorValue);
    }
    return Theme.of(context).custom(_ThemeColour.notesAccent) ??
        (switch (widget.appTheme) {
          AppTheme.pencil => _lightControl,
          AppTheme.boi => _defaultNoteBlue,
          AppTheme.pastel => _pastelMauve,
          AppTheme.copper || AppTheme.blackMetal => _metalPalette!.notesAccent,
          AppTheme.pixel || AppTheme.glass => _modernPalette!.notesAccent,
        });
  }

  Widget _buildNotes({required bool wide}) {
    final theme = Theme.of(context);
    final palette = _metalPalette;
    final modern = _modernPalette;
    final note = _selectedNote;
    final category = note == null ? null : _categoryFor(note);
    final noteColour = _noteColour(category);
    final bodyColour = theme.custom(_ThemeColour.text) ??
        palette?.ink ??
        modern?.ink ??
        (widget.isDark ? _borderWhite : _lightText);
    final border = theme.custom(_ThemeColour.borders);
    final panel = theme.custom(_ThemeColour.panel);

    final editor = note == null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  size: 42,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 10),
                AppText(
                  'create a note from the sidebar',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          )
        : Padding(
            key: const ValueKey('note-editor'),
            padding: EdgeInsets.fromLTRB(
              wide ? 52 : 24,
              28,
              wide ? 52 : 24,
              30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _contentFade(
                          _noteReveal,
                          0,
                          0.32,
                          Text(
                            note.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: noteColour,
                              fontWeight: FontWeight.w700,
                            ),
                          )),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: localizeText(context, 'change category'),
                      onPressed: () => _chooseNoteCategory(note),
                      icon: Icon(
                        Icons.label_outline_rounded,
                        color: noteColour,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (theme.platform == TargetPlatform.android) ...[
                      if (_ocrBusy)
                        Container(
                          key: const ValueKey('note-ocr-button'),
                          width: 40,
                          height: 40,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: _borderWhite, width: 2),
                          ),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette?.notesAccent ?? _defaultNoteBlue,
                          ),
                        )
                      else
                        PopupMenuButton<OcrImageSource>(
                          tooltip: localizeText(
                            context,
                            'add text from a picture',
                          ),
                          padding: EdgeInsets.zero,
                          onSelected: _importNoteText,
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: OcrImageSource.picture,
                              child: AppText('add picture'),
                            ),
                            PopupMenuItem(
                              value: OcrImageSource.camera,
                              child: AppText('take a photo'),
                            ),
                          ],
                          child: Container(
                            key: const ValueKey('note-ocr-button'),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: _borderWhite, width: 2),
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              color: palette?.notesAccent ?? _defaultNoteBlue,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                    ],
                    PopupMenuButton<String>(
                      tooltip: localizeText(context, 'note options'),
                      padding: EdgeInsets.zero,
                      onSelected: (action) {
                        if (action == 'rename') _renameNote(note);
                        if (action == 'delete') _deleteNote(note);
                        if (action == 'categories') _openCategorySettings();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'rename',
                          child: AppText('rename'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: AppText('delete'),
                        ),
                        PopupMenuItem(
                          value: 'categories',
                          child: AppText('category settings'),
                        ),
                      ],
                      child: const SizedBox.square(
                        key: ValueKey('note-header-settings'),
                        dimension: 40,
                        child: Icon(Icons.more_vert_rounded, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                AppText(
                  _formatDate(context, note.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: category == null
                          ? const SizedBox.shrink()
                          : _contentFade(
                              _noteReveal,
                              0.12,
                              0.46,
                              Text(
                                category.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge
                                    ?.copyWith(color: noteColour),
                              ),
                            ),
                    ),
                    TextFieldTapRegion(
                      key: const ValueKey('note-format-tap-region'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        key: const ValueKey('note-format-toolbar'),
                        children: [
                          _noteFormatButton(
                              format: _NoteFormat.bold,
                              icon: Icons.format_bold_rounded,
                              tooltip: 'bold'),
                          _noteFormatButton(
                              format: _NoteFormat.italic,
                              icon: Icons.format_italic_rounded,
                              tooltip: 'italic'),
                          _noteFormatButton(
                              format: _NoteFormat.underline,
                              icon: Icons.format_underlined_rounded,
                              tooltip: 'underline'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: _NoteBodyReveal(
                    progress: CurveTween(curve: const Interval(0.22, 1))
                        .animate(_noteReveal),
                    child: Listener(
                      onPointerDown: _trackNoteLinkPress,
                      onPointerCancel: (_) => _pressedNoteLink = null,
                      child: TextField(
                        key: const ValueKey('note-content-field'),
                        controller: _noteController,
                        focusNode: _noteFocusNode,
                        expands: true,
                        minLines: null,
                        maxLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        cursorColor: bodyColour,
                        style: TextStyle(
                          color: bodyColour,
                          height: 1.5,
                        ),
                        contextMenuBuilder: _buildNoteSelectionToolbar,
                        onTap: _openPressedNoteLink,
                        onTapOutside: (_) => _noteFocusNode.unfocus(),
                        onChanged: _updateNoteContent,
                        decoration: InputDecoration(
                          hintText: localizeText(context, 'start writing…'),
                          hintStyle: const TextStyle(color: _switchGrey),
                          filled: true,
                          fillColor: panel ??
                              modern?.panel.withValues(alpha: 1) ??
                              (widget.isDark
                                  ? (palette?.surface ?? _surfaceDark)
                                  : widget.isPastel
                                      ? _pastelWhite
                                      : _lightSurface),
                          alignLabelWithHint: true,
                          contentPadding: const EdgeInsets.all(18),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(
                              color: border ??
                                  modern?.border ??
                                  (widget.isDark
                                      ? noteColour.withValues(alpha: 0.55)
                                      : widget.isPastel
                                          ? _pastelMauve
                                          : _lightLine),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(
                              color: border ??
                                  modern?.notesAccent ??
                                  (widget.isDark
                                      ? noteColour
                                      : widget.isPastel
                                          ? _pastelMauve
                                          : _lightLine),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

    return KeyedSubtree(key: ValueKey(note?.id ?? 'empty-note'), child: editor);
  }

  Widget _buildMain(ChecklistProject project, {required bool wide}) {
    final theme = Theme.of(context);
    final accent = theme.custom(_ThemeColour.checklistAccent) ??
        _metalPalette?.checklistAccent ??
        _modernPalette?.checklistAccent;
    final done = project.completedTaskCount;
    final usesSoftKeyboardAction = theme.platform == TargetPlatform.android ||
        theme.platform == TargetPlatform.iOS;
    final composerFrameColor = theme.custom(_ThemeColour.borders) ??
        accent ??
        (theme.brightness == Brightness.dark
            ? _borderWhite
            : theme.dividerColor);
    final reminderColor = accent ?? _brandPurple;
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = wide
            ? ((constraints.maxWidth - 880) / 2).clamp(48, 148).toDouble()
            : 24.0;
        return Column(
          children: [
            Expanded(
              child: CustomScrollView(
                key: ValueKey(project.id),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(horizontal, 22, horizontal, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (!wide) ...[
                                Builder(
                                  builder: (scaffoldContext) => IconButton(
                                    tooltip: localizeText(context, 'open menu'),
                                    onPressed: () =>
                                        Scaffold.of(scaffoldContext)
                                            .openDrawer(),
                                    icon: const Icon(Icons.menu_rounded),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: _contentFade(
                                    _projectReveal,
                                    0,
                                    0.32,
                                    Text(
                                      project.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -1.0,
                                        height: 1.15,
                                      ),
                                    )),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          Row(
                            children: [
                              Expanded(
                                child: AppText(
                                  project.tasks.length == 1
                                      ? '{date}  ·  {tasks} task  ·  {done} completed'
                                      : '{date}  ·  {tasks} tasks  ·  {done} completed',
                                  arguments: {
                                    'date':
                                        _formatDate(context, project.createdAt),
                                    'tasks': project.tasks.length,
                                    'done': done
                                  },
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.58),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              PopupMenuButton<ProjectImportance>(
                                tooltip: localizeText(context, 'Set priority'),
                                initialValue: project.importance,
                                onSelected: (value) =>
                                    _setImportance(project, value),
                                itemBuilder: (context) =>
                                    ProjectImportance.values
                                        .map(
                                          (importance) => PopupMenuItem(
                                            value: importance,
                                            child: _ImportanceMenuLabel(
                                              importance: importance,
                                              isPastel: widget.isPastel,
                                              isPencil: widget.appTheme ==
                                                  AppTheme.pencil,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                child: _ImportanceChip(
                                  importance: project.importance,
                                  isPastel: widget.isPastel,
                                  isPencil: widget.appTheme == AppTheme.pencil,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Tooltip(
                            message: localizeText(
                              context,
                              project.reminderAt == null
                                  ? 'set reminder'
                                  : 'change reminder',
                            ),
                            child: OutlinedButton.icon(
                              key: const ValueKey('checklist-reminder-button'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    widget.isDark || _modernPalette != null
                                        ? reminderColor
                                        : widget.isPastel
                                            ? _pastelMauve
                                            : _lightText,
                                side: BorderSide(
                                  color: widget.isDark || _modernPalette != null
                                      ? reminderColor
                                      : widget.isPastel
                                          ? _pastelMauve
                                          : _lightLine,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () => _editProjectReminder(project),
                              icon: Icon(
                                project.reminderAt == null
                                    ? Icons.calendar_month_outlined
                                    : Icons.event_available_outlined,
                                size: 18,
                              ),
                              label: AppText(
                                project.reminderAt == null
                                    ? 'reminder'
                                    : _formatReminder(
                                        context,
                                        project.reminderAt!,
                                      ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          if (project.tasks.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _AnimatedChecklistProgress(
                              value: done / project.tasks.length,
                              color: accent ??
                                  (widget.isDark
                                      ? _brandYellow
                                      : widget.isPastel
                                          ? _pastelMauve
                                          : _lightText),
                              backgroundColor:
                                  widget.isDark || _modernPalette != null
                                      ? theme.dividerColor
                                      : widget.isPastel
                                          ? _pastelYellow
                                          : const Color(0xFFD8D8D6),
                            ),
                          ],
                          const SizedBox(height: 27),
                          _contentFade(
                              project.coverImagePath == null
                                  ? const AlwaysStoppedAnimation(1.0)
                                  : _projectReveal,
                              0.12,
                              0.52,
                              _CoverImage(
                                path: project.coverImagePath,
                                onBrowse: () => _browseForCover(project),
                                onCamera: () => _takeCoverPhoto(project),
                                onRemove: () => _removeCover(project),
                              )),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  if (project.tasks.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 48),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.checklist_rounded,
                                size: 34,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.32,
                                ),
                              ),
                              const SizedBox(height: 10),
                              AppText(
                                'your list starts here',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        0,
                        horizontal,
                        20,
                      ),
                      sliver: SliverReorderableList(
                        itemCount: project.tasks.length,
                        onReorderItem: _reorderTask,
                        itemBuilder: (context, index) {
                          final task = project.tasks[index];
                          final linkedNote = _linkedNoteFor(task);
                          final start = 0.33 + 0.045 * index.clamp(0, 8);
                          return KeyedSubtree(
                            key: ValueKey('reorder-task-${task.id}'),
                            child: _contentFade(
                                _projectReveal,
                                start,
                                start + 0.30,
                                Material(
                                  color: Colors.transparent,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _TaskRow(
                                        task: task,
                                        linkedNote: linkedNote,
                                        reorderIndex: index,
                                        onToggle: () => _toggleTask(task),
                                        onEdit: () => _editTask(task),
                                        onLinkNote: () => _linkNoteToTask(task),
                                        onOpenNote: linkedNote == null
                                            ? null
                                            : () => _showTaskNote(linkedNote),
                                        onDelete: () => _deleteTask(task),
                                      ),
                                      if (index < project.tasks.length - 1)
                                        Divider(
                                          height: 1,
                                          color: theme.dividerColor,
                                        ),
                                    ],
                                  ),
                                )),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(horizontal, 10, horizontal, 22),
              child: Focus(
                onKeyEvent: _handleTaskKey,
                child: TextField(
                  controller: _taskController,
                  focusNode: _taskFocusNode,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: usesSoftKeyboardAction
                      ? TextInputAction.done
                      : TextInputAction.newline,
                  onSubmitted:
                      usesSoftKeyboardAction ? (_) => _addTask() : null,
                  decoration: InputDecoration(
                    hintText: localizeText(
                      context,
                      usesSoftKeyboardAction
                          ? 'add a task…'
                          : 'add a task…  (enter to add · shift+enter for a new line)',
                    ),
                    hintStyle: const TextStyle(color: _switchGrey),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(
                        color: composerFrameColor,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(
                        color: composerFrameColor,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(
                        color: composerFrameColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NoteBodyReveal extends SingleChildRenderObjectWidget {
  const _NoteBodyReveal({required this.progress, required super.child});

  final Animation<double> progress;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderNoteBodyReveal(progress);

  @override
  void updateRenderObject(
      BuildContext context, _RenderNoteBodyReveal renderObject) {
    renderObject.progress = progress;
  }
}

class _RenderNoteBodyReveal extends RenderProxyBox {
  _RenderNoteBodyReveal(this._progress);

  Animation<double> _progress;

  set progress(Animation<double> value) {
    if (value == _progress) return;
    if (attached) _progress.removeListener(markNeedsPaint);
    _progress = value;
    if (attached) _progress.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _progress.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _progress.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_progress.value >= 1 || size.isEmpty) {
      layer = null;
      super.paint(context, offset);
      return;
    }
    final edge = _progress.value * 1.25 * size.height;
    final mask = (layer as ShaderMaskLayer?) ?? ShaderMaskLayer();
    layer = mask;
    mask
      ..shader = ui.Gradient.linear(
        Offset(0, edge - size.height * 0.25),
        Offset(0, edge),
        const [Colors.white, Colors.transparent],
      )
      ..maskRect = offset & size
      ..blendMode = BlendMode.dstIn;
    context.pushLayer(mask, super.paint, offset);
  }
}

TextStyle _settingsTextStyle(Color color, bool pressed) => TextStyle(
      color: pressed ? Color.lerp(color, Colors.white, 0.32) : color,
      shadows:
          pressed ? const [Shadow(color: Colors.white70, blurRadius: 4)] : null,
    );

class _SettingsPress extends StatefulWidget {
  const _SettingsPress({required this.onTap, required this.builder, super.key});

  final VoidCallback onTap;
  final Widget Function(bool pressed) builder;

  @override
  State<_SettingsPress> createState() => _SettingsPressState();
}

class _SettingsPressState extends State<_SettingsPress> {
  bool _pressed = false;

  Future<void> _activate() async {
    if (_pressed) return;
    setState(() => _pressed = true);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (!mounted) return;
    setState(() => _pressed = false);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: _activate,
        child: widget.builder(_pressed),
      );
}

class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark({
    required this.notesActive,
    required this.onChecklistPressed,
    required this.onNotesPressed,
  });

  final bool notesActive;
  final VoidCallback onChecklistPressed;
  final VoidCallback onNotesPressed;

  Widget _modeButton({
    required String label,
    required bool active,
    required VoidCallback onPressed,
    required Key textKey,
    required Key slotKey,
    required Color checkColor,
    required ThemeData theme,
  }) {
    final metal = theme.metalPalette;
    final modern = theme.appearance?._modernPalette;
    final pixel = theme.appearance == AppTheme.pixel;
    final ink = theme.custom(_ThemeColour.text);
    final activeColor = ink ?? metal?.ink ?? modern?.ink ?? _borderWhite;
    final inactiveColor = ink?.withValues(alpha: 0.66) ??
        metal?.muted ??
        modern?.ink.withValues(alpha: 0.70) ??
        const Color(0xFF8C8791);
    final style = TextStyle(
      color: active ? activeColor : inactiveColor,
      fontFamily: pixel
          ? _pixelFont
          : metal != null
              ? _metalSerif
              : null,
      fontSize: metal != null || pixel ? 14 : 15,
      height: 1,
      fontWeight: metal != null || pixel ? FontWeight.w700 : FontWeight.w900,
      letterSpacing: metal != null ? 0.75 : -0.4,
    );
    return Semantics(
      label: label,
      button: true,
      selected: active,
      excludeSemantics: true,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                key: textKey,
                duration: const Duration(milliseconds: 220),
                style: style,
                child: AppText(label, maxLines: 1),
              ),
              AnimatedContainer(
                key: slotKey,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                width: active ? 26 : 0,
                height: 22,
                decoration: const BoxDecoration(),
                clipBehavior: Clip.hardEdge,
                child: active
                    ? Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Align(
                          key: const ValueKey('selected-mode-check-alignment'),
                          alignment: Alignment.center,
                          child: Transform.translate(
                            key: const ValueKey('selected-mode-check-offset'),
                            offset: const Offset(0, -1.5),
                            child: _GlitchCheckmark(
                              key: const ValueKey('selected-mode-check'),
                              color: checkColor,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.metalPalette;
    final modern = theme.appearance?._modernPalette;
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          _modeButton(
            label: 'CHECKLIST',
            active: !notesActive,
            onPressed: onChecklistPressed,
            textKey: const ValueKey('checklist-word-style'),
            slotKey: const ValueKey('checklist-check-slot'),
            checkColor: theme.custom(_ThemeColour.checklistAccent) ??
                palette?.checklistAccent ??
                modern?.checklistAccent ??
                _brandCyan,
            theme: theme,
          ),
          const SizedBox(width: 6),
          _modeButton(
            label: 'NOTES',
            active: notesActive,
            onPressed: onNotesPressed,
            textKey: const ValueKey('notes-word-style'),
            slotKey: const ValueKey('notes-check-slot'),
            checkColor: theme.custom(_ThemeColour.notesAccent) ??
                palette?.notesAccent ??
                modern?.notesAccent ??
                _defaultNoteBlue,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _WelcomeDialog extends StatefulWidget {
  const _WelcomeDialog();

  @override
  State<_WelcomeDialog> createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends State<_WelcomeDialog> {
  bool _showChanges = false;

  @override
  Widget build(BuildContext context) {
    final changesColour =
        Theme.of(context).metalPalette?.checklistAccent ?? _brandPurple;
    return _popupAlert(
      context,
      key: const ValueKey('welcome-dialog'),
      title: const AppText('welcome to CHECKLIST'),
      content: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText(
              welcomeMessage,
              arguments: {
                'version': checklistVersion,
                'build': checklistBuildNumber
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const ValueKey('welcome-read-more'),
              style: TextButton.styleFrom(
                foregroundColor: changesColour,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
                side: BorderSide.none,
              ),
              onPressed: () => setState(() => _showChanges = !_showChanges),
              child: AppText(_showChanges ? 'read less' : 'read more'),
            ),
            if (_showChanges) ...[
              const SizedBox(height: 4),
              AppText(
                'implemented changes',
                key: const ValueKey('implemented-changes-title'),
                style: TextStyle(
                  color: changesColour,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (final change in _buildChanges)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText('•  '),
                      Expanded(child: AppText(change)),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const AppText('continue'),
        ),
      ],
    );
  }
}

class _VersionInfoDialog extends StatelessWidget {
  const _VersionInfoDialog();

  @override
  Widget build(BuildContext context) {
    return _popupAlert(
      context,
      key: const ValueKey('version-info-dialog'),
      title: const AppText('CHECKLIST $checklistVersion'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText('build {build}',
                  arguments: {'build': checklistBuildNumber}),
              const SizedBox(height: 14),
              AppText(
                'features',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (final feature in _implementedChanges)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText('•  '),
                      Expanded(child: AppText(feature)),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              const AppText(
                'Makers: Ákos Nemes · Codex AI',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const AppText('close'),
        ),
      ],
    );
  }
}

class _BrightActionButton extends StatefulWidget {
  const _BrightActionButton({
    required this.onPressed,
    required this.child,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  State<_BrightActionButton> createState() => _BrightActionButtonState();
}

class _BrightActionButtonState extends State<_BrightActionButton> {
  bool _isBright = false;

  Future<void> _activate() async {
    if (widget.onPressed == null || _isBright) return;
    setState(() => _isBright = true);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (!mounted) return;
    setState(() => _isBright = false);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final normal = Theme.of(context).colorScheme.primary;
    final bright = Color.lerp(normal, Colors.white, 0.32)!;
    return FilledButton(
      onPressed: widget.onPressed == null ? null : _activate,
      style: FilledButton.styleFrom(
        backgroundColor: _isBright ? bright : normal,
      ),
      child: widget.child,
    );
  }
}

class _GlitchCheckmark extends StatefulWidget {
  const _GlitchCheckmark({required this.color, super.key});

  final Color color;

  @override
  State<_GlitchCheckmark> createState() => _GlitchCheckmarkState();
}

class _GlitchCheckmarkState extends State<_GlitchCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final math.Random _random = math.Random();
  Timer? _ambientGlitchTimer;
  bool _strongGlitch = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !MediaQuery.disableAnimationsOf(context)) {
        _runGlitch(strong: true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ambientGlitchTimer?.cancel();
      _ambientGlitchTimer = null;
      _controller.stop();
    } else if (_ambientGlitchTimer == null) {
      _scheduleAmbientGlitch();
    }
  }

  void _runGlitch({required bool strong}) {
    _strongGlitch = strong;
    _controller.duration = Duration(milliseconds: strong ? 520 : 280);
    _controller.forward(from: 0);
  }

  void _scheduleAmbientGlitch() {
    _ambientGlitchTimer?.cancel();
    _ambientGlitchTimer = Timer(
      Duration(seconds: 10 + _random.nextInt(11)),
      () {
        if (!mounted) return;
        _runGlitch(strong: false);
        _scheduleAmbientGlitch();
      },
    );
  }

  @override
  void dispose() {
    _ambientGlitchTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Icon(Icons.check_rounded, color: widget.color, size: 21);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final decay = 1 - progress;
        final amplitude = _strongGlitch ? 3.0 : 0.8;
        final frequency = _strongGlitch ? 19.0 : 11.0;
        final horizontal =
            math.sin(progress * math.pi * frequency) * amplitude * decay;
        final vertical = math.cos(progress * math.pi * (frequency * 0.7)) *
            amplitude *
            0.35 *
            decay;
        final scale = 1 +
            math.sin(progress * math.pi * 13) *
                (_strongGlitch ? 0.11 : 0.035) *
                decay;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (_controller.isAnimating && decay > 0.12) ...[
              Transform.translate(
                offset: Offset(-horizontal * 0.55, vertical * 0.3),
                child: Opacity(
                  opacity: 0.24 * decay,
                  child: Icon(
                    Icons.check_rounded,
                    color: widget.color,
                    size: 21,
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(horizontal * 0.7, -vertical * 0.4),
                child: Opacity(
                  opacity: 0.18 * decay,
                  child: Icon(
                    Icons.check_rounded,
                    color: widget.color,
                    size: 21,
                  ),
                ),
              ),
            ],
            Transform.translate(
              offset: Offset(horizontal, vertical),
              child: Transform.scale(
                scale: scale,
                child: Icon(Icons.check_rounded, color: widget.color, size: 21),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NoteDialogResult {
  const _NoteDialogResult({required this.name, this.categoryId});

  final String name;
  final String? categoryId;
}

class _NoteDetailsDialog extends StatefulWidget {
  const _NoteDetailsDialog({
    required this.title,
    required this.initialText,
    required this.categories,
    this.initialCategoryId,
    this.usePaleBackground = false,
  });

  final String title;
  final String initialText;
  final List<NoteCategory> categories;
  final String? initialCategoryId;
  final bool usePaleBackground;

  @override
  State<_NoteDetailsDialog> createState() => _NoteDetailsDialogState();
}

class _NoteDetailsDialogState extends State<_NoteDetailsDialog> {
  static const _noCategory = '__no_category__';
  late final TextEditingController _controller;
  late String _categoryId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initialText.length,
    );
    _categoryId = widget.initialCategoryId ?? _noCategory;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(
      _NoteDialogResult(
        name: name,
        categoryId: _categoryId == _noCategory ? null : _categoryId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final pastel = base.appearance == AppTheme.pastel;
    final modern = base.appearance?._modernPalette;
    final lightCreate = modern == null &&
        !widget.usePaleBackground &&
        base.brightness == Brightness.light;
    final palette = base.metalPalette;
    final dialogSurface = base.custom(_ThemeColour.panel) ??
        palette?.surface ??
        (modern != null
            ? base.dialogTheme.backgroundColor!
            : widget.usePaleBackground
                ? _renameNotePastelBlue
                : lightCreate
                    ? (pastel ? _pastelWhite : _lightSurface)
                    : _notesSidebar);
    final dialogForeground = base.custom(_ThemeColour.text) ??
        palette?.ink ??
        modern?.ink ??
        (widget.usePaleBackground
            ? _pencilPriorityHigh
            : lightCreate
                ? _lightText
                : _borderWhite);
    final fieldBorder = base.custom(_ThemeColour.borders) ??
        palette?.line ??
        modern?.border ??
        (widget.usePaleBackground ? _deepBlueButton : _borderWhite);
    final buttonOverride = base.custom(_ThemeColour.buttons);
    final noteAccent = base.custom(_ThemeColour.notesAccent) ??
        palette?.notesAccent ??
        modern?.notesAccent ??
        _defaultNoteBlue;
    final actionBackground = buttonOverride ??
        palette?.notesButton ??
        (modern != null ? noteAccent : _deepBlueButton);
    final actionForeground = buttonOverride != null
        ? _contrastingInk(actionBackground)
        : palette?.ink ?? modern?.buttonInk ?? _borderWhite;
    final noteTheme = base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: noteAccent,
        secondary: base.custom(_ThemeColour.checklistAccent) ??
            palette?.checklistAccent ??
            modern?.checklistAccent ??
            _deepBlueButton,
        surface: dialogSurface,
        onSurface: dialogForeground,
      ),
      dialogTheme: base.dialogTheme.copyWith(backgroundColor: dialogSurface),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: dialogSurface,
        hintStyle: TextStyle(
          color: palette?.muted ??
              (widget.usePaleBackground || lightCreate
                  ? _lightControl
                  : _switchGrey),
        ),
        labelStyle: TextStyle(color: dialogForeground),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: fieldBorder, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: fieldBorder, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: actionBackground,
          foregroundColor: actionForeground,
          shape: const RoundedRectangleBorder(),
          side: BorderSide(color: actionForeground, width: 2),
          backgroundBuilder: base.isBlackMetal ? _blackMetalButtonFinish : null,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette?.notesAccent ??
              (widget.usePaleBackground || lightCreate
                  ? _deepBlueButton
                  : noteAccent),
          shape: const RoundedRectangleBorder(),
          side: BorderSide(color: fieldBorder, width: 2),
        ),
      ),
    );

    return Theme(
      data: noteTheme,
      child: _popupAlert(
        context,
        key: const ValueKey('note-details-dialog'),
        backgroundColor: dialogSurface,
        shape: lightCreate
            ? RoundedRectangleBorder(
                side: BorderSide(
                    color: base.custom(_ThemeColour.borders) ??
                        (pastel ? _pastelYellow : _lightLine),
                    width: 2),
              )
            : null,
        title: AppText(widget.title),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                maxLength: 64,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: localizeText(context, 'note name'),
                  counterText: '',
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const ValueKey('note-category-selector'),
                initialValue: _categoryId,
                decoration: InputDecoration(
                  labelText: localizeText(context, 'category'),
                ),
                items: [
                  const DropdownMenuItem(
                    value: _noCategory,
                    child: AppText('no category'),
                  ),
                  for (final category in widget.categories)
                    DropdownMenuItem(
                      value: category.id,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _NoteColourDot(color: Color(category.colorValue)),
                          const SizedBox(width: 10),
                          Flexible(child: Text(category.name)),
                        ],
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _categoryId = value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const AppText('cancel'),
          ),
          _BrightActionButton(onPressed: _submit, child: const AppText('save')),
        ],
      ),
    );
  }
}

class _TextEntryDialog extends StatefulWidget {
  const _TextEntryDialog({
    required this.title,
    required this.initialText,
    required this.hintText,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
    this.submitOnEnter = false,
  });

  final String title;
  final String initialText;
  final String hintText;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final bool submitOnEnter;

  @override
  State<_TextEntryDialog> createState() => _TextEntryDialogState();
}

class _TextEntryDialogState extends State<_TextEntryDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initialText.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return _popupAlert(
      context,
      title: AppText(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        textInputAction: widget.submitOnEnter
            ? TextInputAction.done
            : TextInputAction.newline,
        decoration: InputDecoration(
          hintText: localizeText(context, widget.hintText),
          counterText: '',
        ),
        onSubmitted: widget.submitOnEnter ? (_) => _submit() : null,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const AppText('cancel'),
        ),
        _BrightActionButton(onPressed: _submit, child: const AppText('save')),
      ],
    );
  }
}

class _NoteCategoryPickerDialog extends StatefulWidget {
  const _NoteCategoryPickerDialog({
    required this.categories,
    required this.onDelete,
  });

  final List<NoteCategory> categories;
  final Future<void> Function(NoteCategory category) onDelete;

  @override
  State<_NoteCategoryPickerDialog> createState() =>
      _NoteCategoryPickerDialogState();
}

class _NoteCategoryPickerDialogState extends State<_NoteCategoryPickerDialog> {
  late final List<NoteCategory> _categories;
  bool _removeMode = false;
  String? _removingId;

  @override
  void initState() {
    super.initState();
    _categories = [...widget.categories];
  }

  Future<void> _remove(NoteCategory category) async {
    if (_removingId != null) return;
    setState(() => _removingId = category.id);
    await Future<void>.delayed(const Duration(seconds: 1));
    await widget.onDelete(category);
    if (!mounted) return;
    setState(() {
      _categories.removeWhere((item) => item.id == category.id);
      _removingId = null;
      if (_categories.isEmpty) _removeMode = false;
    });
  }

  Widget _indicator(NoteCategory category) {
    final color = Color(category.colorValue);
    if (!_removeMode) return _NoteColourDot(color: color);
    final selected = category.id == _removingId;
    return AnimatedContainer(
      key: ValueKey('remove-category-${category.id}'),
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        border: Border.all(color: color, width: 2),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.black)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).metalPalette;
    final theme = Theme.of(context);
    final modern = theme.appearance?._modernPalette;
    final cancelFrame = theme.custom(_ThemeColour.borders) ??
        palette?.checklistAccent ??
        modern?.border ??
        _defaultNoteBlue;
    final buttonOverride = theme.custom(_ThemeColour.buttons);
    final actionBackground = buttonOverride ??
        palette?.notesButton ??
        modern?.notesAccent ??
        _deepBlueButton;
    final actionInk = buttonOverride != null
        ? _contrastingInk(actionBackground)
        : modern?.buttonInk ?? _borderWhite;
    return _popupAlert(
      context,
      key: const ValueKey('category-picker-dialog'),
      title: AppText(_removeMode ? 'remove category' : 'change category'),
      content: SizedBox(
        width: 320,
        child: ListView(
          shrinkWrap: true,
          children: [
            if (!_removeMode)
              ListTile(
                leading: const Icon(Icons.block_rounded),
                title: const AppText('no category'),
                onTap: () => Navigator.pop(context, ''),
              ),
            if (_categories.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: AppText(
                  'no categories yet',
                  textAlign: TextAlign.center,
                ),
              ),
            for (final category in _categories)
              ListTile(
                leading: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _indicator(category),
                ),
                title: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        decoration: category.id == _removingId
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                  child: Text(category.name),
                ),
                onTap: _removingId != null
                    ? null
                    : () {
                        if (_removeMode) {
                          _remove(category);
                        } else {
                          Navigator.pop(context, category.id);
                        }
                      },
              ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        SizedBox(
          key: const ValueKey('category-action-row'),
          width: 320,
          child: Row(
            children: [
              if (!_removeMode) ...[
                Expanded(
                  child: TextButton(
                    key: const ValueKey('category-cancel-button'),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: _switchGrey,
                      side: BorderSide(color: cancelFrame, width: 2),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const AppText('cancel'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('category-new-button'),
                    style: FilledButton.styleFrom(
                      backgroundColor: actionBackground,
                      foregroundColor: actionInk,
                      side: const BorderSide(color: _borderWhite, width: 2),
                    ),
                    onPressed: () => Navigator.pop(context, '__new__'),
                    child: const AppText('new'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('category-remove-button'),
                    style: FilledButton.styleFrom(
                      backgroundColor: actionBackground,
                      foregroundColor: actionInk,
                      side: const BorderSide(color: _borderWhite, width: 2),
                    ),
                    onPressed: _categories.isEmpty
                        ? null
                        : () => setState(() => _removeMode = true),
                    child: const AppText('remove'),
                  ),
                ),
              ] else
                Expanded(
                  child: TextButton(
                    onPressed: _removingId == null
                        ? () => setState(() => _removeMode = false)
                        : null,
                    child: const AppText('done'),
                  ),
                ),
              if (_removeMode) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: TextButton(
                    key: const ValueKey('category-cancel-button'),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: _switchGrey,
                      side: BorderSide(color: cancelFrame, width: 2),
                    ),
                    onPressed: _removingId == null
                        ? () => Navigator.pop(context)
                        : null,
                    child: const AppText('cancel'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CategorySettingsDialog extends StatelessWidget {
  const _CategorySettingsDialog({required this.categories});

  final List<NoteCategory> categories;

  @override
  Widget build(BuildContext context) {
    return _popupAlert(
      context,
      key: const ValueKey('category-settings-dialog'),
      title: const AppText('category settings'),
      content: SizedBox(
        width: 320,
        child: categories.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: AppText(
                  'no categories yet',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final category in categories)
                    ListTile(
                      leading: _NoteColourDot(
                        color: Color(category.colorValue),
                      ),
                      title: Text(category.name),
                      trailing: const Icon(Icons.edit_rounded),
                      onTap: () => Navigator.pop(context, category.id),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const AppText('close'),
        ),
      ],
    );
  }
}

class _NewNoteCategoryDialog extends StatefulWidget {
  const _NewNoteCategoryDialog({this.category});

  final NoteCategory? category;

  @override
  State<_NewNoteCategoryDialog> createState() => _NewNoteCategoryDialogState();
}

class _NewNoteCategoryDialogState extends State<_NewNoteCategoryDialog> {
  late final TextEditingController _controller;
  int _selectedColour = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.category?.name ?? '');
    final colourIndex = _noteColours.indexWhere(
      (colour) => colour.toARGB32() == widget.category?.colorValue,
    );
    if (colourIndex >= 0) _selectedColour = colourIndex;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(
      NoteCategory(
        id: widget.category?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        colorValue: _noteColours[_selectedColour].toARGB32(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _popupAlert(
      context,
      title: AppText(
        widget.category == null ? 'new category' : 'edit category',
      ),
      content: SizedBox(
        width: 310,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 40,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: localizeText(context, 'category name'),
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            AppText('colour', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_noteColours.length, (index) {
                final selected = index == _selectedColour;
                return Semantics(
                  label: '${localizeText(context, 'colour')} ${index + 1}',
                  button: true,
                  selected: selected,
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => setState(() => _selectedColour = index),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _noteColours[index],
                        border: Border.all(
                          color: selected ? _borderWhite : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.black,
                              size: 20,
                            )
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const AppText('cancel'),
        ),
        _BrightActionButton(
          onPressed: _submit,
          child: AppText(widget.category == null ? 'create' : 'save'),
        ),
      ],
    );
  }
}

class _NoteColourDot extends StatelessWidget {
  const _NoteColourDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _HeartBubbleLayer extends StatefulWidget {
  const _HeartBubbleLayer({
    required this.enabled,
    required this.drawerOpen,
    required this.restartSignal,
  });

  final bool enabled;
  final bool drawerOpen;
  final int restartSignal;

  @override
  State<_HeartBubbleLayer> createState() => _HeartBubbleLayerState();
}

class _HeartBubbleLayerState extends State<_HeartBubbleLayer>
    with SingleTickerProviderStateMixin {
  static const _heartColors = <Color>[
    _brandMagenta,
    _brandCyan,
    _brandPurple,
    _brandYellow,
    Color(0xFFE85D75),
    _borderWhite,
  ];

  final _random = math.Random();
  final _particles = <_HeartParticle>[];
  late final AnimationController _controller;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  Duration? _lastFrame;
  Size _size = Size.zero;
  double _accelerationX = 0;
  double _accelerationY = 9.8;
  double _gyroscopeX = 0;
  double _gyroscopeY = 0;
  double _motion = 0;
  double _blowTime = 0;
  bool _bursting = false;
  bool _restartWhenSized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_tick);
    if (widget.enabled) _listenToSensors();
    if (widget.enabled && widget.drawerOpen) _restartWhenSized = true;
  }

  @override
  void didUpdateWidget(covariant _HeartBubbleLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _listenToSensors();
        if (widget.drawerOpen) _startBlow();
      } else {
        _stopSensors();
        _particles.clear();
        _bursting = false;
        _controller.stop();
      }
    }
    if (widget.enabled && widget.drawerOpen && !oldWidget.drawerOpen) {
      _startBlow();
    } else if (widget.enabled && !widget.drawerOpen && oldWidget.drawerOpen) {
      _startBurst();
    }
    if (widget.enabled &&
        widget.drawerOpen &&
        widget.restartSignal != oldWidget.restartSignal) {
      _startBlow();
    }
  }

  void _listenToSensors() {
    _accelerometerSubscription ??=
        accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
            .listen((event) {
      final delta =
          (event.x - _accelerationX).abs() + (event.y - _accelerationY).abs();
      _accelerationX = (_accelerationX * 0.72) + (event.x * 0.28);
      _accelerationY = (_accelerationY * 0.72) + (event.y * 0.28);
      _motion = math.max(_motion, delta * 0.08);
    }, onError: (_) {});
    _gyroscopeSubscription ??=
        gyroscopeEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
            (event) {
      _gyroscopeX = event.x;
      _gyroscopeY = event.y;
      final rotation = math.sqrt(
        (event.x * event.x) + (event.y * event.y) + (event.z * event.z),
      );
      _motion = math.max(_motion, rotation);
    }, onError: (_) {});
  }

  void _stopSensors() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
  }

  void _ensureAnimating() {
    if (_controller.isAnimating) return;
    _lastFrame = null;
    _controller.repeat();
  }

  void _startBlow() {
    if (!widget.enabled || !widget.drawerOpen) return;
    _bursting = false;
    if (_size.isEmpty) {
      _restartWhenSized = true;
    } else {
      _resetParticlesForBlow();
    }
    _ensureAnimating();
  }

  void _resetParticlesForBlow() {
    if (_size.isEmpty) return;
    if (_particles.isEmpty) {
      for (var index = 0; index < 22; index++) {
        _particles.add(
          _HeartParticle(
            x: 12 + _random.nextDouble() * math.max(1, _size.width - 24),
            y: _size.height - 8 - _random.nextDouble() * 12,
            radius: 6 + _random.nextDouble() * 5,
            color: _heartColors[index % _heartColors.length],
            rotation: (_random.nextDouble() - 0.5) * 0.7,
          ),
        );
      }
    }
    for (var index = 0; index < _particles.length; index++) {
      final particle = _particles[index];
      particle
        ..x = particle.x.clamp(10, math.max(10, _size.width - 10))
        ..y = _size.height - particle.radius
        ..velocityX = (_random.nextDouble() - 0.5) * 55
        ..velocityY = -125 - _random.nextDouble() * 105
        ..delay = index * 0.045
        ..settled = false
        ..burst = 0;
    }
    _blowTime = 1.65;
    _motion = 0;
    _restartWhenSized = false;
  }

  void _startBurst() {
    if (_particles.isEmpty) return;
    _bursting = true;
    for (final particle in _particles) {
      particle
        ..burst = 0
        ..settled = false;
    }
    _ensureAnimating();
  }

  void _tick() {
    final elapsed = _controller.lastElapsedDuration;
    if (elapsed == null) return;
    final lastFrame = _lastFrame;
    _lastFrame = elapsed;
    if (lastFrame == null) return;
    final seconds = ((elapsed - lastFrame).inMicroseconds / 1000000).clamp(
      0.0,
      0.05,
    );

    if (_bursting) {
      for (final particle in _particles) {
        particle.burst = (particle.burst + seconds * 3.2).clamp(0, 1);
      }
      if (_particles.every((particle) => particle.burst >= 1)) {
        _particles.clear();
        _bursting = false;
        _controller.stop();
      }
      if (mounted) setState(() {});
      return;
    }
    if (!widget.enabled || !widget.drawerOpen || _size.isEmpty) return;

    _blowTime = math.max(0, _blowTime - seconds);
    final blowing = _blowTime > 0;
    final gravityX = ((-_accelerationX * 18) + (_gyroscopeY * 28)).clamp(
      -240.0,
      240.0,
    );
    final gravityY = (105 + (_accelerationY * 12) + (_gyroscopeX * 18)).clamp(
      -90.0,
      280.0,
    );

    for (final particle in _particles) {
      if (particle.delay > 0) {
        particle.delay -= seconds;
        continue;
      }
      if (particle.settled) {
        if (_motion > 0.22 || blowing) {
          particle
            ..settled = false
            ..velocityX = (_random.nextDouble() - 0.5) * 60 - (_gyroscopeY * 35)
            ..velocityY = -25 - math.min(100, _motion * 38);
        } else {
          continue;
        }
      }

      particle.velocityX += gravityX * seconds;
      particle.velocityY += (gravityY - (blowing ? 245 : 0)) * seconds;
      final drag = math.pow(0.985, seconds * 60).toDouble();
      particle.velocityX *= drag;
      particle.velocityY *= drag;
      particle.x += particle.velocityX * seconds;
      particle.y += particle.velocityY * seconds;
      particle.rotation += particle.velocityX * seconds * 0.0025;

      if (particle.x < particle.radius) {
        particle
          ..x = particle.radius
          ..velocityX = particle.velocityX.abs() * 0.42;
      } else if (particle.x > _size.width - particle.radius) {
        particle
          ..x = _size.width - particle.radius
          ..velocityX = -particle.velocityX.abs() * 0.42;
      }
      if (particle.y < particle.radius) {
        particle
          ..y = particle.radius
          ..velocityY = particle.velocityY.abs() * 0.32;
      }
      if (particle.y >= _size.height - particle.radius) {
        particle.y = _size.height - particle.radius;
        if (!blowing && particle.velocityY.abs() < 48) {
          particle
            ..velocityX = 0
            ..velocityY = 0
            ..settled = true;
        } else {
          particle.velocityY = -particle.velocityY.abs() * 0.28;
        }
      }
    }
    _motion *= math.pow(0.9, seconds * 60).toDouble();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _stopSensors();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final nextSize = constraints.biggest;
        if (nextSize.isFinite && nextSize != _size) {
          _size = nextSize;
          for (final particle in _particles) {
            particle
              ..x = particle.x.clamp(0, _size.width)
              ..y = particle.y.clamp(0, _size.height);
          }
        }
        if (_restartWhenSized && !_size.isEmpty) {
          _resetParticlesForBlow();
        }
        return CustomPaint(
          painter: _HeartBubblePainter(
            particles: _particles,
            bursting: _bursting,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _HeartParticle {
  _HeartParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
    required this.rotation,
  });

  double x;
  double y;
  final double radius;
  final Color color;
  double rotation;
  double velocityX = 0;
  double velocityY = 0;
  double delay = 0;
  double burst = 0;
  bool settled = false;
}

class _HeartBubblePainter extends CustomPainter {
  const _HeartBubblePainter({required this.particles, required this.bursting});

  final List<_HeartParticle> particles;
  final bool bursting;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final opacity = (1 - particle.burst).clamp(0.0, 1.0);
      if (opacity <= 0) continue;
      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity * 0.72)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(particle.x, particle.y);
      canvas.rotate(particle.rotation);
      final scale = bursting ? 1 + (particle.burst * 0.7) : 1.0;
      canvas.scale(scale);
      final radius = particle.radius;
      final heart = Path()
        ..moveTo(0, radius * 0.85)
        ..cubicTo(
          -radius * 1.25,
          radius * 0.05,
          -radius * 0.95,
          -radius * 0.95,
          0,
          -radius * 0.35,
        )
        ..cubicTo(
          radius * 0.95,
          -radius * 0.95,
          radius * 1.25,
          radius * 0.05,
          0,
          radius * 0.85,
        )
        ..close();
      canvas.drawPath(heart, paint);
      if (bursting && particle.burst > 0.15) {
        final fragmentPaint = Paint()
          ..color = particle.color.withValues(alpha: opacity * 0.8);
        for (var index = 0; index < 4; index++) {
          final angle = (math.pi / 2 * index) + particle.rotation;
          final distance = radius * particle.burst * 2.2;
          canvas.drawCircle(
            Offset(math.cos(angle) * distance, math.sin(angle) * distance),
            math.max(1, radius * 0.14 * opacity),
            fragmentPaint,
          );
        }
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _HeartBubblePainter oldDelegate) => true;
}

class _ChecklistReminderResult {
  const _ChecklistReminderResult(this.reminderAt);

  final DateTime? reminderAt;
}

class _ChecklistReminderDialog extends StatefulWidget {
  const _ChecklistReminderDialog({
    required this.checklistName,
    required this.initialReminder,
  });

  final String checklistName;
  final DateTime? initialReminder;

  @override
  State<_ChecklistReminderDialog> createState() =>
      _ChecklistReminderDialogState();
}

class _ChecklistReminderDialogState extends State<_ChecklistReminderDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialReminder?.toLocal() ??
        DateTime.now().add(const Duration(days: 1));
    _selectedDate = DateUtils.dateOnly(initial);
    _selectedTime = TimeOfDay.fromDateTime(initial);
  }

  Future<void> _chooseTime() async {
    final selected = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) => _animatedTimePicker(
        context,
        initialTime: _selectedTime,
        helpText: localizeText(context, 'reminder time'),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selectedTime = selected);
    }
  }

  void _save() {
    Navigator.pop(
      context,
      _ChecklistReminderResult(
        DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _popupAlert(
      context,
      key: const ValueKey('checklist-reminder-dialog'),
      title: const AppText(
        'reminder',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.checklistName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            CalendarDatePicker(
              key: const ValueKey('checklist-reminder-calendar'),
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              onDateChanged: (value) =>
                  setState(() => _selectedDate = DateUtils.dateOnly(value)),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const ValueKey('checklist-reminder-time'),
              onPressed: _chooseTime,
              icon: const Icon(Icons.schedule_rounded),
              label: AppText(_selectedTime.format(context)),
            ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const AppText('cancel'),
                ),
              ),
              if (widget.initialReminder != null) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: TextButton(
                    key: const ValueKey('remove-checklist-reminder'),
                    onPressed: () => Navigator.pop(
                      context,
                      const _ChecklistReminderResult(null),
                    ),
                    child: const AppText('remove'),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Expanded(
                child: _BrightActionButton(
                  key: const ValueKey('save-checklist-reminder'),
                  onPressed: _save,
                  child: const AppText('save'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NewProjectDialog extends StatefulWidget {
  const _NewProjectDialog();

  @override
  State<_NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<_NewProjectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(
      context,
      ChecklistProject(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _popupAlert(
      context,
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 48,
        decoration: InputDecoration(
          hintText: localizeText(context, 'checklist name'),
          hintStyle: const TextStyle(color: _switchGrey),
          counterText: '',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const AppText('cancel'),
        ),
        _BrightActionButton(
          key: const ValueKey('create-checklist'),
          onPressed: _submit,
          child: const AppText('create'),
        ),
      ],
    );
  }
}

enum _CoverSource { camera, browse }

class _CoverCropDialog extends StatefulWidget {
  const _CoverCropDialog({required this.sourcePath});

  final String sourcePath;

  @override
  State<_CoverCropDialog> createState() => _CoverCropDialogState();
}

class _CoverCropDialogState extends State<_CoverCropDialog> {
  final _boundaryKey = GlobalKey();
  final _transformationController = TransformationController();
  Size? _sourceSize;
  Size? _lastFrameSize;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _readImageSize();
  }

  Future<void> _readImageSize() async {
    try {
      final bytes = await File(widget.sourcePath).readAsBytes();
      final decoded = image_library.decodeImage(bytes);
      if (decoded == null) {
        throw StateError('The selected image could not be opened.');
      }
      final size = Size(decoded.width.toDouble(), decoded.height.toDouble());
      if (mounted) setState(() => _sourceSize = size);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  void _centreImage(Size frameSize, Size imageSize) {
    if (_lastFrameSize == frameSize) return;
    _lastFrameSize = frameSize;
    final imageAspect = imageSize.width / imageSize.height;
    final childWidth = imageAspect > _coverAspectRatio
        ? frameSize.height * imageAspect
        : frameSize.width;
    final childHeight = imageAspect > _coverAspectRatio
        ? frameSize.height
        : frameSize.width / imageAspect;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _transformationController.value = Matrix4.translationValues(
        (frameSize.width - childWidth) / 2,
        (frameSize.height - childHeight) / 2,
        0,
      );
    });
  }

  Future<void> _saveCrop() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('The crop is not ready.');
      final pixelRatio = math.min(3.0, 1600 / math.max(1, boundary.size.width));
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('The crop could not be saved.');
      if (mounted) Navigator.pop(context, data.buffer.asUint8List());
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Widget _cropFrame(Size sourceSize) {
    return AspectRatio(
      aspectRatio: _coverAspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final frameSize = constraints.biggest;
          final imageAspect = sourceSize.width / sourceSize.height;
          final childWidth = imageAspect > _coverAspectRatio
              ? frameSize.height * imageAspect
              : frameSize.width;
          final childHeight = imageAspect > _coverAspectRatio
              ? frameSize.height
              : frameSize.width / imageAspect;
          _centreImage(frameSize, sourceSize);
          return Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                key: _boundaryKey,
                child: ClipRect(
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    constrained: false,
                    minScale: 1,
                    maxScale: 5,
                    panEnabled: true,
                    scaleEnabled: true,
                    child: SizedBox(
                      width: childWidth,
                      height: childHeight,
                      child: Image.file(
                        File(widget.sourcePath),
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  key: const ValueKey('cover-crop-frame'),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).metalPalette?.checklistAccent ??
                          _brandPurple,
                      width: 3,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sourceSize = _sourceSize;
    return _popupAlert(
      context,
      key: const ValueKey('cover-crop-dialog'),
      title: const AppText('choose your cover'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sourceSize == null && _error == null)
              const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (sourceSize != null)
              _cropFrame(sourceSize)
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: AppText(_error!, textAlign: TextAlign.center),
              ),
            if (sourceSize != null) ...[
              const SizedBox(height: 12),
              const AppText(
                'drag to move • pinch or scroll to zoom',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const AppText('cancel'),
        ),
        FilledButton(
          key: const ValueKey('save-cover-crop'),
          onPressed: sourceSize == null || _saving ? null : _saveCrop,
          child: _saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const AppText('use crop'),
        ),
      ],
    );
  }
}

class _CoverImage extends StatefulWidget {
  const _CoverImage({
    required this.path,
    required this.onBrowse,
    required this.onCamera,
    required this.onRemove,
  });

  final String? path;
  final VoidCallback onBrowse;
  final VoidCallback onCamera;
  final VoidCallback onRemove;

  @override
  State<_CoverImage> createState() => _CoverImageState();
}

class _CoverImageState extends State<_CoverImage> {
  Timer? _hideRemoveTimer;
  bool _showRemove = false;

  @override
  void initState() {
    super.initState();
    if (widget.path != null) _revealRemoveButton(rebuild: false);
  }

  @override
  void didUpdateWidget(covariant _CoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path == widget.path) return;
    _hideRemoveTimer?.cancel();
    _showRemove = widget.path != null;
    if (_showRemove) _scheduleRemoveButtonHide();
  }

  void _revealRemoveButton({bool rebuild = true}) {
    _hideRemoveTimer?.cancel();
    if (rebuild && !_showRemove) setState(() => _showRemove = true);
    if (!rebuild) _showRemove = true;
    _scheduleRemoveButtonHide();
  }

  void _scheduleRemoveButtonHide() {
    _hideRemoveTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showRemove = false);
    });
  }

  @override
  void dispose() {
    _hideRemoveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imagePath = widget.path;
    if (imagePath == null) {
      return PopupMenuButton<_CoverSource>(
        key: const ValueKey('cover-source-menu'),
        tooltip: localizeText(context, 'Add a cover image'),
        position: PopupMenuPosition.under,
        onSelected: (source) {
          switch (source) {
            case _CoverSource.camera:
              widget.onCamera();
              break;
            case _CoverSource.browse:
              widget.onBrowse();
              break;
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            key: ValueKey('cover-camera-option'),
            value: _CoverSource.camera,
            child: AppText('camera'),
          ),
          PopupMenuItem(
            key: ValueKey('cover-browse-option'),
            value: _CoverSource.browse,
            child: AppText('browse'),
          ),
        ],
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 116),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.62),
            border: Border.all(color: theme.dividerColor, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 25,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
              const SizedBox(height: 8),
              AppText(
                'Add a cover image',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AspectRatio(
      key: const ValueKey('checklist-cover-frame'),
      aspectRatio: _coverAspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            key: const ValueKey('cover-image-interaction'),
            behavior: HitTestBehavior.opaque,
            onTap: _revealRemoveButton,
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: theme.colorScheme.surface,
                alignment: Alignment.center,
                child: const AppText(
                  'This cover image is no longer available.',
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: _showRemove
                  ? IconButton.filledTonal(
                      key: const ValueKey('cover-remove-button'),
                      tooltip: localizeText(context, 'Remove cover image'),
                      onPressed: widget.onRemove,
                      icon: const Icon(Icons.close_rounded),
                    )
                  : const SizedBox.shrink(key: ValueKey('cover-remove-hidden')),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskNotePickerDialog extends StatelessWidget {
  const _TaskNotePickerDialog({
    required this.notes,
    required this.selectedNoteId,
  });

  final List<NoteEntry> notes;
  final String? selectedNoteId;

  @override
  Widget build(BuildContext context) {
    return _popupAlert(
      context,
      key: const ValueKey('task-note-picker'),
      title: const AppText('link a note'),
      content: SizedBox(
        width: 360,
        height: notes.isEmpty ? 90 : 320,
        child: notes.isEmpty
            ? const Center(child: AppText('no notes yet'))
            : ListView.separated(
                key: const ValueKey('task-note-picker-list'),
                itemCount: notes.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final note = notes[index];
                  final links = findNoteLinks(note.content);
                  final formatted = _NoteFormatting(note.content, links);
                  return ListTile(
                    key: ValueKey('task-note-choice-${note.id}'),
                    title: Text(
                      note.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text.rich(
                      formatted.plainText.isEmpty
                          ? TextSpan(text: localizeText(context, 'empty note'))
                          : formatted.buildTextSpan(note.content, links,
                              base: const TextStyle(),
                              theme: Theme.of(context)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: note.id == selectedNoteId
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () => Navigator.pop(context, note.id),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const AppText('cancel'),
        ),
      ],
    );
  }
}

class _TaskLinkedNoteDialog extends StatefulWidget {
  const _TaskLinkedNoteDialog({
    required this.note,
    required this.frameColour,
    required this.onOpenLink,
  });

  final NoteEntry note;
  final Color frameColour;
  final ValueChanged<Uri> onOpenLink;

  @override
  State<_TaskLinkedNoteDialog> createState() => _TaskLinkedNoteDialogState();
}

class _TaskLinkedNoteDialogState extends State<_TaskLinkedNoteDialog> {
  late final _content = widget.note.content;
  late final _links = findNoteLinks(_content);
  late final _formatting = _NoteFormatting(_content, _links);
  late final _linkTaps = {
    for (final link in _links)
      link.start: TapGestureRecognizer()
        ..onTap = () => widget.onOpenLink(link.uri),
  };

  @override
  void dispose() {
    for (final tap in _linkTaps.values) {
      tap.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.metalPalette;
    final modern = theme.appearance?._modernPalette;
    final bodyStyle = (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
      color: theme.custom(_ThemeColour.text) ??
          palette?.ink ??
          modern?.ink ??
          (theme.brightness == Brightness.dark ? _borderWhite : _lightText),
      height: 1.5,
    );
    return _popupAlert(
      context,
      key: const ValueKey('task-linked-note-dialog'),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: widget.frameColour, width: 2),
      ),
      title: Row(
        children: [
          Icon(Icons.note_rounded,
              color: theme.custom(_ThemeColour.notesAccent) ??
                  palette?.notesAccent ??
                  modern?.notesAccent ??
                  _defaultNoteBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.note.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        height: 360,
        child: Scrollbar(
          child: SingleChildScrollView(
            key: const ValueKey('task-linked-note-scroll'),
            child: SelectionArea(
              child: Text.rich(
                _formatting.plainText.isEmpty
                    ? TextSpan(
                        text: localizeText(context, 'this note is empty'))
                    : _formatting.buildTextSpan(
                        _content,
                        _links,
                        base: bodyStyle,
                        theme: theme,
                        linkTaps: _linkTaps,
                      ),
                style: bodyStyle,
              ),
            ),
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const AppText('close'),
        ),
      ],
    );
  }
}

class _SidebarFadeItem extends StatefulWidget {
  const _SidebarFadeItem({
    required this.visible,
    required this.child,
    super.key,
  });

  final bool visible;
  final Widget child;

  @override
  State<_SidebarFadeItem> createState() => _SidebarFadeItemState();
}

class _SidebarFadeItemState extends State<_SidebarFadeItem> {
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _entered = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      key: const ValueKey('sidebar-entry-fade'),
      opacity: widget.visible && _entered ? 1 : 0,
      duration: _sidebarEntryFadeDuration,
      curve: Curves.easeInOut,
      child: widget.child,
    );
  }
}

class _AnimatedChecklistProgress extends StatelessWidget {
  const _AnimatedChecklistProgress({
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  final double value;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('animated-checklist-progress'),
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) => LinearProgressIndicator(
        minHeight: 5,
        value: animatedValue,
        color: color,
        backgroundColor: backgroundColor,
      ),
    );
  }
}

class _TaskHoldReorderListener extends ReorderableDragStartListener {
  const _TaskHoldReorderListener({
    required super.index,
    required super.child,
    super.key,
  });

  @override
  MultiDragGestureRecognizer createRecognizer() {
    return DelayedMultiDragGestureRecognizer(
      delay: _taskReorderHoldDuration,
      debugOwner: this,
    );
  }
}

class _LinkedNoteButton extends StatefulWidget {
  const _LinkedNoteButton({required this.taskId, required this.onPressed});

  final String taskId;
  final Future<void> Function() onPressed;

  @override
  State<_LinkedNoteButton> createState() => _LinkedNoteButtonState();
}

class _LinkedNoteButtonState extends State<_LinkedNoteButton> {
  bool _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    await Future<void>.delayed(_linkedNoteCueDuration);
    if (!mounted) return;
    await widget.onPressed();
    if (mounted) setState(() => _opening = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.metalPalette;
    final restingColour = palette?.checklistAccent ??
        (theme.brightness == Brightness.dark ? _brandYellow : _defaultNoteBlue);
    final targetColor =
        _opening ? (palette?.notesAccent ?? _brandPurple) : restingColour;
    return IconButton(
      key: ValueKey('task-note-button-${widget.taskId}'),
      tooltip: localizeText(context, 'open linked note'),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      style: IconButton.styleFrom(side: BorderSide.none),
      onPressed: _open,
      icon: TweenAnimationBuilder<Color?>(
        tween: ColorTween(begin: restingColour, end: targetColor),
        duration: const Duration(milliseconds: 90),
        builder: (context, color, child) => Icon(
          Icons.sticky_note_2_rounded,
          key: ValueKey('task-note-icon-${widget.taskId}'),
          size: 20,
          color: color,
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.linkedNote,
    required this.reorderIndex,
    required this.onToggle,
    required this.onEdit,
    required this.onLinkNote,
    required this.onOpenNote,
    required this.onDelete,
  });

  final ChecklistTask task;
  final NoteEntry? linkedNote;
  final int reorderIndex;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onLinkNote;
  final Future<void> Function()? onOpenNote;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskText = SelectableText(
      task.text,
      key: ValueKey(
        linkedNote == null
            ? 'task-text-${task.id}'
            : 'task-note-opener-${task.id}',
      ),
      onTap: onOpenNote == null ? null : () => onOpenNote!(),
      style: theme.textTheme.bodyLarge?.copyWith(
        height: 1.45,
        color: task.isDone
            ? theme.colorScheme.onSurface.withValues(alpha: 0.44)
            : null,
        decoration: task.isDone ? TextDecoration.lineThrough : null,
        decorationColor: theme.colorScheme.onSurface.withValues(alpha: 0.45),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            key: ValueKey('task-leading-column-${task.id}'),
            width: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox.square(
                  key: ValueKey('task-checkbox-${task.id}'),
                  dimension: 32,
                  child: Checkbox(
                    value: task.isDone,
                    onChanged: (_) => onToggle(),
                    shape: const RoundedRectangleBorder(),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    visualDensity: VisualDensity.standard,
                  ),
                ),
                if (linkedNote != null)
                  Padding(
                    key: ValueKey('task-note-below-checkbox-${task.id}'),
                    padding: const EdgeInsets.only(top: 2),
                    child: _LinkedNoteButton(
                      taskId: task.id,
                      onPressed: onOpenNote!,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: _TaskHoldReorderListener(
                key: ValueKey('task-reorder-area-${task.id}'),
                index: reorderIndex,
                child: taskText,
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: localizeText(context, 'Task options'),
            padding: EdgeInsets.zero,
            onSelected: (action) {
              if (action == 'edit') onEdit();
              if (action == 'note') onLinkNote();
              if (action == 'delete') onDelete();
            },
            child: SizedBox.square(
              key: const ValueKey('task-settings'),
              dimension: 40,
              child: Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.48),
              ),
            ),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: AppText('edit')),
              PopupMenuItem(value: 'note', child: AppText('+ note')),
              PopupMenuItem(value: 'delete', child: AppText('delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImportanceBar extends StatelessWidget {
  const _ImportanceBar({
    required this.importance,
    this.isPastel = false,
    this.isPencil = false,
    this.width = 10,
    this.height = 42,
  });

  final ProjectImportance importance;
  final bool isPastel;
  final bool isPencil;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _themedImportanceColor(theme, importance,
        isPastel: isPastel, isPencil: isPencil);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        border: _blackMetalMediumRim(theme, importance),
        boxShadow: _pixelPriorityGlow(theme, color),
      ),
    );
  }
}

class _ImportanceChip extends StatelessWidget {
  const _ImportanceChip({
    required this.importance,
    this.isPastel = false,
    this.isPencil = false,
  });

  final ProjectImportance importance;
  final bool isPastel;
  final bool isPencil;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _themedImportanceColor(theme, importance,
        isPastel: isPastel, isPencil: isPencil);
    final mediumRim = _blackMetalMediumRim(theme, importance, width: 2);
    return Container(
      key: ValueKey('priority-chip-${importance.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: mediumRim != null ? color : color.withValues(alpha: 0.12),
        border: mediumRim ?? Border.all(color: color, width: 2),
        boxShadow: _pixelPriorityGlow(theme, color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ImportanceBar(
            importance: importance,
            isPastel: isPastel,
            isPencil: isPencil,
            width: 4,
            height: 16,
          ),
          const SizedBox(width: 7),
          AppText(
            _importanceLabel(importance),
            style: theme.textTheme.labelMedium?.copyWith(
                color: mediumRim != null ? _blackMetalMediumLabel : color),
          ),
        ],
      ),
    );
  }
}

class _ImportanceMenuLabel extends StatelessWidget {
  const _ImportanceMenuLabel({
    required this.importance,
    required this.isPastel,
    required this.isPencil,
  });

  final ProjectImportance importance;
  final bool isPastel;
  final bool isPencil;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _themedImportanceColor(theme, importance,
        isPastel: isPastel, isPencil: isPencil);
    final mediumRim = _blackMetalMediumRim(theme, importance);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: ValueKey('priority-menu-${importance.name}'),
          width: 4,
          height: 18,
          color: mediumRim == null ? color : null,
          decoration: mediumRim == null
              ? null
              : BoxDecoration(color: color, border: mediumRim),
        ),
        const SizedBox(width: 8),
        AppText(
          _importanceLabel(importance),
          style: theme.textTheme.bodyMedium?.copyWith(
              color: mediumRim != null ? _blackMetalMediumLabel : color),
        ),
      ],
    );
  }
}

String _importanceLabel(ProjectImportance importance) {
  return switch (importance) {
    ProjectImportance.low => 'low',
    ProjectImportance.normal => 'medium',
    ProjectImportance.high => 'high',
  };
}

Border? _blackMetalMediumRim(ThemeData theme, ProjectImportance importance,
        {double width = 1}) =>
    theme.isBlackMetal && importance == ProjectImportance.normal
        ? Border.all(color: const Color(0xFF9E70AE), width: width)
        : null;

List<BoxShadow>? _pixelPriorityGlow(ThemeData theme, Color colour) =>
    theme.appearance == AppTheme.pixel
        ? [BoxShadow(color: colour.withValues(alpha: 0.23), blurRadius: 7)]
        : null;

Color _themedImportanceColor(
  ThemeData theme,
  ProjectImportance importance, {
  required bool isPastel,
  required bool isPencil,
}) {
  final custom = theme.custom(switch (importance) {
    ProjectImportance.low => _ThemeColour.low,
    ProjectImportance.normal => _ThemeColour.medium,
    ProjectImportance.high => _ThemeColour.high,
  });
  if (custom != null) return custom;
  if (isPastel) return _pastelImportanceColor(importance);
  if (isPencil) return _pencilImportanceColor(importance);
  if (theme.metalPalette case final palette?) {
    return switch (importance) {
      ProjectImportance.low => palette.muted,
      ProjectImportance.normal =>
        theme.isBlackMetal ? _blackMetalMedium : palette.notesAccent,
      ProjectImportance.high => palette.checklistAccent,
    };
  }
  if (theme.appearance?._modernPalette case final palette?) {
    return palette.priorities[importance.index];
  }
  return theme.brightness == Brightness.dark
      ? _importanceColor(importance)
      : theme.colorScheme.primary;
}

Color _importanceColor(ProjectImportance importance) {
  return switch (importance) {
    ProjectImportance.low => const Color(0xFF229FE3),
    ProjectImportance.normal => _brandPurple,
    ProjectImportance.high => _brandYellow,
  };
}

Color _pastelImportanceColor(ProjectImportance importance) {
  return switch (importance) {
    ProjectImportance.low => _pastelPriorityLow,
    ProjectImportance.normal => _pastelPriorityMedium,
    ProjectImportance.high => _pastelPriorityHigh,
  };
}

Color _pencilImportanceColor(ProjectImportance importance) {
  return switch (importance) {
    ProjectImportance.low => _pencilPriorityLow,
    ProjectImportance.normal => _pencilPriorityMedium,
    ProjectImportance.high => _pencilPriorityHigh,
  };
}

String _formatDate(BuildContext context, DateTime date) {
  const englishMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  const hungarianMonths = [
    'jan.',
    'febr.',
    'márc.',
    'ápr.',
    'máj.',
    'jún.',
    'júl.',
    'aug.',
    'szept.',
    'okt.',
    'nov.',
    'dec.',
  ];
  final local = date.toLocal();
  const frenchMonths = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.'
  ];
  return switch (Localizations.localeOf(context).languageCode) {
    'hu' => '${local.year}. ${hungarianMonths[local.month - 1]} ${local.day}.',
    'fr' => '${local.day} ${frenchMonths[local.month - 1]} ${local.year}',
    'cs' => '${local.day}. ${local.month}. ${local.year}',
    'de' => '${local.day}.${local.month}.${local.year}',
    'zh' => '${local.year}年${local.month}月${local.day}日',
    _ => '${local.day} ${englishMonths[local.month - 1]} ${local.year}',
  };
}

String _formatReminder(BuildContext context, DateTime date) {
  final local = date.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${_formatDate(context, local)} · $hour:$minute';
}
