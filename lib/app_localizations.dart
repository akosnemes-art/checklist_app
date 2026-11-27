import 'package:flutter/material.dart';

part 'app_translations.dart';
part 'app_translations_de_zh.dart';

enum AppLanguage {
  english('en', 'English'),
  hungarian('hu', 'Hungarian'),
  french('fr', 'French'),
  czech('cs', 'Czech'),
  german('de', 'German'),
  chinese('zh', 'Simplified Chinese');

  const AppLanguage(this.code, this.label);
  final String code;
  final String label;
  Locale get locale => Locale(code);
}

const welcomeMessage = 'You are using CHECKLIST version {version} '
    '(build {build}).\n\nDesigned by Ákos Nemes using Codex AI.';

const _hungarian = <String, String>{
  "Task controls align with their rows, with refined Cyberpunk, Pixel and Pastel styling.":
      "A feladatok vezérlői a sorokhoz igazodnak, a Cyberpunk, Pixel és Pastel megjelenése finomodott.",
  "Updated the launcher icon to show version 0.5.6.":
      "Az alkalmazásikonon most a 0.5.6-os verzió látható.",
  "- note": "- jegyzet",
  "Added a task menu action to unlink notes.":
      "A feladatmenüből leválaszthatók a jegyzetek.",
  "Pixel and Cyberpunk have new control and background effects.":
      "A Pixel és a Cyberpunk új gomb- és háttéreffekteket kapott.",
  "Pastel has rounded, softly raised surfaces and new fonts.":
      "A Pastel lekerekített, finoman kiemelt felületeket és új betűtípusokat kapott.",
  "Cyberpunk has layered popups, fine grain and softly glowing edges.":
      "A Cyberpunk felugró ablakai rétegenként nyílnak meg, a felületek finoman szemcsézettek, a szélek pedig lágyan világítanak.",
  "Cyberpunk has glowing yellow borders and Pastel has raised panels and Nunito text.":
      "A Cyberpunk keretei sárgán világítanak, a Pastel kiemelt paneleket és Nunito betűtípust kapott.",
  "Cyberpunk adds a blue cut-corner new-note button.":
      "A Cyberpunk új jegyzet gombja kék színt és levágott sarkot kapott.",
  "Cyberpunk progress glows on the yellow fill.":
      "A Cyberpunk folyamatjelző sárga része világít.",
  "Theme backgrounds reach the system bars, and the launcher icon is updated.":
      "A témák háttere a rendszersávok mögé ér, és megújult az alkalmazásikon.",
  "Cyberpunk opens directly and adds neon progress and priority controls.":
      "A Cyberpunk azonnal elindul, és világító folyamatjelzőt és prioritásgombokat kapott.",
  "Reduced top spacing and removed the Glass theme.":
      "Csökkent a felső térköz, a Glass téma megszűnt.",
  "Moved the website globe beside the Notes formatting controls.":
      "A webhelyek földgömbje a jegyzetformázó gombok mellé került.",
  "Added the Cyberpunk theme with photography by Allan Ferreira.":
      "Új Cyberpunk téma Allan Ferreira fényképével.",
  "Added rolling credits in About and updated the launcher icon.":
      "A Névjegy gördülő stáblistát kapott, és megújult az alkalmazásikon.",
  "designed by {name}": "tervezte: {name}",
  "credits": "stáblista",
  "design": "tervezés",
  "development": "fejlesztés",
  "original Cyberpunk photography": "A Cyberpunk eredeti háttérfotója",
  "view portfolio": "portfólió megtekintése",
  "Notes extend to the status bar and use a solid writing surface.":
      "A Jegyzetek háttere az állapotsávig ér, az írófelület pedig egyszínű.",
  "Pixel has CRT noise and theme changes draw from bottom to top.":
      "A Pixel témában megjelenik a CRT-zaj, témaváltáskor az elemek alulról felfelé rajzolódnak ki.",
  "The version fades out when Settings opens.":
      "A Beállítások megnyitásakor a verziószám elhalványul.",
  "Added the Pixel and Glass themes.": "Új Pixel és Glass témák.",
  "Added separate colour customisation for each theme.":
      "A témák színei külön-külön testreszabhatók.",
  "customise": "testreszabás",
  "customise colours": "színek testreszabása",
  "reset colours": "színek visszaállítása",
  "app background": "alkalmazás háttere",
  "panels and fields": "panelek és mezők",
  "sidebar": "oldalsáv",
  "text": "szöveg",
  "buttons": "gombok",
  "borders": "keretek",
  "checklist accent": "ellenőrzőlista kiemelése",
  "notes accent": "jegyzetek kiemelése",
  "note links": "jegyzethivatkozások",
  "low priority": "alacsony prioritás",
  "medium priority": "közepes prioritás",
  "high priority": "magas prioritás",
  "hue": "árnyalat",
  "saturation": "telítettség",
  "value": "fényesség",
  "could not save theme colours": "Nem sikerült menteni a téma színeit.",
  'Gave Black Metal blood-red controls and a faster steel glint.':
      'A Black Metal vérvörös gombokat és gyorsabb fémes felvillanást kapott.',
  'Added Black Metal with distressed panels and a soft moving shine.':
      'Az új Black Metal témában koptatott panelek és finoman mozgó fények jelennek meg.',
  'Renamed Goth to Copper and removed the circular artwork.':
      'A Goth téma új neve Copper, a kör alakú díszítés eltűnt.',
  'Photo imports preserve detected bold, italic, and underlined text.':
      'A fényképek importálása megőrzi a felismert félkövér, dőlt és aláhúzott szöveget.',
  'The launcher icon lettering is centred.':
      'Az alkalmazásikon felirata középre került.',
  'German': 'Német',
  'Simplified Chinese': 'Egyszerűsített kínai',
  'website links': 'webhelyhivatkozások',
  'no website links yet': 'még nincsenek webhelyhivatkozások',
  'loading preview…': 'előnézet betöltése…',
  'preview unavailable': 'az előnézet nem érhető el',
  'Popup frames draw in before their contents fade in.':
      'Az ablakok kerete a tartalom megjelenése előtt rajzolódik ki.',
  'Linked notes show formatting and open hyperlinks.':
      'A csatolt jegyzetekben látható a formázás, a hivatkozások megnyithatók.',
  'Saved note links can be browsed with website screenshots.':
      'A jegyzetek hivatkozásai webhely-előnézetekkel böngészhetők.',
  'German and Simplified Chinese are available.':
      'A német és az egyszerűsített kínai elérhető.',
  '+ note': '+ jegyzet',
  'Add a cover image': 'Borítókép hozzáadása',
  'Backup exported successfully.': 'A biztonsági mentés elkészült.',
  'Backup imported successfully.': 'A biztonsági mentés importálva.',
  'Boi': 'Boi',
  'Cancel': 'Mégse',
  'CHECKLIST': 'CHECKLIST',
  'Checklist name': 'Lista neve',
  'Delete': 'Törlés',
  'Delete checklist?': 'Törlöd a listát?',
  'Edit task': 'Feladat szerkesztése',
  'English': 'Angol',
  'Hungarian': 'Magyar',
  'Makers: Ákos Nemes · Codex AI': 'Készítők: Ákos Nemes · Codex AI',
  'NOTES': 'NOTES',
  'Pastel': 'Pastel',
  'Pencil': 'Pencil',
  'Remove cover image': 'Borítókép eltávolítása',
  'Rename checklist': 'Lista átnevezése',
  'Set priority': 'Prioritás beállítása',
  'Task details': 'Feladat részletei',
  'Task options': 'Feladat beállításai',
  'This cover image is no longer available.':
      'Ez a borítókép már nem érhető el.',
  'Try again': 'Újra',
  'YOUR CHECKLISTS': 'LISTÁID',
  'YOUR NOTES': 'JEGYZETEID',
  'Your checklists could not be loaded.': 'A listákat nem sikerült betölteni.',
  'about': 'névjegy',
  'add a task…': 'feladat hozzáadása…',
  'add a task…  (enter to add · shift+enter for a new line)':
      'feladat hozzáadása…  (Enter: hozzáadás · Shift+Enter: új sor)',
  'add picture': 'kép hozzáadása',
  'add text from a picture': 'szöveg hozzáadása képről',
  'a–z': 'a–z',
  'backup': 'biztonsági mentés',
  'bold': 'félkövér',
  'browse': 'tallózás',
  'build': 'build',
  'camera': 'kamera',
  'cancel': 'mégse',
  'category': 'kategória',
  'category name': 'kategória neve',
  'category settings': 'kategóriabeállítások',
  'category · a–z': 'kategória · a–z',
  'change category': 'kategória módosítása',
  'change reminder': 'emlékeztető módosítása',
  'checklist name': 'lista neve',
  'checklist options': 'lista beállításai',
  'choose a checklist': 'válassz egy listát',
  'choose your cover': 'válassz borítóképet',
  'close': 'bezárás',
  'close settings': 'beállítások bezárása',
  'colour': 'szín',
  'continue': 'tovább',
  'create': 'létrehozás',
  'current': 'jelenlegi',
  'date · newest': 'dátum · legújabb',
  'date · oldest': 'dátum · legrégebbi',
  'delete': 'törlés',
  'delete note?': 'Törlöd a jegyzetet?',
  'done': 'kész',
  'drag to move • pinch or scroll to zoom':
      'húzd a mozgatáshoz • csippents vagy görgess a nagyításhoz',
  'edit': 'szerkesztés',
  'edit category': 'kategória szerkesztése',
  'empty note': 'üres jegyzet',
  'export': 'exportálás',
  'export data': 'adatok exportálása',
  'features': 'funkciók',
  'high': 'magas',
  'implemented changes': 'megvalósított változtatások',
  'import': 'importálás',
  'import / export': 'importálás / exportálás',
  'import data': 'adatok importálása',
  'italic': 'dőlt',
  'language': 'nyelv',
  'link a note': 'jegyzet csatolása',
  'link detected': 'hivatkozás észlelve',
  'low': 'alacsony',
  'make a note': 'jegyzet készítése',
  'medium': 'közepes',
  'maximize or restore': 'maximalizálás vagy visszaállítás',
  'minimize': 'minimalizálás',
  'new': 'új',
  'new category': 'új kategória',
  'new checklist': 'új lista',
  'new note': 'új jegyzet',
  'no categories yet': 'még nincs kategória',
  'no category': 'nincs kategória',
  'no notes yet': 'még nincs jegyzet',
  'note name': 'jegyzet neve',
  'note options': 'jegyzet beállításai',
  'open menu': 'menü megnyitása',
  'open settings': 'beállítások megnyitása',
  'past reminder': 'elmúlt emlékeztető',
  'priority · high first': 'prioritás · magas elöl',
  'QR link detected': 'QR-hivatkozás észlelve',
  'read less': 'kevesebb',
  'read more': 'tovább',
  'reminder': 'emlékeztető',
  'remove': 'eltávolítás',
  'remove category': 'kategória eltávolítása',
  'rename': 'átnevezés',
  'rename note': 'jegyzet átnevezése',
  'save': 'mentés',
  'settings': 'beállítások',
  'set reminder': 'emlékeztető beállítása',
  'sort checklists': 'listák rendezése',
  'sort notes': 'jegyzetek rendezése',
  'start writing…': 'kezdj írni…',
  'switch to back camera': 'váltás a hátlapi kamerára',
  'switch to front camera': 'váltás az előlapi kamerára',
  'take a photo': 'fénykép készítése',
  'take photo': 'fénykép készítése',
  'themes': 'témák',
  'this note is empty': 'ez a jegyzet üres',
  'underline': 'aláhúzott',
  'upcoming reminder': 'közelgő emlékeztető',
  'use crop': 'kivágás használata',
  'welcome to CHECKLIST': 'üdv a CHECKLIST alkalmazásban',
  'your list starts here': 'a listád itt kezdődik',
  'Added animated checklist progress and sidebar entry transitions.':
      'Animált lista-előrehaladás és oldalsávi átmenetek.',
  'Added Hungarian language support across the interface.':
      'Magyar nyelvi támogatás az egész felületen.',
  'Added portable checklist and note import/export.':
      'Hordozható lista- és jegyzetimportálás/exportálás.',
  'Improved the task checkmark touch target.':
      'Nagyobb és könnyebben érinthető feladatjelölő.',
  'Moved 140 ms task reordering onto the text area only.':
      'A 140 ms-os feladatrendezés csak a szövegterületen működik.',
  'Made the sticky-note icon open linked notes after a blue-to-purple cue.':
      'A cetliikon kékből lilára vált, majd megnyitja a csatolt jegyzetet.',
  'Added dedicated high, medium, and low priority colours to Pastel.':
      'A Pastel téma külön magas, közepes és alacsony prioritásszíneket kapott.',
  'Aligned the sidebar mode checkmark with its wordmark.':
      'Az oldalsáv módjelölő pipája a felirathoz igazodik.',
  'Moved linked-note icons below their task checkboxes.':
      'A csatolt jegyzet ikonja a feladat jelölőnégyzete alá került.',
  'Added dedicated Pencil priority colours.':
      'A Pencil téma külön prioritásszíneket kapott.',
  'Made note formatting render bold, italic, and underlined text.':
      'A jegyzetformázás félkövér, dőlt és aláhúzott szöveget jelenít meg.',
  'Added a borderless selection toolbar with editing and formatting actions.':
      'Keret nélküli kijelölési eszköztár került be szerkesztési és formázási műveletekkel.',
  'Kept bottom controls above Android system navigation bars.':
      'Az alsó vezérlők az Android rendszernavigációs sávja fölött maradnak.',
  'Aligned linked-task checkboxes with every other task checkbox.':
      'A csatolt jegyzetes feladatok jelölőnégyzetei a többihez igazodnak.',
  'Made Notes leave edit mode when tapping outside the editor.':
      'A Jegyzetek kilép a szerkesztési módból, ha a szerkesztőn kívülre koppintasz.',
  'Changed the rename-note window to pale pastel blue.':
      'A jegyzetátnevező ablak halvány pasztellkék lett.',
  'Updated the Android launcher icon with the new safe CHECKLIST logo.':
      'Az Android indítóikon az új, biztonságos CHECKLIST logót használja.',
  'Extended app backgrounds behind gesture navigation while keeping controls safe.':
      'Az alkalmazás háttere a gesztusnavigáció mögé is kinyúlik, a vezérlők pedig biztonságos helyen maradnak.',
  'Removed the white strip beneath the sidebar at the gesture navigation area.':
      'Eltűnt az oldalsáv alatti fehér csík a gesztusnavigáció területéről.',
  'Notes open links in the default browser or an installed app.':
      'A jegyzetek az alapértelmezett böngészőben vagy egy telepített alkalmazásban nyitják meg a hivatkozásokat.',
  'Website addresses recognised in photos become tappable links.':
      'A fotókon felismert webcímek megnyitható hivatkozásokká válnak.',
  'Could not open that link.': 'Nem sikerült megnyitni a hivatkozást.',
  'open linked note': 'csatolt jegyzet megnyitása',
  'French': 'Francia',
  'Czech': 'Cseh',
  'create a note from the sidebar': 'hozz létre jegyzetet az oldalsávból',
  'reminder time': 'emlékeztető időpontja',
  'No text was found in that image.': 'A képen nem található szöveg.',
  'Text added to your note.': 'A szöveg bekerült a jegyzetbe.',
  'Could not recognise that image.':
      'A képen lévő szöveget nem sikerült felismerni.',
  'Photo text is available on Android.': 'A képfelismerés Androidon érhető el.',
  'Could not save language setting:':
      'A nyelvi beállítást nem sikerült menteni:',
  'Could not save the theme setting:': 'A témát nem sikerült menteni:',
  'Could not add that image:': 'A képet nem sikerült hozzáadni:',
  'Could not take that photo:': 'A fényképet nem sikerült elkészíteni:',
  'Could not load your checklists:': 'A listákat nem sikerült betölteni:',
  'Cover updated, but the old image could not be removed.':
      'A borító frissült. A korábbi képet nem sikerült eltávolítani.',
  'No camera is available.': 'Nem érhető el kamera.',
  'No picture picker is available.': 'Nem érhető el képválasztó.',
  'Another image is already being processed.':
      'Egy másik kép feldolgozása folyamatban van.',
  'Choose a picture or take a photo.':
      'Válassz egy képet vagy készíts fényképet.',
  'The selected image could not be opened.':
      'A kiválasztott képet nem sikerült megnyitni.',
  'The selected picture could not be opened.':
      'A kiválasztott képet nem sikerült megnyitni.',
  'The selected image is no longer available.':
      'A kiválasztott kép már nem érhető el.',
  'The selected image is empty.': 'A kiválasztott kép üres.',
  'The image is empty.': 'A kép üres.',
  'The camera photo could not be opened.':
      'A fényképet nem sikerült megnyitni.',
  'The camera photo is no longer available.': 'A fénykép már nem érhető el.',
  'The image import was interrupted.': 'A kép importálása megszakadt.',
  'Choose an image smaller than 40 MB.': 'Válassz 40 MB-nál kisebb képet.',
  'The selected image format could not be read.':
      'A kiválasztott kép formátuma nem olvasható.',
  'The offline image reader could not start.':
      'Az offline képfelismerést nem sikerült elindítani.',
  'Could not turn that image into text.':
      'A képet nem sikerült szöveggé alakítani.',
  'Camera permission is needed to take a cover photo.':
      'A borítóképhez engedélyezd a kamera használatát.',
  'Camera permission is needed to take a photo.':
      'A fénykép készítéséhez engedélyezd a kamera használatát.',
  'The camera could not be opened.': 'A kamerát nem sikerült megnyitni.',
  'The crop is not ready.': 'A kivágás még nincs készen.',
  'The crop could not be saved.': 'A kivágást nem sikerült menteni.',
  'The backup file is empty.': 'A biztonsági mentés fájlja üres.',
  'This is not a supported CHECKLIST backup.':
      'Ez a CHECKLIST biztonsági mentés nem támogatott.',
  '{date}  ·  {done}/{tasks} done': '{date}  ·  {done}/{tasks} kész',
  '{date}  ·  {tasks} task  ·  {done} completed':
      '{date}  ·  {tasks} feladat  ·  {done} kész',
  '{date}  ·  {tasks} tasks  ·  {done} completed':
      '{date}  ·  {tasks} feladat  ·  {done} kész',
  '“{name}” will be removed.': 'A(z) „{name}” jegyzet törölve lesz.',
  '“{name}” and its tasks will be removed.':
      'A(z) „{name}” lista és feladatai törölve lesznek.',
  'Replace this installation with {checklists} checklist(s) and {notes} note(s)?':
      'Lecseréled a telepítés adatait {checklists} listára és {notes} jegyzetre?',
  welcomeMessage: 'A használt alkalmazás: CHECKLIST version {version} '
      '(build {build}).\n\nTervezte: Ákos Nemes a Codex AI használatával.',
  'Selected checklist and note content now fades in from top to bottom.':
      'A kiválasztott listák és jegyzetek tartalma felülről lefelé jelenik meg.',
  'Updated dropdown frames and Pastel note selection and links.':
      'Frissültek a legördülő menük keretei, valamint a Pastel téma jegyzetkijelölései és hivatkozásai.',
  'Note formatting can be combined and toggled from the right side of the category row.':
      'A jegyzetformázás kombinálható és a kategóriasor jobb oldalán kapcsolható.',
  'Settings text lights up when pressed, and French and Czech are available.':
      'A beállítások feliratai megnyomáskor felvillannak, és elérhető a francia és a cseh nyelv.',
  'Could not clean up the cover image:':
      'A borítóképet nem sikerült eltávolítani:',
  'Could not export your data:': 'Az adatokat nem sikerült exportálni:',
  'Could not import that backup:':
      'A biztonsági mentést nem sikerült importálni:',
  'Could not recognise that image:': 'A képet nem sikerült felismerni:',
  'Could not remember that note:': 'A jegyzetet nem sikerült megjegyezni:',
  'Could not remember that selection:':
      'A kijelölést nem sikerült megjegyezni:',
  'Could not save changes:': 'A módosításokat nem sikerült menteni:',
  'Could not save note categories:':
      'A jegyzetkategóriákat nem sikerült menteni:',
  'Could not save the heart animation:':
      'A szívanimációt nem sikerült menteni:',
  'Could not save the note sort order:':
      'A jegyzetrendezést nem sikerült menteni:',
  'Could not save the sort order:': 'A rendezést nem sikerült menteni:',
  'Could not save your notes:': 'A jegyzeteket nem sikerült menteni:',
};

String? _translation(String language, String text) => switch (language) {
      'hu' => _hungarian[text],
      'fr' => _frenchAndCzech[text]?.$1,
      'cs' => _frenchAndCzech[text]?.$2,
      'de' => _germanAndChinese[text]?.$1,
      'zh' => _germanAndChinese[text]?.$2,
      _ => null,
    };

final _argument = RegExp(r'\{([a-z]+)\}');

String localizeText(BuildContext context, String text,
    [Map<String, Object> arguments = const {}]) {
  final language = Localizations.localeOf(context).languageCode;
  final exact = _translation(language, text);
  if (arguments.isNotEmpty) {
    return (exact ?? text).replaceAllMapped(
      _argument,
      (part) => arguments[part[1]]?.toString() ?? part[0]!,
    );
  }
  if (exact != null) return exact;
  if (language == 'en') return text;

  // Translate the app's error summary and retain an unrecognised diagnostic.
  final separator = text.indexOf(': ');
  if (separator < 0) return text;
  final summary = _translation(language, text.substring(0, separator + 1));
  final detail = text.substring(separator + 2);
  if (summary != null) return '$summary ${localizeText(context, detail)}';
  return switch (text.substring(0, separator)) {
    'Bad state' || 'FormatException' => _translation(language, detail) ?? text,
    _ => text,
  };
}

class AppText extends StatelessWidget {
  // The visible Text owns the supplied key so existing widget contracts keep
  // pointing at the rendered text rather than this localization wrapper.
  // ignore: use_key_in_widget_constructors
  const AppText(
    this.data, {
    Key? key,
    this.style,
    this.arguments = const {},
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.semanticsIdentifier,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : textKey = key;

  final String data;
  final Map<String, Object> arguments;
  final Key? textKey;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final String? semanticsIdentifier;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      localizeText(context, data, arguments),
      key: textKey,
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel == null
          ? null
          : localizeText(context, semanticsLabel!),
      semanticsIdentifier: semanticsIdentifier,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}
