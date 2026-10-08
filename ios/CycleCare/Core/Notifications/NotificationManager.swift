import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            // Granted
        }
    }

    func schedulePeriodReminder(daysUntil: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Nhắc nhở kỳ kinh - CycleCare"
        content.body = "Kỳ kinh nguyệt của bạn dự kiến sẽ bắt đầu trong \(daysUntil) ngày tới. Hãy chuẩn bị sẵn sàng nhé!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600 * 24, repeats: false)
        let request = UNNotificationRequest(identifier: "period_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleDailyLogReminder(hour: Int = 20, minute: Int = 0) {
        let content = UNMutableNotificationContent()
        content.title = "Dành 1 phút lắng nghe cơ thể"
        content.body = "Hôm nay bạn cảm thấy thế nào? Hãy ghi lại tâm trạng và các triệu chứng vào CycleCare nhé."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_log_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func clearAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
