# CycleCare - Ứng Dụng Theo Dõi Sức Khỏe Phụ Nữ (iOS)

> Lấy cảm hứng từ Flo Health, được xây dựng theo chuẩn Clean Architecture + MVVM + Repository với SwiftUI hiện đại, iOS 16+.

---

## 📱 Kiến Trúc & Công Nghệ

- **Ngôn ngữ**: Swift 5.9+
- **Giao diện**: SwiftUI (iOS 16+), thiết kế chuẩn Apple Human Interface Guidelines với tông màu Flo (Rose, Lavender, Peach, Dark Mode hỗ trợ).
- **Thống kê & Biểu đồ**: Swift Charts (`import Charts`) hiển thị xu hướng chu kỳ 6 tháng.
- **Sức khỏe**: Apple HealthKit (`HKCategoryTypeIdentifier.menstrualFlow`) đồng bộ hai chiều.
- **Bảo mật sinh trắc**: `LocalAuthentication` (Face ID / Touch ID) khóa ứng dụng khi mở.
- **Lưu trữ an toàn**: `Keychain` (lưu User ID & Anonymous Auth Token), `UserDefaults` & JSON cục bộ (offline-first).
- **Thông báo**: `UserNotifications` tự động nhắc ghi nhật ký và dự đoán ngày kinh.
- **Mô hình kiến trúc**:
  - `Domain/`: Models (`UserProfile`, `Cycle`, `DailyLog`, `Pregnancy`, `Article`), Prediction Engine (`CyclePredictorEngine`).
  - `Data/`: Local (`LocalStorageManager`), Remote (`SupabaseManager`), Repositories (`CycleCareRepository`).
  - `Core/`: Theme, HealthKit, Notifications, Security.
  - `Presentation/`:
    - `Onboarding`: Khảo sát mục tiêu 3 bước, tùy chọn dùng ẩn danh không cần tài khoản.
    - `Home`: Vòng tròn chu kỳ Flo động, chỉ báo khả năng thụ thai, mẹo sức khỏe theo pha.
    - `Calendar`: Lịch tháng màu pastel, đánh dấu ngày kinh, rụng trứng, mở nhanh nhật ký.
    - `Log`: Ghi nhận lưu lượng máu, tâm trạng (emoji), triệu chứng, mức đau bụng, nhu cầu sinh lý, giấc ngủ, dịch âm đạo, ghi chú.
    - `Insights`: Biểu đồ Swift Charts, thư viện bài viết phân loại, màn hình mua gói Flo Premium paywall.
    - `Pregnancy`: Tuần thai, so sánh kích thước bé với hoa quả, bộ đếm thai máy (kick counter), lời khuyên y khoa.
    - `Settings`: Bật/tắt Face ID, đồng bộ Apple Health, hẹn giờ nhắc nhở, liên kết Email (Link Identity), xuất JSON dữ liệu cá nhân, xóa vĩnh viễn dữ liệu.

---

## 🚀 Hướng Dẫn Mở & Chạy Trên Mac / Xcode

### Cách 1: Mở trực tiếp với Xcode (Khuyên dùng)
1. Mở thư mục `ios` trên máy Mac:
   ```bash
   cd ios
   xed .
   # Hoặc mở file Package.swift bằng Xcode:
   open Package.swift
   ```
2. Trong Xcode: Chọn thiết bị giả lập (ví dụ `iPhone 15 Pro` hoặc `iPhone 16`) hoặc máy iPhone thật của bạn.
3. Nhấn **Cmd + R** để Build & Chạy app.
4. Nhấn **Cmd + U** để chạy toàn bộ Unit Tests (`CyclePredictorEngineTests`).

### Cách 2: Tạo Xcode App Project từ thư mục nguồn
Nếu bạn muốn tạo file `.xcodeproj` truyền thống:
1. Mở Xcode -> **File > New > Project...** -> Chọn **iOS > App**.
2. Đặt tên: `CycleCare`, Organization Identifier: `com.cyclecare`.
3. Kéo toàn bộ thư mục `ios/CycleCare` và `ios/CycleCareTests` vào project navigator trong Xcode.
4. Trong **Signing & Capabilities**:
   - Thêm capability **HealthKit** (nếu dùng thiết bị thật).
   - Thêm capability **Push Notifications**.

---

## 🔒 Cấu Hình Secrets (Supabase)

1. Sao chép template:
   ```bash
   cp ios/Secrets.xcconfig.template ios/Secrets.xcconfig
   ```
2. Điền Supabase URL và Supabase Anon Key từ bảng điều khiển dự án của bạn:
   ```xcconfig
   SUPABASE_URL = https://your-project.supabase.co
   SUPABASE_ANON_KEY = your-anon-key-here
   ```

---

## 📤 Đẩy Code Lên GitLab Repository

Repository iOS: `https://gitlab.com/sondeptrai/flo_health_ios`

Để đẩy toàn bộ mã nguồn iOS lên GitLab:
```bash
git remote add origin-ios https://gitlab.com/sondeptrai/flo_health_ios.git
git push origin-ios main
```
