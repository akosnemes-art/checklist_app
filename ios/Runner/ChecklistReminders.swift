import Flutter
import UserNotifications

final class ChecklistReminders: NSObject, UNUserNotificationCenterDelegate {
  private static let prefix = "checklist.reminder."
  private let center = UNUserNotificationCenter.current()
  private var lastSync: Task<Void, Never>?

  func enableForegroundDelivery() {
    center.delegate = self
  }

  func register(with messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "checklist/reminders", binaryMessenger: messenger)
      .setMethodCallHandler { [self] call, result in
        guard call.method == "sync" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard let entries = call.arguments as? [[String: Any]] else {
          result(FlutterError(code: "invalid_reminders", message: nil, details: nil))
          return
        }
        let previous = lastSync
        lastSync = Task { @MainActor in
          await previous?.value
          do {
            if try await sync(entries) {
              result(nil)
            } else {
              result(FlutterError(code: "notifications_denied", message: nil, details: nil))
            }
          } catch {
            result(FlutterError(code: "schedule_failed", message: nil, details: nil))
          }
        }
      }
  }

  private func sync(_ entries: [[String: Any]]) async throws -> Bool {
    let now = Date()
    let upcoming = entries.compactMap { entry -> Reminder? in
      guard
        let id = entry["id"] as? String, !id.isEmpty,
        let title = entry["title"] as? String,
        let milliseconds = entry["timeMillis"] as? Int64
      else { return nil }
      let date = Date(timeIntervalSince1970: Double(milliseconds) / 1000)
      guard date > now else { return nil }
      return Reminder(id: Self.prefix + id, title: title, date: date)
    }.sorted { ($0.date, $0.id) < ($1.date, $1.id) }

    // iOS keeps at most 64 pending local notifications per app.
    let reminders = upcoming.prefix(64)
    let pending = await center.pendingNotificationRequests().filter {
      $0.identifier.hasPrefix(Self.prefix)
    }
    let desiredIDs = Set(reminders.map(\.id))
    let obsolete = pending.map(\.identifier).filter { !desiredIDs.contains($0) }
    if !obsolete.isEmpty {
      center.removePendingNotificationRequests(withIdentifiers: obsolete)
    }
    guard !reminders.isEmpty else { return true }

    let status = await center.notificationSettings().authorizationStatus
    if status == .denied { return false }
    if status == .notDetermined {
      let granted = try await center.requestAuthorization(options: [.alert, .sound])
      if !granted { return false }
    }

    let existing = Dictionary(uniqueKeysWithValues: pending.map { ($0.identifier, $0) })
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    for reminder in reminders {
      guard reminder.date > Date() else { continue }
      let fireDate = calendar.dateComponents(
        [.year, .month, .day, .hour, .minute, .second, .timeZone], from: reminder.date)
      if let request = existing[reminder.id],
        request.content.title == reminder.title,
        let trigger = request.trigger as? UNCalendarNotificationTrigger,
        trigger.dateComponents == fireDate
      { continue }

      let content = UNMutableNotificationContent()
      content.title = reminder.title
      content.sound = .default
      let trigger = UNCalendarNotificationTrigger(dateMatching: fireDate, repeats: false)
      try await center.add(UNNotificationRequest(
        identifier: reminder.id, content: content, trigger: trigger))
    }
    return true
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .list, .sound])
  }

  private struct Reminder {
    let id: String
    let title: String
    let date: Date
  }
}
