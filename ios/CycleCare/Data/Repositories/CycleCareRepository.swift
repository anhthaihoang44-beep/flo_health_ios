import Foundation
import Combine

class CycleCareRepository: ObservableObject {
    static let shared = CycleCareRepository()

    @Published var currentProfile: UserProfile?
    @Published var cycles: [Cycle] = []
    @Published var articles: [Article] = []

    private let local = LocalStorageManager.shared
    private let remote = SupabaseManager.shared
    private let keychain = KeychainManager.shared

    init() {
        loadData()
        seedArticlesIfEmpty()
    }

    func loadData() {
        self.currentProfile = local.getProfile()
        self.cycles = local.getCycles()
        self.articles = local.getArticles()
    }

    // MARK: - Auth
    func getOrCreateUserId() -> String {
        if let id = keychain.get(key: "user_id") {
            return id
        }
        let newId = UUID().uuidString
        keychain.save(key: "user_id", value: newId)
        return newId
    }

    func signInAnonymously() async -> AuthResult {
        let res = await remote.signInAnonymously()
        if case .success(let uid, _, let isAnon) = res {
            keychain.save(key: "user_id", value: uid)
            keychain.save(key: "is_anonymous", value: "\(isAnon)")
        }
        return res
    }

    func linkIdentity(email: String, pass: String) async -> AuthResult {
        let uid = getOrCreateUserId()
        let res = await remote.linkIdentity(userId: uid, email: email, password: pass)
        if case .success = res {
            if var p = currentProfile {
                p.isAnonymous = false
                saveProfile(p)
            }
        }
        return res
    }

    // MARK: - Profile & Cycles
    func saveProfile(_ profile: UserProfile) {
        local.saveProfile(profile)
        DispatchQueue.main.async {
            self.currentProfile = profile
        }
    }

    func logPeriodStart(date: Date) {
        guard var profile = currentProfile else { return }
        profile.lastPeriodStartDate = date
        saveProfile(profile)

        let newCycle = Cycle(
            userId: profile.id,
            startDate: date,
            periodLength: profile.avgPeriodLength
        )
        local.addOrUpdateCycle(newCycle)
        DispatchQueue.main.async {
            self.cycles = self.local.getCycles()
        }
    }

    func saveDailyLog(_ log: DailyLog) {
        local.saveDailyLog(log)
    }

    func getDailyLog(for date: Date) -> DailyLog? {
        local.getDailyLog(for: date)
    }

    // MARK: - Seeding
    func seedArticlesIfEmpty() {
        let existing = local.getArticles()
        if existing.isEmpty {
            let samples = [
                Article(
                    title: "Understanding the 4 Phases of Your Cycle",
                    body: "The average cycle lasts 28 days and is divided into 4 key phases: Menstrual, Follicular, Ovulation, and Luteal. Tracking each phase helps you optimize nutrition, workouts, and energy levels throughout the month.",
                    category: "cycle",
                    locale: "en",
                    isPremium: false
                ),
                Article(
                    title: "Fertility Window & Recognizing Peak Days",
                    body: "The fertile window spans the 5 days before ovulation plus ovulation day itself. Key physical indicators include egg-white cervical mucus and a subtle rise in basal body temperature.",
                    category: "fertility",
                    locale: "en",
                    isPremium: false
                ),
                Article(
                    title: "Natural Ways to Ease Menstrual Cramps",
                    body: "Apply a warm heating pad to your lower abdomen, drink chamomile or ginger tea, practice gentle restorative yoga, and maintain adequate magnesium intake through your diet.",
                    category: "wellness",
                    locale: "en",
                    isPremium: false
                ),
                Article(
                    title: "Essential Nutrition for the 1st Trimester",
                    body: "Taking 400-600 mcg of Folic Acid daily is vital for neural tube development. Eating small, frequent meals helps keep morning sickness at bay.",
                    category: "pregnancy",
                    locale: "en",
                    isPremium: true
                )
            ]
            local.saveArticles(samples)
            DispatchQueue.main.async {
                self.articles = samples
            }
        }
    }

    // MARK: - Export & Delete
    func exportAllUserDataJson() -> String {
        let uid = getOrCreateUserId()
        let profile = currentProfile
        let cycles = local.getCycles()
        let logs = local.getDailyLogs()

        let dict: [String: Any] = [
            "app": "CycleCare",
            "platform": "iOS",
            "exported_at": ISO8601DateFormatter().string(from: Date()),
            "user_id": uid,
            "profile": [
                "display_name": profile?.displayName ?? "",
                "goal": profile?.goal.rawValue ?? "track",
                "avg_cycle_length": profile?.avgCycleLength ?? 28,
                "avg_period_length": profile?.avgPeriodLength ?? 5,
                "is_anonymous": profile?.isAnonymous ?? true
            ],
            "cycles_count": cycles.count,
            "logs_count": logs.count
        ]

        if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "{}"
    }

    func clearAllData() {
        local.clearAll()
        keychain.delete(key: "user_id")
        keychain.delete(key: "is_anonymous")
        DispatchQueue.main.async {
            self.currentProfile = nil
            self.cycles = []
        }
    }
}
