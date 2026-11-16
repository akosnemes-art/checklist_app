# CHECKLIST project specification

This file is the product contract for this repository. Every future coding
session must read it before changing the app. It records behaviour and visual
choices already approved by the user. Do not redesign, recolour, remove, rename,
or relocate an established element unless the user explicitly requests that
specific change.

When a requested change appears to conflict with this file, explain the
conflict and ask the user before altering the existing behaviour. A change in
one mode must not accidentally restyle the other mode. Add or update a
regression test for every approved visual or interaction change.

## Product identity and release policy

- Product name: **CHECKLIST**.
- Current public version: **0.4.3**. The Flutter build number may increase for
  rebuilt APKs, but the public version must not change without explicit user
  approval.
- Android application ID: `com.gather.checklist`.
- Designed by **Ákos Nemes using Codex AI**.
- The welcome dialog appears once per installation and again whenever the
  public version or internal build number changes. It states the public
  version, build number, and design credit. Its purple `read more` text expands
  the dialog with the implemented changes.
- Primary platforms are Android and Ubuntu/Linux, built with Flutter.
- The app is local-first. Checklists, tasks, notes, categories, preferences,
  selections, and cover-image references are stored locally. Do not introduce
  accounts, cloud storage, analytics, or network requirements unless requested.

## Non-negotiable visual invariants

These details have already been approved and must not change incidentally:

- Square corners are used throughout buttons, fields, dialogs, menus, chips,
  drawers, snackbars, and window chrome.
- `CHECKLIST` and `NOTES` form one wordmark in the same font. There is no
  chromatic-aberration text effect. A checkmark appears immediately beside the
  selected mode, glitches when the selection changes, and performs a subtle
  ambient glitch at a random interval between 10 and 20 seconds.
- The active word is white; the inactive word is grey. Switching modes fades
  all affected UI except the drawer/sidebar opening animation itself.
- Checklist mode uses purple; Notes mode uses blue.
- The checklist completion progress bar is always brand yellow
  (`#F3ED23`). It must never inherit the purple or blue theme primary colour.
- Checklist priorities are: low blue (`#229FE3`), normal purple
  (`#922FD0`), and high yellow (`#F3ED23`).
- The task-composer placeholder beginning `add a task…` is grey (`#9AA0AA`).
- The note-editor placeholder `start writing…` is grey (`#9AA0AA`) and typed
  note body text is white (`#F8F7FF`).
- Note-category colour affects the note title, category label, list indicator,
  and selected-row treatment. It does not recolour the note body text.
- White frames are intentional around the create-note button, filter/sort
  button, and category selector.
- Every three-dot settings button is intentionally unframed and uses a vertical
  ellipsis. Do not restore horizontal dots or frames around these buttons.
- The Notes filter button and `new note` button have exactly the same height.
- There are no static decorative hearts in the sidebar.

### Canonical palette

| Role | Value |
| --- | --- |
| Dark app background | `#0D0912` |
| Dark surface | `#17101F` |
| Brand purple | `#922FD0` |
| Brand cyan | `#05E1E6` |
| Brand magenta | `#F000E6` |
| Brand yellow / checklist progress | `#F3ED23` |
| Border and body-text white | `#F8F7FF` |
| Dark checklist sidebar | `#26102F` |
| Light checklist sidebar | `#6B3A7D` |
| Dark Notes sidebar | `#0B1D3B` |
| Light Notes sidebar | `#315B88` |
| Deep-blue button | `#1553A3` |
| Default note blue | `#5A9BFF` |
| Placeholder / light-mode switch grey | `#9AA0AA` |

The 18 category colours are defined once in `_noteColours` in
`lib/main.dart`. Preserve their order because tests and saved user choices may
rely on the palette positions.

## Checklist mode

- The dark sidebar is deep purple and the light sidebar is lighter purple.
- The top action is `new checklist` with the checklist sort button beside it.
- The section label is `YOUR CHECKLISTS` with the current checklist count.
- Only checklist entries are visible in the sidebar while this mode is active.
- Checklist sorting supports newest, oldest, A–Z, and priority.
- A new installation creates `my first checklist` if no project exists.
- Each checklist shows its creation date, completion count, and priority.
- The selected checklist supports rename, delete, priority changes, optional
  cover image, reminder date/time, task creation, task editing, task deletion,
  and completion.
- The selected checklist shows a purple-framed calendar reminder button. It
  opens a calendar and time picker; a saved reminder stays attached to that
  checklist and can be changed or removed. The checklist sidebar three-dot
  menu includes the lowercase `reminder` action.
- On Android, a saved future reminder is scheduled as an exact system alarm.
  It sounds the device alarm tone even when the Flutter UI is not open, shows
  an ongoing alarm notification with a stop action, and is restored after a
  device restart.
- The reminder dialog keeps `cancel`, `remove`, and `save` on one horizontal
  row. The removal label is `remove`, not `remove reminder`.
- Checklist rows with reminders show a small bell beside the checklist name.
  The bell is centred beside and close to the settings dots. Upcoming reminder
  bells are white; bells for past reminders are grey.
- Pressing `Add a cover image` opens a small dropdown with `camera` and
  `browse`. The camera preview has a blue frame and uses the same 16:9 aspect
  ratio as the saved checklist cover. Browsed images open a local crop window;
  its purple frame marks the 16:9 area that will be saved, and the image can be
  moved and zoomed beneath it.
- The cover-image remove X is shown for two seconds, then fades out. Tapping
  the cover reveals it again for another two seconds before the next fade.
- Task-entry settings use an unframed vertical ellipsis. The menu labels
  `edit` and `delete` are lowercase, and `+ note` links an existing note to the
  task.
- A linked task shows a blue note icon beside its left-aligned checkbox. Its
  text wraps within the remaining row width, and tapping the task text opens
  the linked note in a scrollable popup window.
- The selected checklist header includes its creation date and task counts.
- When tasks exist, their completion progress is shown with the fixed yellow
  progress bar. The track may follow the current theme divider colour.
- On desktop, Enter adds a task and Shift+Enter inserts a newline. On Android,
  the soft-keyboard Done action adds the task. The Android placeholder is only
  `add a task…`, without a parenthetical Done instruction.
- The empty checklist message is `your list starts here`.

## Notes mode

- The sidebar remains open when switching between Checklist and Notes modes.
- The sidebar fades from purple to deep blue in dark mode and to the approved
  lighter blue in light mode.
- The top action changes to blue `new note`; the adjacent Notes filter/sort
  control remains the same height.
- The section label becomes `YOUR NOTES` and shows the note count.
- Only note entries are shown in the sidebar while Notes mode is active.
- Note sorting supports newest, oldest, A–Z, and category A–Z.
- A note list entry uses its category colour (or default note blue), shows its
  creation date, and receives a category-coloured selected treatment.
- The sidebar note-row menu uses an unframed vertical ellipsis and offers
  rename, delete, and category settings.
- The main Notes workspace deliberately has no `notes` heading, no `make a
  note` button, and no hamburger/sidebar button.
- On mobile, the drawer is opened with a left-edge swipe. Switching modes or
  selecting an entry must not automatically close an already-open drawer.
- The note page is expanded and shows, in order: note name, creation date,
  category, then the large writing field.
- Note content autosaves locally after a short debounce.
- Create-note and rename-note dialogs use the blue theme, white frames, and a
  category selector.
- The note-header category button opens category assignment. The adjacent
  unframed vertical-ellipsis menu offers rename, delete, and category settings.
- On Android, a square white-framed `+` button sits between the note category
  and three-dot buttons. Its menu offers `add picture` and `take a photo`.
  PaddleOCR turns the selected image into editable note text in English or
  Hungarian entirely offline and inserts it at the current editor selection.

### Category management

- Categories have a stable ID, editable name, and one colour from the approved
  18-colour palette.
- Category settings are available from both note three-dot menus.
- Editing a category can change both its name and colour without breaking note
  assignments.
- The normal change-category popup has `cancel`, `new`, and `remove` on one
  horizontal row in that order. Cancel has a blue frame, transparent
  background, and grey text. New and remove are blue buttons with white frames
  and white text.
- Pressing `remove` changes colour dots into square selection boxes.
- Selecting a category shows a checkmark, crosses out its name, waits one
  second, then removes it from the popup.
- Notes assigned to a removed category become uncategorised; notes themselves
  are never deleted as a side effect.

## Appearance and hidden heart interaction

- Dark/light appearance changes only through the sidebar switch. Tapping the
  label or other empty areas must not toggle the theme.
- Appearance labels are lowercase: `dark` and `light`.
- In light mode the switch is grey. In dark Checklist mode it is purple. In
  dark Notes mode it is blue.
- Both the main workspace and sidebar respond to dark/light mode.
- Seven taps on the empty area between the appearance label and switch toggle
  the hidden heart animation. Seven taps again stop it.
- A long press on that empty area restarts the blowing animation when enabled.
- Hearts behave like buoyant bubbles, react to phone tilt/gyro, collect at the
  current gravity edge, move again with motion, and burst when the mobile
  drawer closes.

## Android-specific contract

- The minimum supported Android version is Android 8.0 (API 26), as required
  by the bundled PaddleOCR Android SDK.
- Android is portrait-only. Do not re-enable automatic rotation unless asked.
- `PopScope(canPop: false)` prevents an Android back gesture from closing the
  app while it is running.
- Android 10+ reserves a left-edge gesture-exclusion area in `MainActivity.kt`
  so the app drawer swipe can win over the operating-system back gesture.
- The app label is `CHECKLIST` and the approved custom launcher icon is used.

## Persistence and compatibility

`LocalStore` owns these SharedPreferences keys; preserve them and maintain
backward-compatible decoding:

- `checklist.projects.v1`
- `checklist.darkMode.v1`
- `checklist.sort.v1`
- `checklist.noteSort.v1`
- `checklist.selectedProject.v1`
- `checklist.heartAnimation.v1`
- `checklist.notes.v1`
- `checklist.noteCategories.v1`
- `checklist.selectedNote.v1`
- `checklist.welcome.v1`
- `checklist.lastSeenVersion.v1`

Never silently rename or delete a persistence key. A schema change requires an
explicit migration so existing user data survives an APK update. Cover-image
deletion must remain restricted to the app-owned support directory.

## Source map

- `lib/main.dart`: themes, application shell, checklist and Notes UI,
  interactions, dialogs, heart animation, and shared visual constants.
- `lib/models/checklist_project.dart`: checklist/project and task models.
- `lib/models/note.dart`: note and category models.
- `lib/services/local_store.dart`: preferences and cover-image persistence.
- `android/app/src/main/AndroidManifest.xml`: Android identity and portrait lock.
- `android/app/src/main/kotlin/com/gather/checklist/MainActivity.kt`: sensor
  bridge, Android gesture exclusion, and offline PaddleOCR bridge.
- `android/app/src/main/jniLibs/`: locally rebuilt OpenCV 4.5.3 JNI and C++
  runtime libraries for PaddleOCR, including 16 KB Android page support.
- `tool/opencv_16k.config.py`: reproducible OpenCV Android ABI/linker build
  configuration; `tool/check_android_elf_alignment.py` validates release APKs.
- `test/`: model, persistence, theme, drawer, Notes, category, welcome, and UI
  regression coverage.

## Change protocol for future Codex sessions

1. Read this entire file and the relevant implementation/tests before editing.
2. Treat every behaviour above as intentional. Scope edits only to the user's
   current request.
3. Do not make opportunistic visual changes. If a requested implementation
   would alter another established colour, size, label, animation, layout, or
   gesture, explain it and ask first.
4. Add or update regression tests, including exact colours/sizes where those
   are part of the contract.
5. Run `dart format`, `flutter analyze`, and the complete `flutter test` suite.
6. For an APK request, verify `versionName`, `versionCode`, signature, and
   SHA-256. Keep the public version unchanged unless explicitly authorised.
7. Local release APKs currently use the project's Android debug certificate;
   state that clearly when handing off an APK.
8. This machine may need a temporary JDK/Android SDK. Build with conservative
   Gradle limits (`-Xmx2048m`, at most two workers) and remove temporary SDK/JDK
   staging after verification to recover disk space.

## Current verification baseline

- Public version: `0.4.3`.
- Last completed APK: version 0.4.3 internal build `26`.
- Current source baseline: 33 passing tests, clean static analysis, and a
  successful Android release build. The APK includes camera-based cover
  capture, offline PaddleOCR, exact system-alarm checklist reminders,
  task-to-note links, and locally rebuilt OpenCV 4.5.3 libraries. All packaged
  64-bit ELF load segments and native ZIP entries pass the 16 KB-alignment
  regression check. OCR input is sampled and capped to a 1600-pixel longest
  side before detection to remain within the Android heap limit.
- Distribution APK naming convention: `dist/checklist-<version>-android.apk`.

If implementation and this specification ever disagree, do not assume the
code is correct. Inspect tests and recent user instructions, report the
discrepancy, and obtain confirmation before changing an established choice.
