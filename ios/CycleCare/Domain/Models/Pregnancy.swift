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
                fruitComparison: "Hạt mè (Hạt vừng)",
                lengthCm: 0.2,
                weightGrams: 0.5,
                description: "Ống thần kinh của bé đang hình thành và tim bắt đầu có những nhịp đập đầu tiên.",
                advice: "Uống bổ sung Acid Folic (400-600 mcg/ngày), nghỉ ngơi và uống đủ nước."
            )
        case 7...10:
            return FetalMilestone(
                week: clamped,
                fruitComparison: "Quả mâm xôi",
                lengthCm: 2.3,
                weightGrams: 2.0,
                description: "Các ngón tay, ngón chân nhỏ xíu đang tách rời và chóp mũi dần rõ nét.",
                advice: "Chia nhỏ bữa ăn nếu bị ốm nghén, uống trà gừng ấm nhẹ."
            )
        case 11...14:
            return FetalMilestone(
                week: clamped,
                fruitComparison: "Quả chanh vàng",
                lengthCm: 7.4,
                weightGrams: 23.0,
                description: "Hoàn tất tam cá nguyệt 1. Bé bắt đầu cử động nhẹ nhàng và có dấu vân tay riêng.",
                advice: "Thời điểm thích hợp thực hiện siêu âm đo độ mờ da gáy."
            )
        case 15...19:
            return FetalMilestone(
                week: clamped,
                fruitComparison: "Quả bơ sáp",
                lengthCm: 12.0,
                weightGrams: 100.0,
                description: "Bé đã có thể nghe được âm thanh nhịp tim và giọng nói của mẹ.",
                advice: "Nói chuyện nhẹ nhàng với bé mỗi ngày, tập ngủ nghiêng bên trái."
            )
        case 20...24:
            return FetalMilestone(
                week: clamped,
                fruitComparison: "Bắp ngô ngọt",
                lengthCm: 28.0,
                weightGrams: 450.0,
                description: "Mẹ cảm nhận rõ cú đạp đầu tiên. Lông mày và mí mắt bé đã hoàn chỉnh.",
                advice: "Bổ sung sắt, canxi và xét nghiệm tiểu đường thai kỳ."
            )
        case 25...29:
            return FetalMilestone(
                week: clamped,
                fruitComparison: "Quả cà tím",
                lengthCm: 36.0,
                weightGrams: 1000.0,
                description: "Bước vào tam cá nguyệt 3. Não bộ bé phát triển vượt bậc và bé biết chớp mắt.",
                advice: "Tập đếm cử động thai sau bữa ăn, chuẩn bị giỏ đồ đi sinh."
            )
        default:
            return FetalMilestone(
                week: clamped,
                fruitComparison: "Quả dưa hấu",
                lengthCm: 50.0,
                weightGrams: 3200.0,
                description: "Bé đã sẵn sàng chào đời! Lớp mỡ dưới da đầy đặn và đã quay đầu thuận.",
                advice: "Theo dõi các cơn gò chuyển dạ hoặc dấu hiệu rỉ ối để vào viện kịp thời."
            )
        }
    }
}
