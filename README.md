# Checklist 0.4.8

Checklist is a focused, local-first checklist app built with Flutter for Ubuntu
and Android. It uses the dark Boi theme by default, keeps projects one tap away,
and saves all checklist data on the device.

The approved product behaviour and visual invariants are recorded in
[`AGENTS.md`](AGENTS.md). Read that specification before modifying the app.

## What it includes

- Persistent Boi, Pencil, and Pastel themes, selected from an animated Settings
  panel alongside Language and About pages.
- Persistent English and Hungarian interface languages, including localized
  menus, dialogs, hints, tooltips, and dates.
- Versioned JSON import/export for moving checklists, tasks, reminders, notes,
  categories, and note links to a fresh installation.
- A warm-grey, monochrome light appearance with cool-grey lines, black text,
  and black checklist progress.
- A responsive sidebar with saved checklists and completion counts.
- Project sorting by newest date, oldest date, A–Z, or priority.
- Theme-specific priority colours, including dedicated Pencil greys/navy and
  Pastel red/teal/lavender controls.
- Creation dates in both the project list and selected-checklist header.
- A multiline desktop composer where **Enter** adds and **Shift+Enter** inserts
  a new line; on Android, the keyboard's **Done** action adds the task.
- Task completion, editing, and deletion, with project progress at a glance.
- Smooth checklist-progress animation and fade transitions when checklist or
  note rows are created or deleted.
- Task reprioritisation after a 140 ms hold on the text area only, with the
  checkmark and three-dot settings control kept independent and no drag handle.
- Linked-note sticky-note icons below task checkboxes that flash from blue to
  purple before opening the attached note.
- Dedicated red, teal, and lavender priority controls in the Pastel theme.
- An optional 16:9 cover image for every checklist, captured through a
  blue-framed camera preview or selected and positioned in a purple-framed crop
  window.
- A persistent calendar and time reminder attached to each checklist that
  sounds the Android system alarm at the saved time.
- Optional links from checklist tasks to existing notes, with scrollable note
  viewing directly from the task row.
- A dedicated notes workspace that fades in without replacing the sidebar.
- Locally autosaved notes with rename, delete, and category controls.
- Rendered bold, italic, and underline controls in the Notes editor, including
  an edit-and-format-only borderless selection toolbar.
- Offline Android photo-to-text for English and Hungarian notes using
  PaddleOCR, from either an existing picture or the device camera. OpenCV and
  the recognition models are bundled locally, including 16 KB-page-compatible
  Android native libraries.
- Custom note categories with names and an 18-colour palette; category colours
  carry through to note titles and category labels while note body text remains
  white for readability.
- Automatic local saving of projects, tasks, preferences, and copied cover
  images, notes, and categories. No account or network connection is required.
- Blue-framed popup windows, fast save/create feedback, and a hidden three-tap
  version and feature window in the Settings row.

## Run it on Ubuntu

### 1. Install Flutter

Install the latest stable Flutter SDK using the
[official Linux instructions](https://docs.flutter.dev/install/manual), then
make sure `flutter` is available in your terminal.

Install the Ubuntu desktop build tools:

```sh
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev libstdc++-12-dev
```

Check the installation:

```sh
flutter doctor -v
flutter devices
```

`flutter devices` should show a `linux` desktop target.

### 2. Generate the Linux runner

From this project directory, run this once:

```sh
flutter config --enable-linux-desktop
flutter create --platforms=linux .
sed -i 's/"checklist_app"/"Checklist"/g' linux/runner/my_application.cc
```

This generates Flutter's platform-owned `linux/` runner without replacing the
application code in `lib/`. The final command gives the native Ubuntu window
the user-facing title **Checklist**.

### 3. Install packages and launch

```sh
flutter pub get
flutter run -d linux
```

Flutter opens Checklist as a native Ubuntu desktop window. Changes are saved
automatically in the current user's application-data directory.

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

The Android version requires Android 8.0 or newer. It uses the same local
projects and checklist features, with a drawer-based project menu, offline
photo-to-text in Notes, and a soft-keyboard **Done** action for adding tasks.

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

## Build a Linux release

```sh
flutter test
flutter analyze
flutter build linux --release
```

The runnable application bundle is created at:

```text
build/linux/<architecture>/release/bundle/
```

On a typical 64-bit Intel/AMD Ubuntu installation, run it directly with:

```sh
./build/linux/x64/release/bundle/checklist_app
```

When sharing the application, copy the **entire** `bundle/` directory—the
executable needs the adjacent `lib/` and `data/` directories.

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

## Troubleshooting

- If Linux does not appear in `flutter devices`, rerun `flutter doctor -v` and
  resolve items under **Linux toolchain**.
- If CMake reports missing GTK headers, reinstall `libgtk-3-dev`.
- If an older generated runner causes build errors, upgrade Flutter and rerun
  `flutter create --platforms=linux .`; application files under `lib/` remain
  intact.
