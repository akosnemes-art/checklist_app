# Checklist 0.5.4

CHECKLIST is a local-first checklist and notes app for Android 8.0 or newer.

## Download

[Download the latest Android APK](https://github.com/akosnemes-art/checklist_app/releases/latest) · [Add to Obtainium](https://apps.obtainium.imranr.dev/redirect?r=obtainium%3A%2F%2Fapp%2F%257B%2522id%2522%253A%2522com.gather.checklist%2522%252C%2522url%2522%253A%2522https%253A%252F%252Fgithub.com%252Fakosnemes-art%252Fchecklist_app%2522%252C%2522author%2522%253A%2522akosnemes-art%2522%252C%2522name%2522%253A%2522CHECKLIST%2522%257D)

In Obtainium, you can also open **Add App** and paste the [repository URL](https://github.com/akosnemes-art/checklist_app).
Obtainium tracks stable GitHub releases and downloads the universal APK.

The approved product behaviour and visual invariants are recorded in
[`AGENTS.md`](AGENTS.md). Read that specification before modifying the app.

## What it includes

- Boi, Pencil, Pastel, Copper, Black Metal, Pixel, and Cyberpunk themes.
  Pixel has arcade lettering and subtle CRT noise. Cyberpunk has neon
  circuitry, glowing progress and priority controls, and cut-corner
  checklist and reminder buttons. Each theme can be customised with colour
  swatches and hue, saturation, and value sliders. Saved Glass selections
  move to Pencil.
- Persistent English, Hungarian, French, Czech, German, and Simplified Chinese
  interface languages,
  including localized menus, dialogs, hints, tooltips, dates, and Android
  reminder notifications.
- Versioned JSON import/export for moving checklists, tasks, reminders, notes,
  categories, and note links to a fresh installation.
- A warm-grey, monochrome light appearance with cool-grey lines, black text,
  and black checklist progress.
- A responsive sidebar with saved checklists and completion counts.
- Project sorting by newest date, oldest date, A–Z, or priority.
- Theme-specific priority colours, including dedicated Pencil greys/navy and
  Pastel red/teal/lavender controls.
- Creation dates in both the project list and selected-checklist header.
- The soft keyboard’s **Done** action adds the task.
- Task completion, editing, and deletion, with project progress at a glance.
- Smooth checklist-progress animation and fade transitions when checklist or
  note rows are created or deleted. Selected checklist and note content fades
  in from top to bottom.
- Task reprioritisation after a 140 ms hold on the text area only, with the
  checkmark and three-dot settings control kept independent and no drag handle.
- Linked-note icons below task checkboxes are yellow in Boi and blue in Pencil
  and Pastel. They flash purple before opening the attached note.
  All task checkboxes share the same alignment.
- Dedicated red, teal, and lavender priority controls in the Pastel theme.
- An optional 16:9 cover image for every checklist, captured through a
  blue-framed camera preview or selected and positioned in a purple-framed crop
  window.
- A persistent calendar and time reminder attached to each checklist that
  sounds the Android system alarm at the saved time.
- Optional links from checklist tasks to existing notes, with formatted
  previews in the chooser and clickable links in the scrollable note window.
- A dedicated notes workspace that fades in without replacing the sidebar.
- Locally autosaved notes with rename, delete, and category controls.
- Independent bold, italic, and underline controls beside the note category,
  plus an edit-and-format-only borderless selection toolbar. Tapping elsewhere
  exits note edit mode while formatting buttons keep the editor active.
- Tap an underlined link outside note edit mode to open it in the default
  browser or the app registered for the link. Links are yellow in Boi,
  light blue in Pencil, and deep blue in Pastel.
- Android edge-to-edge rendering extends each active theme behind the gesture
  indicator without a white strip, while safe-area handling keeps the checklist
  composer and drawer settings above gesture and three-button navigation.
- The Android launcher uses the updated safe CHECKLIST logo from
  `Checklist_app_icon_safe.png` for legacy and adaptive icons.
- Create-note windows follow the writing surface and frame of the current
  theme. Dialog frames draw before their contents fade in.
- Offline Android photo-to-text for English and Hungarian notes using
  PaddleOCR, from either an existing picture or the device camera. Imported
  text retains detected bold, italic, and underline as editable formatting. The camera
  previews for Notes and checklist covers can switch lenses and show detected
  text and QR links. The Notes camera can open links directly from the live
  preview. Links from a captured note photo become tappable in the note.
  OpenCV and the recognition models are bundled locally, including
  16 KB-page-compatible Android native libraries.
- Custom note categories with names and an 18-colour palette; category colours
  carry through to note titles and category labels while note body text remains
  white for readability.
- Automatic local saving of projects, tasks, preferences, and copied cover
  images, notes, and categories. When the selected note has a website link,
  the globe beside its formatting controls opens the gallery of saved links.
  The app captures screenshots online using Android WebView. Notes and OCR
  remain available offline.
- About credits Ákos Nemes for the design. Its Credits button opens a rolling
  list with the designer's contact, developer credit, and photographer's portfolio.
- Fast save/create feedback, the public version below the Settings row, and a
  hidden three-tap version and feature window in that row.

## Run it on Android

Install the latest stable Android Studio, then use its SDK Manager to install
the Android SDK, command-line tools, platform tools, build tools, and an
emulator. Accept the SDK licences and verify the toolchain:

```sh
flutter doctor --android-licenses
flutter doctor -v
flutter devices
```

Start an Android emulator from Android Studio's Device Manager, or connect an
Android phone with Developer options and USB debugging enabled. Then run:

```sh
flutter pub get
flutter run -d <android-device-id>
```

## Build an Android APK

For a locally installable release APK:

```sh
flutter build apk --release
python3 tool/check_android_elf_alignment.py build/app/outputs/flutter-apk/app-release.apk
```

The APK is created at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

For Google Play, configure a private release signing key first, then build the
preferred Android App Bundle format with `flutter build appbundle`.

## Publish an update

Publish a stable GitHub release with a tag such as `v0.5.4` and attach one
universal `checklist-<version>-android.apk`. Increment the Android build
number and sign each update with the certificate used for the previous APK.
Use a tag such as `v0.5.3-build45` for a new build of the same public version.
The current GitHub APK uses the project's Android debug certificate.

## Project structure

```text
lib/
  main.dart                         App shell, interface, and interactions
  models/checklist_project.dart     Project and task data models
  models/note.dart                  Note and note-category data models
  services/local_store.dart         Local persistence and cover-image storage
  services/ocr_service.dart         Android offline OCR bridge
test/
  checklist_project_test.dart       Model serialization checks
  note_test.dart                    Note serialization and persistence checks
  notepad_widget_test.dart          Notepad interaction and colour-flow checks
```
