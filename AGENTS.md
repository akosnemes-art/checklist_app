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
- Current public version: **0.5.1**. The Flutter build number may increase for
  rebuilt APKs, but the public version must not change without explicit user
  approval.
- Android application ID: `com.gather.checklist`.
- Designed by **Ákos Nemes using Codex AI**.
- The welcome dialog appears once per installation and again whenever the
  public version or internal build number changes. It states the public
  version, build number, and design credit. Its purple `read more` text expands
  the dialog with the implemented changes.
- Android is the supported platform. The app is built with Flutter.
- The app is local-first. Checklists, tasks, notes, categories, preferences,
  selections, and cover-image references are stored locally. Do not introduce
  accounts, cloud storage, analytics, or network requirements unless requested.
  Website screenshots visit the linked page when online and cache the result
  locally. Notes and photo text recognition work offline.

## Non-negotiable visual invariants

These details have already been approved and must not change incidentally:

- Square corners are used throughout buttons, fields, dialogs, menus, chips,
  drawers, snackbars, and window chrome.
- `CHECKLIST` and `NOTES` form one wordmark in the same font. There is no
  chromatic-aberration text effect. A checkmark appears immediately beside the
  selected mode, is visually aligned with the surrounding text, glitches when
  the selection changes, and performs a subtle ambient glitch at a random
  interval between 10 and 20 seconds.
- In the Boi theme the active word is white and the inactive word is grey. In
  the Pencil theme both words use the approved greys. Switching workspaces fades
  all affected UI except the drawer/sidebar opening animation itself.
- Boi Checklist mode uses purple; Boi Notes mode uses blue. Pencil mode uses
  only the approved neutral greys except for explicitly retained blue dialog
  frames, blue note links, and blue/yellow Notes formatting controls. Pastel uses its approved
  palette with blue Notes hyperlinks and warm-grey selected note rows.
- The checklist completion progress is brand yellow (`#F3ED23`) in dark mode.
  In light mode its progress is black on a light-grey track.
- Checklist priorities are: low blue (`#229FE3`), normal purple
  (`#922FD0`), and high yellow (`#F3ED23`).
- The task-composer placeholder beginning `add a task…` is grey (`#9AA0AA`).
- The note-editor placeholder `start writing…` is grey (`#9AA0AA`). Typed note
  body text is white (`#F8F7FF`) in dark mode and black in light mode.
- Note-category colour affects the note title, category label, list indicator,
  and selected-row treatment. It does not recolour the note body text.
- White frames are intentional around the create-note button, filter/sort
  button, and category selector.
- Every three-dot settings button is intentionally unframed and uses a vertical
  ellipsis. Do not restore horizontal dots or frames around these buttons.
- The Notes filter button and `new note` button have exactly the same height.
- There are no static decorative hearts in the sidebar.
- Popup dialogs have a two-pixel default-note-blue frame. The linked-note and
  create-note popups use light line grey in Pencil and pale yellow in Pastel.
  Dropdown menu frames
  are two pixels wide and use default note blue in Boi, light line grey in
  Pencil, and pale yellow in Pastel.
- Save and create buttons brighten for 60 milliseconds before completing the
  action. Dialog frames draw first and the contents then fade in. The complete
  transition takes 280 milliseconds and respects reduced-motion settings.

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
| Dark Notes sidebar | `#0B1D3B` |
| Deep-blue button | `#1553A3` |
| Default note blue | `#5A9BFF` |
| Rename-note pale pastel blue | `#D9EAF7` |
| Placeholder / light-mode switch grey | `#9AA0AA` |
| Light app background | `#F7F5F2` |
| Light surface | `#E7E6E3` |
| Light sidebar | `#D5D4D1` |
| Light line | `#858C94` |
| Light control | `#666B70` |
| Light text / progress | `#101010` |
| Pencil high priority | `#0E2F44` |
| Pencil medium priority | `#64696A` |
| Pencil low priority | `#999999` |
| Pastel peach background | `#FBDCC4` |
| Pastel white surface | `#FFFFFF` |
| Pastel pale-yellow accent | `#F8F2C8` |
| Pastel green checklist sidebar | `#BED4C7` |
| Pastel mauve Notes sidebar / line | `#C7B0B8` |
| Pastel high priority | `#E31F26` |
| Pastel medium priority | `#00978D` |
| Pastel low priority | `#B5B1D8` |

The 18 category colours are defined once in `_noteColours` in
`lib/main.dart`. Preserve their order because tests and saved user choices may
rely on the palette positions.

## Checklist mode

- The dark sidebar is deep purple and the light sidebar is neutral grey.
- The top action is `new checklist` with the checklist sort button beside it.
- The section label is `YOUR CHECKLISTS` with the current checklist count.
- Only checklist entries are visible in the sidebar while this mode is active.
- Checklist sorting supports newest, oldest, A–Z, and priority.
- A new installation creates `my first checklist` if no project exists.
- Each checklist shows its creation date, completion count, and priority.
- The selected checklist supports rename, delete, priority changes, optional
  cover image, reminder date/time, task creation, task editing, task deletion,
  and completion.
- Checklist creation contains only the medium-grey `checklist name` field and
  cancel/create actions. It has no `name it` heading or priority control, and
  new checklists default to medium priority. Priority can still be changed from
  the selected checklist header.
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
  moved and zoomed beneath it. The live Android camera preview can switch
  between rear and front cameras when both are available and displays detected
  written links and QR links offline.
- The cover-image remove X is shown for two seconds, then fades out. Tapping
  the cover reveals it again for another two seconds before the next fade.
- Task-entry settings use an unframed vertical ellipsis. The menu labels
  `edit` and `delete` are lowercase, and `+ note` links an existing note to the
  task.
- Holding only the task-text area for at least 140 milliseconds starts
  reordering. The checkmark retains only its completion toggle and the
  three-dot button retains only its settings menu; neither starts a reorder.
  Moving the text area reprioritises the task and saves the new order locally.
  There is no six-dot drag handle.
- A linked task shows the Material `sticky_note_2` icon directly below its
  left-aligned checkbox. Linked and unlinked task checkboxes use the same fixed
  leading-column width and horizontal alignment. The icon is yellow in Boi and
  blue in Pencil and Pastel. Tapping it changes it to purple before opening
  the linked note in a scrollable popup that renders the note's formatting.
  Links in the popup are clickable. The `+ note` chooser shows formatted
  previews of the existing notes.
  The task text wraps within the remaining row width and also
  retains its established note-opening tap.
- In Pastel, priority controls use red `#E31F26` for high, teal `#00978D` for
  medium, and lavender `#B5B1D8` for low. In Pencil, priority controls use navy
  `#0E2F44` for high, dark grey `#64696A` for medium, and grey `#999999` for
  low. Boi priority colours do not change.
- The selected checklist header includes its creation date and task counts.
- When tasks exist, their completion progress is yellow in dark mode and black
  in light mode. The light-mode track is a lighter grey. Progress changes
  animate smoothly rather than jumping to the new value.
- New checklist and note rows fade into the sidebar. Confirmed deletion fades
  the row out before removing and persisting it.
- Selecting a different checklist fades in its title, cover image, and tasks
  from top to bottom. Selecting a different note fades in its title, category,
  and writing area from top to bottom.
- The Android soft-keyboard Done action adds the task. The placeholder is only
  `add a task…`, without a parenthetical Done instruction.
- The empty checklist message is `your list starts here`.

## Notes mode

- The sidebar remains open when switching between Checklist and Notes modes.
- The sidebar fades from purple to deep blue in dark mode. It remains neutral
  grey across both workspaces in light mode.
- The top action changes to blue `new note`; the adjacent Notes filter/sort
  control remains the same height.
- The section label becomes `YOUR NOTES` and shows the note count.
- Only note entries are shown in the sidebar while Notes mode is active.
- Note sorting supports newest, oldest, A–Z, and category A–Z.
- A note list entry uses its category colour (or default note blue), shows its
  creation date, and receives a category-coloured selected treatment. In Pastel
  the selected note row background uses very light warm grey `#F7F5F2`.
- The sidebar note-row menu uses an unframed vertical ellipsis and offers
  rename, delete, and category settings.
- The main Notes workspace deliberately has no `notes` heading, no `make a
  note` button, and no hamburger/sidebar button.
- On mobile, the drawer is opened with a left-edge swipe. Switching modes or
  selecting an entry must not automatically close an already-open drawer.
- The note page is expanded and shows, in order: note name, creation date,
  category, then the large writing field.
- Note content autosaves locally after a short debounce.
- Links in note text are underlined and open in the system browser or registered
  app when tapped outside edit mode. Boi uses brand yellow `#F3ED23`, Pencil
  uses default note blue `#5A9BFF`, and Pastel uses deep blue `#1553A3`.
  Links glow briefly when tapped, and Pastel links brighten to `#5A9BFF`.
  While editing, taps position the cursor.
- The note editor has unframed bold, italic, and underline controls. Inactive
  controls are default-note-blue; active controls are brand yellow. Formatting
  is rendered directly in the editable text, applies to highlighted text, and
  remains active for newly typed characters until switched off. The three styles
  toggle independently and can be combined. Their controls align on the right
  of the category name row below the header controls.
- Highlighted note text uses a borderless selection toolbar containing only
  cut, copy, paste, and the formatting letters `B`, `i`, and `U`.
- Tapping outside the note editor exits edit mode. The formatting toolbar is
  part of the editor tap region, so its buttons preserve focus and formatting
  state.
- The create-note dialog uses the dark-blue Notes theme in Boi and the note
  editor's writing surface in Pencil and Pastel. The rename-note dialog uses a
  pale pastel-blue `#D9EAF7` background with a blue frame. Both retain the
  category selector.
- The note-header category button opens category assignment. The adjacent
  unframed vertical-ellipsis menu offers rename, delete, and category settings.
- On Android, a square white-framed `+` button sits between the note category
  and three-dot buttons. Its menu offers `add picture` and `take a photo`.
  PaddleOCR turns the selected image into editable note text in English or
  Hungarian entirely offline and inserts it at the current editor selection.
  The live preview can switch between rear and front cameras when available.
  It displays recognised written addresses and QR links offline. Recognised
  addresses and QR links in a captured photo become tappable links in the note.
  Detected links can also be opened from the live Notes camera preview.
- The globe beside the version in the Notes sidebar opens saved web links
  across all notes with clickable screenshots. The app attempts to capture
  previews of newly typed and photographed website links while online.

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

## Settings, themes, and hidden heart interaction

- The former dark/light switch is removed. The bottom of the sidebar has a
  single `settings` row beneath a fixed full-width line. The public version is
  displayed below the row at half the Settings text size. The line stays the
  same length whether Settings is open or closed.
- Opening Settings fades and expands the option content. Closing it collapses
  the content and returns to the main Settings page.
- The Settings arrow points down when open and up when closed. Pressing a
  Settings row briefly brightens its text.
- The main Settings page contains `themes`, `language`, `import / export`, and
  `about`.
- The Themes page replaces the main option text with a fade and offers `Boi`,
  `Pencil`, and `Pastel`. Boi is the established dark appearance, Pencil is the
  established light appearance, and Pastel uses the five canonical pastel
  colours. The selected theme is saved locally.
- The Language page offers persistent English, Hungarian, French, Czech,
  German, and Simplified Chinese selection. The translate icon is on the main Language row. Language choices
  are text-only. Visible interface labels, hints, menus, dialogs, tooltips,
  dates, and Android reminder messages respond to the selected language.
  User-created content is never translated.
- Import/export writes a versioned JSON backup containing checklists, tasks,
  reminders, notes, note categories, links, and current selections. Import
  validates the file and replaces the starter/local content after explicit
  confirmation. App-private cover image paths are cleared because they are not
  portable between installations.
- The About page shows the public version, internal build, maker credits
  `Ákos Nemes · Codex AI`, and contact email `akosnemes@proton.me`. It does not
  show update notes.
- Both the main workspace and sidebar respond to theme changes.
- Seven taps on the empty middle area of the Settings row toggle
  the hidden heart animation. Seven taps again stop it.
- Three taps on that same middle area open a version popup listing the current
  build, implemented features, and the maker credits `Ákos Nemes · Codex AI`.
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
- The main content and mobile drawer respect the Android bottom safe area so
  the task composer and Settings panel stay above gesture or three-button
  system navigation.
- Android uses transparent edge-to-edge system navigation. The active app or
  drawer background extends behind a gesture indicator without a white strip;
  safe-area padding still keeps interactive controls clear of system UI.
- The app label is `CHECKLIST`. Gradle packages the approved
  `Checklist_app_icon_safe.png` as both the legacy and adaptive launcher icon.

## Persistence and compatibility

`LocalStore` owns these SharedPreferences keys; preserve them and maintain
backward-compatible decoding:

- `checklist.projects.v1`
- `checklist.darkMode.v1`
- `checklist.theme.v1`
- `checklist.language.v1`
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
- `lib/app_localizations.dart` and `lib/app_translations.dart`: interface
  translations and the localized text wrapper.
- `lib/app_version.dart`: public version and internal build number.
- `lib/models/checklist_project.dart`: checklist/project and task models.
- `lib/models/note.dart`: note and category models.
- `lib/note_formatting.dart`: note formatting, selection, and rendered styles.
- `lib/photo_camera_dialog.dart`: shared camera preview and live link display.
- `lib/popup_animation.dart`: shared dialog frame and content transitions.
- `lib/website_gallery.dart` and `lib/services/website_previews.dart`: saved
  web links, screenshot capture, and the local preview cache.
- `lib/services/local_store.dart`: preferences and cover-image persistence.
- `lib/services/note_links.dart`: note link detection and repair of common
  spacing errors in photographed web addresses.
- `android/app/src/main/AndroidManifest.xml`: Android identity and portrait lock.
- `android/app/src/main/kotlin/com/gather/checklist/MainActivity.kt`: sensor
  bridge, Android gesture exclusion, and offline PaddleOCR bridge.
- `android/app/src/main/kotlin/com/gather/checklist/CameraLinkScanner.kt`:
  camera-frame preparation and offline QR decoding.
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

- Public version: `0.5.1`.
- Last completed APK: version 0.5.1 internal build `39`.
- Current source baseline: 70 passing tests, clean static analysis, and a
  successful Android release build. The APK includes camera-based cover
  capture, offline PaddleOCR, exact system-alarm checklist reminders,
  task-to-note links, tappable Notes hyperlinks, live text and QR link
  detection, and locally rebuilt OpenCV 4.5.3 libraries. All packaged
  64-bit ELF load segments and native ZIP entries
  pass the 16 KB-alignment regression check. OCR input is sampled and capped
  to a 1600-pixel longest side before detection to remain within the Android
  heap limit.
- Distribution APK naming convention: `dist/checklist-<version>-android.apk`.
- Publish one universal APK on each stable GitHub Release. Obtainium tracks
  the public repository URL. Keep the signing certificate consistent across updates.

If implementation and this specification ever disagree, do not assume the
code is correct. Inspect tests and recent user instructions, report the
discrepancy, and obtain confirmation before changing an established choice.
