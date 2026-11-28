# CHECKLIST 0.5.9 technical audit

**28 November 2026 · Android build 64.** The starting point was local 0.5.8 build 63. The last public build was 61. I used synthetic lists and notes for the review. No personal checklist data was needed.

## Summary

I fixed literal asterisks in Notes, a narrow window for losing an edit, and recovery after an interrupted import. I also found a link parser that repeatedly scanned the same string and an Android photo import that could allocate the entire input before checking its size. The interface, supported Android versions, offline models and existing preference keys are preserved.

## Scope and execution paths

| Area | What I traced |
| --- | --- |
| Flutter | The app entry point builds the theme and workspace. The home state owns selections, controllers and debounce timers. Task rows use a reorderable sliver. Sidebar rows and the note chooser use builders. I followed creation, editing, ticking, reordering, sorting, deleting, note linking and workspace switching into persistence. |
| Storage | Projects, notes and categories are JSON collections in SharedPreferences. Covers live in application support storage and web previews in the cache. Import validates the schema, clears nonportable cover paths, asks for confirmation and applies the selection. There is no SQL query planner or online account service. |
| Android | Method channels connect the camera, file picker, PaddleOCR, QR scanner, alarms and screenshot WebView. Review covered image input size, orientation, bitmap ownership, OCR serialization, camera teardown, WebView timeout and cleanup, alarm broadcast receivers and the permissions in the manifest. |
| iPhone | Reviewed the shared Dart paths and the Swift bridges for Vision, reminders and temporary WebKit snapshots. Vision uses a background queue and bounded thumbnails. A build and device run still require Xcode. |
| Distribution | Checked Flutter dependencies and the Android build configuration, launcher resource generation, bundled fonts and models, ABI coverage, ZIP alignment and signing. Compared release source with the last public revision in a separate Git checkout to preserve local changes. |

## Findings and fixes

Priorities reflect user impact. The source locations point to the 0.5.9 implementation.

| Priority | Root cause and impact | Regression case | Change and compatibility |
| --- | --- | --- | --- |
| P1 | The editor consumed each `*` or `**` as a style toggle. Multiplication, bullet lists and pasted text could disappear or restyle following words. | Type or paste `* milk`, `2 * 3` and `**strong**`. Apply toolbar bold, save, reopen and round-trip a backup. | New text keeps stars literally. Unversioned notes translate their old star toggles to the existing style markers on read. A per-note format field distinguishes subsequent saves. Existing underline syntax and toolbar formatting are preserved. [Note decoder](lib/models/note.dart#L29) · [Editor](lib/note_formatting.dart#L22) |
| P1 | Closing the workspace cancelled its 250 ms autosave timer. An app suspension or quick teardown could drop the last edit. | Enter text and leave before the debounce expires. Check the stored note before advancing the test clock. | Lifecycle changes and disposal flush the active timer once. Ordinary foreground typing still uses the debounce. An abrupt process kill can still precede any lifecycle callback. [Lifecycle handler](lib/main.dart#L804) |
| P1 | Import replaced five preferences independently. An interruption after the first writes could mix unrelated projects, notes and selections. | Start with partially replaced preferences and an accepted import, replay twice and inspect all selections and note text. | Keep the confirmed backup in a temporary preference, finish all writes, then clear it. Startup finishes a pending import before exposing the workspace. Existing saves need no storage conversion. The extra temporary copy costs space during import. [Restore logic](lib/services/local_store.dart#L278) |
| P1 | Android read an entire encoded photo into a byte array before enforcing the existing 40 MiB limit. A large file or provider stream could exhaust the heap first. | Copy an exact-limit stream and a stream one byte larger using the same helper as the Android picker. | Check camera files before decoding. Stream picked photos to private temporary storage, checking each chunk, decode from the file, and delete the temporary copy on success or failure. EXIF orientation and the 1600 px OCR target are retained. Provider imports trade one disk write for bounded input buffering. [Android image handling](android/app/src/main/kotlin/com/gather/checklist/MainActivity.kt#L335) · [Input limit](android/app/src/main/kotlin/com/gather/checklist/PhotoInput.kt#L6) |
| P2 | Link trimming recounted brackets and copied successively shorter strings. Long punctuation tails stalled note parsing on the UI isolate. | Parse a URL ending in balanced brackets followed by thousands of unmatched punctuation characters. Compare both the URI and its end offset. | Count each bracket type at most once and trim by index. The same URL and balanced brackets survive. [Link parser](lib/services/note_links.dart#L66) |
| P2 | Backup validation accepted duplicate object IDs. Selection and keyed rows could then refer to the wrong entry. | Decode a backup containing two tasks with the same ID inside one checklist. | Validate unique nonempty IDs in each applicable namespace before replacement. Task IDs in different checklists can still coincide. [Import validation](lib/services/local_store.dart#L246) |
| P2 | Cover deletion checked a string prefix. That check also accepted nested paths outside the intended set of app-created files. Imported backups already stripped cover paths. | In a temporary test directory, request removal of a direct cover, an indirect path and a symbolic link. | Only regular files immediately inside the real covers directory qualify. The other files survive. [Cover deletion](lib/services/local_store.dart#L456) |
| P2 | Building the sidebar sorted both collections even though it only displayed one. Sorting hidden notes by category could repeat category lookups for an invisible list. | Follow both sidebar branches and switch between checklist and note sorting in the widget suite. | Resolve each sorted list on first use within that build. Hidden sorts fall from one to zero per build. No cross-build cache or invalidation is needed. [Sidebar](lib/main.dart#L2682) |

## Performance measurements

The host was an Intel Core i5-8250U with 15 GiB of reported RAM, Linux x86-64, Flutter 3.47.9, Dart 3.13.7 and JDK 17. Both parser runs used the same Dart VM, benchmark script, strings and synthetic task generator. Each cell below is the median of seven timed iterations after two warmups. These are host microbenchmarks. System load and JIT warmup affect short timings.

| Input size | Link parse before | Link parse after | Checklist JSON save/load before | Checklist JSON save/load after |
| ---: | ---: | ---: | ---: | ---: |
| 10 | 55 µs | 32 µs | 370 µs | 363 µs |
| 100 | 662 µs | 146 µs | 2,266 µs | 1,503 µs |
| 1,000 | 7,361 µs | 696 µs | 3,297 µs | 3,354 µs |
| 10,000 | 725,094 µs | 860 µs | 18,794 µs | 18,743 µs |

The parser input is one address followed by the indicated number of closing parentheses. At 10,000 characters the change removed about 724 ms of parsing time. The JSON column uses the indicated number of tasks in one checklist, half complete, and verifies the count after decoding. That column is a control. There was no change to the task JSON algorithm. Run the benchmark from the project root with the command below. [Benchmark source](tool/audit_benchmark.dart)

```sh
dart --packages=.dart_tool/package_config.json tool/audit_benchmark.dart
```

| Metric | Before | After | Interpretation |
| --- | --- | --- | --- |
| Android cold startup, idle/peak memory, CPU use and frame pacing | Not measured | Not measured | No Android device or emulator was attached. The headless runner exercises Flutter without a phone GPU, camera or OS lifecycle. |
| Checklist UI under load | No equivalent baseline run | Open, tick, persist and scroll passed at all four sizes | In one instrumented desktop widget process, RSS at the four checkpoints ranged from 270 to 318 MiB. They are process samples during increasing workloads. They cannot establish phone memory usage or a leak trend. |
| Search latency and database query time | Inapplicable | Inapplicable | The app has sort controls and preferences-backed collections. The JSON measurements above cover the relevant model path. |
| APK bytes, universal Android build | 156,332,486 | 156,331,266 | 1,220 bytes smaller than build 63. The native libraries accounted for roughly 147 MB of compressed entries in build 63. All three supported ABIs and the offline models are retained. |

## Tests and release verification

- Baseline local build 63 passed 119 Flutter tests and static analysis. Build 64 passed 129 Flutter tests, including four large-checklist cases, and static analysis.
- Three JVM tests passed. Two use English and Hungarian typography fixtures. The third exercises the bounded photo input path. These tests run the Kotlin logic directly with JUnit 4.13.2.
- The Android release identifies itself as `com.gather.checklist`, version `0.5.9`, code `64`, minimum API 26. The universal APK contains arm64-v8a, armeabi-v7a and x86_64. Both the native alignment checker and Android ZIP alignment check passed.
- The legacy and adaptive launcher PNGs were decoded from the APK and compared pixel-for-pixel with the supplied artwork. The Flutter asset matches the source file. The iPhone icon catalogue was resized from that same artwork.
- APK SHA-256 is `14abce37c43bc1e47fcdc210dda553a348741c06b2c97e12e799ac9ce7cb66ce`. Android signature verification passed. The signer SHA-256 matches the previous public APK, `1791f917bbf27c34a751d74e7f3b197a9e4e8ca91b57efd63302274deb7ab78e`. The project uses its existing Android debug certificate for update compatibility.

## Dependencies and defensive review

I checked 89 hosted packages in the Dart lockfile and six pinned Maven coordinates against OSV on 28 November 2026. The queries returned no matching advisories for those versions. The pub.dev outdated report listed 30 update candidates, with no current advisory, retraction or discontinued flag in that report. I kept the dependency versions. These checks do not cover every Gradle transitive dependency, the local PaddleOCR AAR, or the rebuilt OpenCV 4.5.3 binaries. [OSV](https://osv.dev/) · [Bundled component notices](THIRD_PARTY_NOTICES.md)

The cover guard, import validation and bounded OCR input are the defensive changes in this release. The review also confirmed that Android preview WebViews deny file and content access, cancel TLS errors, and have a capture timeout. The preview cache uses a hash of the URL for its filename. Camera use does not add microphone permission. The managed security scanner failed at startup, so these conclusions come from source inspection and local tests.

## Files and release scope

The fixes touch the Notes model and formatter, link parser, workspace lifecycle, local store and Android photo reader. Regression coverage is in the note, link, backup, lifecycle, large checklist, welcome and Android photo-input tests. Release metadata, welcome translations, launcher art, the README and project contract were updated. This release also brings the Blue milk refinements, font credits and iPhone project from local 0.5.8 builds into the public source. The storage journal is the only new preference key.

## Open work and verification limits

- **Physical devices.** Long-running heap behaviour, battery use, cold start, GPU frame times, OEM alarm delivery, camera orientation and OCR latency were not measured on hardware. A repeated checklist/Notes/camera navigation run on a lower-memory Android phone is the next profiling priority. iOS signing and native compilation still require a Mac with Xcode.
- **Large files.** The JSON picker reads a backup into memory, and the Dart camera-cover crop decodes and encodes the image on the UI isolate. A large real backup or high-resolution cover warrants a phone memory and frame trace. The journal improves recovery once the confirmed record has been written. Disk-full and power-cut durability were not tested on a device.
- **Large libraries.** Editing a task still writes that checklist collection to preferences. Active category sorting still does repeated category lookups. Measure these with realistic libraries before changing the storage model or introducing a cache.
- **Maintenance.** The Flutter home state handles several workflows, and Gradle reports deprecated build settings. Future changes can pull out individual tested workflows as needed. A signing-key change needs a separate migration plan for existing installations.
