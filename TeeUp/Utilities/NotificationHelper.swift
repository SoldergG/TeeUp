import UserNotifications
import Foundation

/// Schedule local notifications for game sessions, reminders, etc.
enum NotificationHelper {
    // MARK: - Game session reminder
    static func scheduleGameReminder(
        sessionId: String,
        courseName: String,
        date: Date,
        hoursBefore: Int = 2
    ) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Partida em breve!"
        content.body = "A tua partida em \(courseName) começa às \(date.timeString)"
        content.sound = .default
        content.categoryIdentifier = "GAME_REMINDER"

        let triggerDate = Calendar.current.date(byAdding: .hour, value: -hoursBefore, to: date) ?? date
        guard triggerDate > .now else { return }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "game_\(sessionId)",
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    // MARK: - Round completion reminder
    static func scheduleRoundReminder(roundId: String, after hours: Int = 24) async {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "Ronda incompleta"
        content.body = "Tens uma ronda por completar. Queres terminá-la?"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(hours * 3600), repeats: false)
        let request = UNNotificationRequest(identifier: "round_\(roundId)", content: content, trigger: trigger)
        try? await center.add(request)
    }

    // MARK: - Cancel
    static func cancelReminder(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Badge
    @MainActor
    static func clearBadge() async {
        try? await UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
