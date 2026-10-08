import Foundation

enum HealthGoal: String, Codable, CaseIterable {
    case track = "track"
    case conceive = "conceive"
    case pregnant = "pregnant"
    case perimenopause = "perimenopause"

    var titleEn: String {
        switch self {
        case .track: return "Track Cycle"
        case .conceive: return "Try to Conceive"
        case .pregnant: return "Pregnancy"
        case .perimenopause: return "Perimenopause"
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
        displayName: String = "Anonymous User",
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
