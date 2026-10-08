import Foundation

struct DailyLog: Codable, Identifiable {
    let id: String
    let userId: String
    var logDate: Date
    var mood: String?
    var discharge: String?
    var crampsLevel: Int? // 0 - 5
    var libido: Int?      // 0 - 5
    var sleepHours: Double?
    var sleepQuality: Int? // 1 - 5
    var activity: String?
    var symptoms: [String]
    var note: String?

    init(
        id: String = UUID().uuidString,
        userId: String,
        logDate: Date,
        mood: String? = nil,
        discharge: String? = nil,
        crampsLevel: Int? = nil,
        libido: Int? = nil,
        sleepHours: Double? = nil,
        sleepQuality: Int? = nil,
        activity: String? = nil,
        symptoms: [String] = [],
        note: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.logDate = logDate
        self.mood = mood
        self.discharge = discharge
        self.crampsLevel = crampsLevel
        self.libido = libido
        self.sleepHours = sleepHours
        self.sleepQuality = sleepQuality
        self.activity = activity
        self.symptoms = symptoms
        self.note = note
    }
}
