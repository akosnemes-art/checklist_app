# CHECKLIST

I made CHECKLIST so I could keep a short to-do list and a longer note together. A task like “call the garage” can have a reminder on the list and a note underneath with the phone number and everything I need to ask. The lists, notes and photos live on your phone. You can use it offline, including reading text from a photo.

**[Download CHECKLIST for Android](https://github.com/akosnemes-art/checklist_app/releases/download/v0.5.9/checklist-0.5.9-android.apk)** · [All releases](https://github.com/akosnemes-art/checklist_app/releases)

## Install and update

CHECKLIST runs on Android 8 or newer. Open the APK on your phone and allow the app you downloaded it with to install it if Android asks. For an update, install the new APK over your existing copy to keep your lists and notes.

I put one APK on each stable release so you can also use Obtainium. In Obtainium, choose **Add App**, paste `https://github.com/akosnemes-art/checklist_app`, and tap **Add**. [Add CHECKLIST to Obtainium](https://apps.obtainium.imranr.dev/redirect?r=obtainium%3A%2F%2Fapp%2F%257B%2522id%2522%253A%2522com.gather.checklist%2522%252C%2522url%2522%253A%2522https%253A%252F%252Fgithub.com%252Fakosnemes-art%252Fchecklist_app%2522%252C%2522author%2522%253A%2522akosnemes-art%2522%252C%2522name%2522%253A%2522CHECKLIST%2522%257D)

The repo also includes an iPhone project for iOS 15 and later. It needs a Mac and Xcode to build and sign. I’ve included the setup steps. [Install on iPhone](IOS_INSTALL.md)

## Make your first list

1. Open the sidebar and choose **new checklist**. On a phone you can also swipe in from the left edge.
2. Write a task in **add a task…** and press **Done** on the keyboard. Tick the box to complete it. Hold the task text and drag to change the order.
3. Use the calendar to set a reminder for the checklist, or the priority button to mark how urgent it is. You can also add a cover from your camera or pictures.
4. For details that need more room, switch to **NOTES** in the sidebar and create a note. Back on the checklist, open a task’s **⋮** menu and choose **+ note**. The little note icon below the checkbox opens it.

## Write a note

Notes save as you type. Use **B**, *i* and **U** to format a selection or the text you type next. Asterisks work as ordinary text, so you can write `2 * 3` or `**remember**` exactly as shown. You can give notes a coloured category and sort them in the sidebar.

Tap **+** beside the category button to turn a picture into editable text. Android recognises English and Hungarian offline and picks up some bold, italic and underlined text. The Notes camera also recognises web addresses and QR links. Tap outside the editor to open a link. When a note contains a web link, the globe beside **B** opens your saved links and any previews captured while online.

## Make it yours

In **Settings → themes**, choose Boi, Pencil, Blue milk, Copper, Black Metal, Pixel, Cyberpunk or SV. Tap **customise** under your selection to change its colours. **Settings → language** has English, Hungarian, French, Czech, German and Simplified Chinese.

To move to another phone, use **Settings → import / export** to save a JSON backup. It includes checklists, reminders, notes, categories and task-to-note links. Import asks before replacing the lists on the destination phone. Add cover photos again after the move.

## What I changed in 0.5.9

I fixed the asterisk in Notes. You can type or paste it anywhere without switching on italics or bold. I also fixed a missed save when leaving the app, sped up links with long runs of punctuation, and updated the icon. [Release notes](https://github.com/akosnemes-art/checklist_app/releases/tag/v0.5.9) · [Technical audit](AUDIT_REPORT.md)

## Build it yourself

With Flutter and the Android SDK installed, run these from the project folder.

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
python3 tool/check_android_elf_alignment.py build/app/outputs/flutter-apk/app-release.apk
```

The APK is in `build/app/outputs/flutter-apk/`. The GitHub APK uses the project’s Android debug certificate. Android needs the same signing certificate to install an update over it.

Designed by Ákos Nemes. Font credits are in **Settings → about → credits**. [Third-party notices](THIRD_PARTY_NOTICES.md)
