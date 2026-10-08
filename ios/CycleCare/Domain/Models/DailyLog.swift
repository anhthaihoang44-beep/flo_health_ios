import Foundation

public enum MenstrualFlow: String, Codable, CaseIterable {
    case none = "none"
    case light = "light"
    case medium = "medium"
    case heavy = "heavy"
}

public enum MoodType: String, Codable, CaseIterable {
    case happy = "happy"
    case calm = "calm"
    case sad = "sad"
    case irritable = "irritable"
    case tired = "tired"
    case anxious = "anxious"

    public var emoji: String {
        switch self {
        case .happy: return "😊"
        case .calm: return "😌"
        case .sad: return "😢"
        case .irritable: return "😠"
        case .tired: return "😴"
        case .anxious: return "😰"
        }
    }

    public var label: String {
        switch self {
        case .happy: return "Vui vẻ"
        case .calm: return "Bình yên"
        case .sad: return "Buồn bã"
        case .irritable: return "Khó chịu"
        case .tired: return "Mệt mỏi"
        case .anxious: return "Lo âu"
        }
    }
}

public enum SymptomType: String, Codable, CaseIterable {
    case cramps = "cramps"
    case headache = "headache"
    case bloating = "bloating"
    case backache = "backache"
    case breastTenderness = "breast_tenderness"
    case acne = "acne"

    public var emoji: String {
        switch self {
        case .cramps: return "⚡"
        case .headache: return "🤕"
        case .bloating: return "🎈"
        case .backache: return "🦴"
        case .breastTenderness: return "🌸"
        case .acne: return "✨"
        }
    }

    public var label: String {
        switch self {
        case .cramps: return "Đau bụng"
        case .headache: return "Đau đầu"
        case .bloating: return "Đầy hơi"
        case .backache: return "Đau lưng"
        case .breastTenderness: return "Căng ngực"
        case .acne: return "Nổi mụn"
        }
    }
}

public enum DischargeType: String, Codable, CaseIterable {
    case none = "none"
    case dry = "dry"
    case sticky = "sticky"
    case creamy = "creamy"
    case eggwhite = "eggwhite"
    case watery = "watery"

    public var label: String {
        switch self {
        case .none: return "Không có"
        case .dry: return "Khô ráo"
        case .sticky: return "Dính"
        case .creamy: return "Đục kem"
        case .eggwhite: return "Lòng trắng"
        case .watery: return "Lỏng như nước"
        }
    }
}

public enum ActivityLevel: String, Codable, CaseIterable {
    case none = "none"
    case light = "light"
    case moderate = "moderate"
    case intense = "intense"

    public var label: String {
        switch self {
        case .none: return "Không vận động"
        case .light: return "Nhẹ nhàng"
        case .moderate: return "Vừa phải"
        case .intense: return "Cường độ cao"
        }
    }
}

public struct DailyLog: Codable, Identifiable {
    public let id: String
    public let userId: String
    public var logDate: Date
    public var flow: MenstrualFlow
    public var mood: MoodType?
    public var discharge: DischargeType
    public var crampsLevel: Int?
    public var libido: Int?
    public var sleepHours: Double?
    public var sleepQuality: Int?
    public var activity: ActivityLevel
    public var symptoms: [SymptomType]
    public var note: String?

    public init(
        id: String = UUID().uuidString,
        userId: String,
        logDate: Date,
        flow: MenstrualFlow = .none,
        mood: MoodType? = nil,
        discharge: DischargeType = .none,
        crampsLevel: Int? = nil,
        libido: Int? = nil,
        sleepHours: Double? = nil,
        sleepQuality: Int? = nil,
        activity: ActivityLevel = .none,
        symptoms: [SymptomType] = [],
        note: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.logDate = logDate
        self.flow = flow
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
