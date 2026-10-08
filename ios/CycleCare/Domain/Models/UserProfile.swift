import Foundation

enum HealthGoal: String, Codable, CaseIterable {
    case track = "track"
    case conceive = "conceive"
    case pregnant = "pregnant"
    case perimenopause = "perimenopause"

    var titleVi: String {
        switch self {
        case .track: return "Theo dõi chu kỳ kinh nguyệt"
        case .conceive: return "Kế hoạch thụ thai"
        case .pregnant: return "Đang mang thai"
        case .perimenopause: return "Giai đoạn tiền mãn kinh"
        }
    }
}

struct UserProfile: Codable, Identifiable {
    let id: String
    var displayName: String
    var birthYear: Int?
    var goal: HealthGoal
    var avgCycleLength: Int
    var avgPeriodLength: Int
    var isAnonymous: BooleanLiteralType
    var lastPeriodStartDate: Date?

    init(
        id: String = UUID().uuidString,
        displayName: String = "Bạn",
        birthYear: Int? = nil,
        goal: HealthGoal = .track,
        avgCycleLength: Int = 28,
        avgPeriodLength: Int = 5,
        isAnonymous: Bool = true,
        lastPeriodStartDate: Date? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.birthYear = birthYear
        self.goal = goal
        self.avgCycleLength = avgCycleLength
        self.avgPeriodLength = avgPeriodLength
        self.isAnonymous = isAnonymous
        self.lastPeriodStartDate = lastPeriodStartDate
    }
}
