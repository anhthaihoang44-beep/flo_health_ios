import Foundation

struct Cycle: Codable, Identifiable {
    let id: String
    let userId: String
    var startDate: Date
    var endDate: Date?
    var cycleLength: Int?
    var periodLength: Int?
    var isPredicted: Bool

    init(
        id: String = UUID().uuidString,
        userId: String,
        startDate: Date,
        endDate: Date? = nil,
        cycleLength: Int? = nil,
        periodLength: Int? = nil,
        isPredicted: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.startDate = startDate
        self.endDate = endDate
        self.cycleLength = cycleLength
        self.periodLength = periodLength
        self.isPredicted = isPredicted
    }
}
