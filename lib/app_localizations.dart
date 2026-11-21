import 'package:flutter/material.dart';

enum AppLanguage { english, hungarian }

extension AppLanguageDetails on AppLanguage {
  Locale get locale => Locale(this == AppLanguage.hungarian ? 'hu' : 'en');
}

const _hungarian = <String, String>{
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
  'Added dedicated high, medium, and low priority colours to Pastel.': 'A Pastel téma külön magas, közepes és alacsony prioritásszíneket kapott.',
  'Aligned the sidebar mode checkmark with its wordmark.':
      'Az oldalsáv módjelölő pipája a felirathoz igazodik.',
  'Moved linked-note icons below their task checkboxes.':
      'A csatolt jegyzet ikonja a feladat jelölőnégyzete alá került.',
  'Added dedicated Pencil priority colours.':
      'A Pencil téma külön prioritásszíneket kapott.',
  'Made note formatting render bold, italic, and underlined text.':
      'A jegyzetformázás félkövér, dőlt és aláhúzott szöveget jelenít meg.',
  'Added a borderless selection toolbar with editing and formatting actions.': 'Keret nélküli kijelölési eszköztár került be szerkesztési és formázási műveletekkel.',
  'open linked note': 'csatolt jegyzet megnyitása',
};

String localizeText(BuildContext context, String text) {
  if (Localizations.localeOf(context).languageCode != 'hu') return text;
  final exact = _hungarian[text];
  if (exact != null) return exact;

  if (text.endsWith(' done')) {
    return '${text.substring(0, text.length - 5)} kész';
  }
  if (text.startsWith('build ')) return text;
  if (text.startsWith('“') && text.endsWith('” will be removed.')) {
    final name = text.substring(1, text.length - '” will be removed.'.length);
    return 'A(z) „$name” jegyzet törölve lesz.';
  }
  if (text.startsWith('“') &&
      text.endsWith('” and its tasks will be removed.')) {
    final name = text.substring(
      1,
      text.length - '” and its tasks will be removed.'.length,
    );
    return 'A(z) „$name” lista és feladatai törölve lesznek.';
  }
  if (text.startsWith('You are using CHECKLIST version ')) {
    return text
        .replaceFirst('You are using', 'A használt alkalmazás:')
        .replaceFirst('Designed by', 'Tervezte:')
        .replaceFirst('using Codex AI', 'a Codex AI használatával');
  }
  final replacement = RegExp(
    r'^Replace this installation with (\d+) checklist\(s\) and (\d+) note\(s\)\?$',
  ).firstMatch(text);
  if (replacement != null) {
    return 'Lecseréled a telepítés adatait ${replacement.group(1)} listára '
        'és ${replacement.group(2)} jegyzetre?';
  }
  const errorPrefixes = <String, String>{
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
  for (final entry in errorPrefixes.entries) {
    if (text.startsWith(entry.key)) {
      return '${entry.value}${text.substring(entry.key.length)}';
    }
  }
  return text;
}

class AppText extends StatelessWidget {
  // The visible Text owns the supplied key so existing widget contracts keep
  // pointing at the rendered text rather than this localization wrapper.
  // ignore: use_key_in_widget_constructors
  const AppText(
    this.data, {
    Key? key,
    this.style,
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
      localizeText(context, data),
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
