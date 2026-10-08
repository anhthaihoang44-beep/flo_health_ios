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
                    title: "Hiểu Rõ 4 Pha Của Chu Kỳ Kinh Nguyệt",
                    body: "Chu kỳ kinh nguyệt trung bình kéo dài 28 ngày và được chia thành 4 pha: Pha hành kinh, Pha nang trứng, Pha rụng trứng và Pha hoàng thể. Việc theo dõi từng pha giúp tối ưu hóa chế độ dinh dưỡng và năng lượng.",
                    category: "cycle",
                    locale: "vi",
                    isPremium: false
                ),
                Article(
                    title: "Cửa Sổ Thụ Thai & Cách Nhận Biết Thời Điểm Vàng",
                    body: "Cửa sổ thụ thai bao gồm 5 ngày trước khi rụng trứng và ngày rụng trứng. Dấu hiệu: dịch âm đạo dạng lòng trắng trứng sống và nhiệt độ cơ thể cơ bản tăng nhẹ.",
                    category: "fertility",
                    locale: "vi",
                    isPremium: false
                ),
                Article(
                    title: "Giảm Đau Bụng Kinh Tự Nhiên Không Cần Thuốc",
                    body: "Chườm ấm vùng bụng dưới bằng túi chườm (40°C), uống trà gừng ấm, tập yoga nhẹ nhàng và bổ sung magie trong chế độ ăn hàng ngày.",
                    category: "wellness",
                    locale: "vi",
                    isPremium: false
                ),
                Article(
                    title: "Dinh Dưỡng 3 Tháng Đầu Thai Kỳ (Tam Cá Nguyệt 1)",
                    body: "Bổ sung Acid Folic (400-600 mcg/ngày) là tối quan trọng để phòng dị tật ống thần kinh. Chia nhỏ bữa ăn để giảm ốm nghén.",
                    category: "pregnancy",
                    locale: "vi",
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
