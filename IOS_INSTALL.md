# Install CHECKLIST on an iPhone without the App Store

## Install on your own iPhone for free

Use a Mac with Xcode, Flutter 3.47.9 or later, and an iPhone running iOS 15 or later. A free Apple Account works for a **Personal Team** in Xcode. Use an Xcode version that supports the iOS version installed on your phone. [Flutter’s iOS setup guide](https://docs.flutter.dev/platform-integration/ios/setup) · [Apple’s Personal Team limits](https://developer.apple.com/help/account/basics/about-your-developer-account/)

1. Copy the project to your Mac, or unzip `checklist-0.5.8-build62-ios-source.zip` there. Open Terminal in the folder containing `pubspec.yaml` and run:

   ```sh
   flutter doctor -v
   flutter pub get
   flutter build ios --debug --config-only --no-codesign
   open ios/Runner.xcworkspace
   ```

2. In Xcode, open **Settings → Accounts** and sign in with your Apple Account. In the project navigator, pick **Runner**, then the **Runner** target. Under **Signing & Capabilities**, enable **Automatically manage signing** and select your **Personal Team**. If Xcode reports that `com.gather.checklist` is unavailable, set a unique bundle identifier such as `com.yourname.checklist` and use that same identifier for future installs.
3. Connect and unlock the iPhone. Tap **Trust** if it asks whether to trust the Mac. Select the iPhone as the run destination in Xcode. On the iPhone, open **Settings → Privacy & Security → Developer Mode**, switch it on, restart, and confirm when the phone comes back on. The option may appear only after Xcode begins pairing the phone. [Apple’s Developer Mode instructions](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)
4. In Xcode, choose **Product → Run** (⌘R). When Xcode finishes, open **CHECKLIST** from the iPhone’s Home Screen. If iOS asks you to trust the developer, follow the prompt in **Settings → General → VPN & Device Management**. Once the first install works, you can choose **Product → Scheme → Edit Scheme → Run → Build Configuration → Release** and run again for a standalone, optimized build.

Free Personal Team profiles expire after **7 days**. Run the same project from Xcode again with the same team and bundle identifier to renew the install in place. Keep the existing app installed and export a backup before trying a different signing identity or bundle identifier. [Apple’s Personal Team limits](https://developer.apple.com/help/account/basics/about-your-developer-account/)

## Install an IPA on registered iPhones

With a paid Apple Developer Program membership, you can share a signed Ad Hoc IPA with people whose iPhones you register with your team. After setting up signing as above, register the devices in your Apple developer account, choose a generic iOS device as the destination in Xcode, and use **Product → Archive**. In the Organizer, select the archive and choose **Distribute App → Custom → Ad Hoc** to export it. Install the IPA on registered iPhones through Xcode’s device manager or Apple Configurator. Enable Developer Mode when prompted. [Apple’s guide to distribution on registered devices](https://developer.apple.com/documentation/xcode/distributing-your-app-to-registered-devices)

## Move your checklists and notes from Android

On Android, open the sidebar and choose **Settings → Import / Export → Export data**. Send the JSON to your iPhone, save it in Files, then use **Import data** in Checklist on the iPhone. Import replaces the iPhone’s existing checklists and notes after confirmation. Set your theme on the iPhone and add any cover images again.

## iPhone features

- The app uses Apple Vision for on-device text and QR recognition. Photo text comes in as editable plain text. You can apply bold, italic, and underline in Notes. Recognition languages depend on the iOS version and Vision’s available languages.
- Reminders use iPhone local notifications and the standard notification sound. Allow notifications when Checklist asks. The app schedules the next 64 future reminders, and refreshes them when you open the app.
- Website previews use WebKit with standard iOS transport rules. If a screenshot cannot be loaded, the link still opens in your browser.
- The iPhone project was prepared on Linux. Building, signing, and verifying it on an iPhone require Xcode on a Mac.
