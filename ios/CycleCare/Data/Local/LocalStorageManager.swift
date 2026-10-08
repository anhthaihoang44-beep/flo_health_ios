import Foundation

class LocalStorageManager {
    static let shared = LocalStorageManager()
    private init() {}

    private let userDefaults = UserDefaults.standard
    private let profileKey = "cyclecare_profile"
    private let cyclesKey = "cyclecare_cycles"
    private let logsKey = "cyclecare_daily_logs"
    private let articlesKey = "cyclecare_articles"
    private let pregnancyKey = "cyclecare_pregnancy"

    // Profile
    func saveProfile(_ profile: UserProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            userDefaults.set(data, forKey: profileKey)
        }
    }

    func getProfile() -> UserProfile? {
        guard let data = userDefaults.data(forKey: profileKey),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return nil
        }
        return profile
    }

    // Cycles
    func saveCycles(_ cycles: [Cycle]) {
        if let data = try? JSONEncoder().encode(cycles) {
            userDefaults.set(data, forKey: cyclesKey)
        }
    }

    func getCycles() -> [Cycle] {
        guard let data = userDefaults.data(forKey: cyclesKey),
              let cycles = try? JSONDecoder().decode([Cycle].self, from: data) else {
            return []
        }
        return cycles
    }

    func addOrUpdateCycle(_ cycle: Cycle) {
        var cycles = getCycles()
        if let idx = cycles.firstIndex(where: { $0.id == cycle.id }) {
            cycles[idx] = cycle
        } else {
            cycles.insert(cycle, at: 0)
        }
        saveCycles(cycles)
    }

    // Daily Logs
    func saveDailyLogs(_ logs: [DailyLog]) {
        if let data = try? JSONEncoder().encode(logs) {
            userDefaults.set(data, forKey: logsKey)
        }
    }

    func getDailyLogs() -> [DailyLog] {
        guard let data = userDefaults.data(forKey: logsKey),
              let logs = try? JSONDecoder().decode([DailyLog].self, from: data) else {
            return []
        }
        return logs
    }

    func saveDailyLog(_ log: DailyLog) {
        var logs = getDailyLogs()
        let cal = Calendar.current
        if let idx = logs.firstIndex(where: { cal.isDate($0.logDate, inSameDayAs: log.logDate) }) {
            logs[idx] = log
        } else {
            logs.append(log)
        }
        saveDailyLogs(logs)
    }

    func getDailyLog(for date: Date) -> DailyLog? {
        let cal = Calendar.current
        return getDailyLogs().first(where: { cal.isDate($0.logDate, inSameDayAs: date) })
    }

    // Articles
    func saveArticles(_ articles: [Article]) {
        if let data = try? JSONEncoder().encode(articles) {
            userDefaults.set(data, forKey: articlesKey)
        }
    }

    func getArticles() -> [Article] {
        guard let data = userDefaults.data(forKey: articlesKey),
              let articles = try? JSONDecoder().decode([Article].self, from: data) else {
            return []
        }
        return articles
    }

    // Clear
    func clearAll() {
        userDefaults.removeObject(forKey: profileKey)
        userDefaults.removeObject(forKey: cyclesKey)
        userDefaults.removeObject(forKey: logsKey)
        userDefaults.removeObject(forKey: pregnancyKey)
    }
}
