import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let photoRecognition = PhotoRecognition()
  private let checklistReminders = ChecklistReminders()
  private let websitePreview = WebsitePreview()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    checklistReminders.enableForegroundDelivery()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    photoRecognition.register(with: messenger)
    checklistReminders.register(with: messenger)
    websitePreview.register(with: messenger)
  }
}
