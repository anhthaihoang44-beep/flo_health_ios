import Foundation

struct Pregnancy: Codable, Identifiable {
    let id: String
    let userId: String
    var lmpDate: Date
    var dueDate: Date
    var isActive: Bool
    var endedAt: Date?

    init(
        id: String = UUID().uuidString,
        userId: String,
        lmpDate: Date,
        dueDate: Date,
        isActive: Bool = true,
        endedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.lmpDate = lmpDate
        self.dueDate = dueDate
        self.isActive = isActive
        self.endedAt = endedAt
    }
}

struct FetalMilestone {
    let week: Int
    let fruitComparison: String
    let lengthCm: Double
    let weightGrams: Double
    let description: String
    let advice: String

    static func forWeek(_ week: Int) -> FetalMilestone {
        let clamped = max(4, min(40, week))
        switch clamped {
        case 4...6:
            return FetalMilestone(
                week: clamped,
                fruitComparison: "Sesame Seed",
                lengthCm: 0.2,
                weightGrams: 0.5,
                description: "The neural tube is developing and the heart is beginning its very first beats.",
                advice: "Take 400-600 mcg of Folic Acid daily, stay well-hydrated, and prioritize rest."
            )
        case 7...10:
            return FetalMilestone(
                week: clamped,
                fruitComparison: "Raspberry",
                lengthCm: 2.3,
                weightGrams: 2.0,
                description: "Tiny webbed fingers and toes are separating and facial features are starting to form.",
                advice: "Eat smaller, frequent meals to ease morning sickness and sip warm ginger tea."
            )
        case 11...14:
            return FetalMilestone(
                week: clamped,
                fruitComparison: "Lemon",
                lengthCm: 7.4,
                weightGrams: 23.0,
                description: "Completing first trimester! Baby is moving gently and unique fingerprints are forming.",
                advice: "Ideal window for your first trimester ultrasound scan and screening tests."
            )
        case 15...19:
            return FetalMilestone(
                week: clamped,
                fruitComparison: "Avocado",
                lengthCm: 12.0,
                weightGrams: 100.0,
                description: "Baby can now hear your heartbeat and the soothing sound of your voice.",
                advice: "Talk and sing gently to baby, and practice sleeping on your left side."
            )
        case 20...24:
            return FetalMilestone(
                week: clamped,
                fruitComparison: "Ear of Corn",
                lengthCm: 28.0,
                weightGrams: 450.0,
                description: "You may feel distinct little kicks! Eyebrows and delicate eyelids are now formed.",
                advice: "Ensure adequate iron and calcium intake, and schedule gestational diabetes screening."
            )
        case 25...29:
            return FetalMilestone(
                week: clamped,
                fruitComparison: "Eggplant",
                lengthCm: 36.0,
                weightGrams: 1000.0,
                description: "Entering the 3rd trimester! Rapid brain growth and baby is now practicing blinking.",
                advice: "Track baby's kick counts daily after meals and prepare your hospital go-bag."
            )
        default:
            return FetalMilestone(
                week: clamped,
                fruitComparison: "Watermelon",
                lengthCm: 50.0,
                weightGrams: 3200.0,
                description: "Baby is fully grown and ready to meet you! Soft chubby skin and settled in head-down position.",
                advice: "Monitor labor contractions and fluid signs to arrive at the maternity ward promptly."
            )
        }
    }
}
