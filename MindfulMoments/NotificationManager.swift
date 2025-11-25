import Foundation
import UserNotifications

final class NotificationManager {

    static let shared = NotificationManager()

    private init() {}


    func requestPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
    }


    func scheduleDailyReminder(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()

        // Avoid stacking duplicates
        center.removePendingNotificationRequests(withIdentifiers: ["mindful_daily_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Check in with your day"
        content.body = "Take a moment to log how you're feeling in Mindful Moments."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "mindful_daily_reminder",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule daily reminder: \(error)")
            }
        }
    }

    func cancelDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            "mindful_daily_reminder",
            "mindful_oneoff_reminder"
        ])
    }

    func scheduleOneOffReminderLaterToday() {
        let center = UNUserNotificationCenter.current()

        // Make sure we have permission (safe to call multiple times)
        requestPermission()

        // Remove any previous "later today" reminder so we only keep the latest one
        center.removePendingNotificationRequests(withIdentifiers: ["mindful_oneoff_reminder"])

        let now = Date()
        let calendar = Calendar.current

        // Try to schedule
        let targetDate: Date
        if let inTwoHours = calendar.date(byAdding: .hour, value: 2, to: now),
           calendar.isDate(inTwoHours, inSameDayAs: now) {
            targetDate = inTwoHours
        } else {
            // If it's too late
            targetDate = now.addingTimeInterval(15 * 60)
        }

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: targetDate)

        let content = UNMutableNotificationContent()
        content.title = "Take a moment for yourself"
        content.body = "You asked to be reminded later today. How are you feeling right now?"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "mindful_oneoff_reminder",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule one-off reminder: \(error)")
            } else {
                print("One-off reminder scheduled for \(targetDate)")
            }
        }
    }
}
