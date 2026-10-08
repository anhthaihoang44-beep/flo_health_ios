package com.cyclecare.app.domain.model

import java.time.LocalDate

data class Pregnancy(
    val id: String,
    val userId: String,
    val lmpDate: LocalDate,
    val dueDate: LocalDate,
    val isActive: Boolean = true,
    val endedAt: LocalDate? = null
)

data class FetalDevelopmentWeek(
    val week: Int,
    val fruitComparison: String,
    val lengthCm: Double,
    val weightGrams: Double,
    val highlights: String,
    val motherTips: String
)

object PregnancyMilestones {
    fun getWeekInfo(week: Int): FetalDevelopmentWeek {
        val clampedWeek = week.coerceIn(4, 40)
        return when (clampedWeek) {
            in 4..6 -> FetalDevelopmentWeek(
                week = clampedWeek,
                fruitComparison = "Hạt mè (Hạt vừng)",
                lengthCm = 0.2,
                weightGrams = 0.5,
                highlights = "Ống thần kinh của bé đang hình thành và tim bắt đầu có những nhịp đập sơ khai đầu tiên.",
                motherTips = "Uống bổ sung Acid Folic (400-600 mcg) mỗi ngày, ngủ đủ giấc và uống nhiều nước."
            )
            in 7..10 -> FetalDevelopmentWeek(
                week = clampedWeek,
                fruitComparison = "Quả mâm xôi",
                lengthCm = 2.3,
                weightGrams = 2.0,
                highlights = "Các ngón tay, ngón chân nhỏ xíu đang tách rời, mí mắt và chóp mũi dần rõ nét.",
                motherTips = "Nếu bị ốm nghén, hãy chia nhỏ bữa ăn thành 5-6 bữa nhẹ và dùng trà gừng ấm."
            )
            in 11..14 -> FetalDevelopmentWeek(
                week = clampedWeek,
                fruitComparison = "Quả chanh vàng",
                lengthCm = 7.4,
                weightGrams = 23.0,
                highlights = "Hoàn tất tam cá nguyệt 1. Bé đã có dấu vân tay riêng và bắt đầu cử động nhẹ nhàng trong bụng mẹ.",
                motherTips = "Thời điểm thích hợp để thực hiện siêu âm đo độ mờ da gáy và xét nghiệm sàng lọc trước sinh."
            )
            in 15..19 -> FetalDevelopmentWeek(
                week = clampedWeek,
                fruitComparison = "Quả bơ sáp",
                lengthCm = 12.0,
                weightGrams = 100.0,
                highlights = "Bé đã có thể nghe được âm thanh từ nhịp tim và giọng nói trầm ấm của mẹ.",
                motherTips = "Hãy trò chuyện nhẹ nhàng với bé mỗi tối và duy trì tư thế ngủ nghiêng về bên trái."
            )
            in 20..24 -> FetalDevelopmentWeek(
                week = clampedWeek,
                fruitComparison = "Bắp ngô ngọt",
                lengthCm = 28.0,
                weightGrams = 450.0,
                highlights = "Bạn có thể cảm nhận rõ những cú đạp đầu tiên (Quickening). Lông mày và mí mắt bé đã hoàn chỉnh.",
                motherTips = "Bổ sung sắt và canxi theo hướng dẫn của bác sĩ, thực hiện nghiệm pháp đường huyết thai kỳ."
            )
            in 25..29 -> FetalDevelopmentWeek(
                week = clampedWeek,
                fruitComparison = "Quả cà tím",
                lengthCm = 36.0,
                weightGrams = 1000.0,
                highlights = "Bước vào tam cá nguyệt 3. Não bộ bé phát triển vượt bậc và bé có thể chớp mắt khi cảm nhận ánh sáng.",
                motherTips = "Tập đếm cử động thai (thai máy) sau bữa ăn, chuẩn bị sẵn giỏ đồ đi sinh."
            )
            in 30..35 -> FetalDevelopmentWeek(
                week = clampedWeek,
                fruitComparison = "Quả dưa lưới",
                lengthCm = 44.0,
                weightGrams = 1900.0,
                highlights = "Hệ miễn dịch và phổi của bé đang hoàn thiện nhanh chóng để chuẩn bị cho thế giới bên ngoài.",
                motherTips = "Tham gia lớp học tiền sản, tập thở và chuẩn bị tâm lý thư giãn trước ngày đón bé."
            )
            else -> FetalDevelopmentWeek(
                week = clampedWeek,
                fruitComparison = "Quả dưa hấu",
                lengthCm = 50.0,
                weightGrams = 3200.0,
                highlights = "Bé đã sẵn sàng chào đời! Lớp mỡ dưới da đầy đặn và bé thường đã quay đầu xuống vùng xương chậu.",
                motherTips = "Theo dõi các dấu hiệu chuyển dạ: cơn co thắt đều đặn, rỉ ối hoặc ra dịch hồng."
            )
        }
    }
}
