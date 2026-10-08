# CycleCare - Ứng Dụng Theo Dõi Sức Khỏe Phụ Nữ (MVP)

CycleCare là ứng dụng di động theo dõi chu kỳ kinh nguyệt, rụng trứng và thai kỳ dành cho phụ nữ, được thiết kế theo phong cách tối giản, mềm mại (tông hồng–tím pastel) với tính năng bảo mật dữ liệu y tế nghiêm ngặt, hỗ trợ ngoại tuyến (Offline-First) và đồng bộ đám mây qua Supabase.

---

## 🏗️ 1. Sơ Đồ Kiến Trúc Hệ Thống (Architecture)

Ứng dụng được xây dựng theo mô hình **Clean Architecture + MVVM** kết hợp **Offline-First**:

```
 ┌─────────────────────────────────────────────────────────────┐
 │                      PRESENTATION LAYER                     │
 │   Jetpack Compose + Material 3 Theme (Pastel Tokens)        │
 │   StateFlow ViewModels & Jetpack Navigation Compose         │
 │   (Onboarding, Home Wheel Canvas, Calendar, Daily Log, ...) │
 └──────────────────────────────┬──────────────────────────────┘
                                │
 ┌──────────────────────────────▼──────────────────────────────┐
 │                        DOMAIN LAYER                         │
 │   CyclePredictorEngine (Thuần Kotlin, Không phụ thuộc SDK)   │
 │   Domain Models (UserProfile, Cycle, DailyLog, Article)      │
 └──────────────────────────────┬──────────────────────────────┘
                                │
 ┌──────────────────────────────▼──────────────────────────────┐
 │                         DATA LAYER                          │
 │   CycleCareRepository (Single Source of Truth)              │
 │   ├── Room Local Database (Lưu trữ và cache ngoại tuyến)   │
 │   └── SupabaseManager (Postgrest REST & Anonymous Auth)     │
 └──────────────────────────────┬──────────────────────────────┘
                                │
 ┌──────────────────────────────▼──────────────────────────────┐
 │                    SUPABASE CLOUD BACKEND                   │
 │   PostgreSQL với RLS (Row Level Security) cho mọi bảng      │
 │   Supabase Auth (Anonymous, Email/Password, Link Identity)  │
 └─────────────────────────────────────────────────────────────┘
```

---

## 📋 2. Yêu Cầu Môi Trường & Cài Đặt

- **Hệ điều hành**: Windows 10/11, macOS hoặc Linux
- **JDK**: Java 17 LTS
- **Android SDK**: compileSdk 35, minSdk 26
- **Gradle**: 8.7 (đi kèm Gradle Wrapper)

### Các bước khởi chạy dự án:

1. **Clone repository hoặc mở thư mục dự án**:
   ```bash
   git clone https://gitlab.com/sondeptrai/flo_health_android.git
   cd flo_health_android
   ```

2. **Cấu hình `local.properties`**:
   Tạo hoặc mở file `local.properties` ở thư mục gốc của dự án và điền thông tin sau (file này đã được bảo mật qua `.gitignore`):
   ```properties
   sdk.dir=C\:\\Users\\HP\\AppData\\Local\\Android\\Sdk
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6...
   ```
   *(Lưu ý: Nếu chưa có tài khoản Supabase, ứng dụng sẽ tự động kích hoạt chế độ Offline-First với dữ liệu cục bộ an toàn)*.

3. **Biên dịch và chạy ứng dụng**:
   - Sử dụng PowerShell:
     ```powershell
     .\gradlew.ps1 assembleDebug
     ```
   - Hoặc CMD:
     ```cmd
     gradlew.bat assembleDebug
     ```
   - Hoặc mở trực tiếp dự án trong **Android Studio** và nhấn nút **Run (Shift + F10)**.

---

## 🗄️ 3. Cấu Hình Supabase & Chạy Migration SQL

Toàn bộ database schema và các chính sách bảo mật RLS được định nghĩa trong file:
👉 `supabase/migrations/20261008000000_init_schema.sql`

### Các bước thiết lập trên Supabase:
1. Đăng nhập vào [Supabase Dashboard](https://supabase.com/dashboard) và tạo một dự án mới.
2. Vào tab **SQL Editor** ở thanh menu bên trái.
3. Mở file `supabase/migrations/20261008000000_init_schema.sql`, sao chép toàn bộ nội dung và dán vào SQL Editor.
4. Nhấn **Run** để khởi tạo các bảng:
   - `profiles`: Lưu thông tin chu kỳ và hồ sơ người dùng.
   - `cycles`: Lịch sử các kỳ kinh nguyệt.
   - `daily_logs`: Nhật ký triệu chứng, tâm trạng, cơn đau, giấc ngủ.
   - `pregnancies`: Chế độ theo dõi thai kỳ và ngày dự sinh.
   - `partner_links`: Liên kết chia sẻ dữ liệu an toàn với bạn đời.
   - `reminders`: Danh sách cấu hình nhắc nhở.
   - `articles`: Thư viện kiến thức sức khỏe (kèm seed data).
   - `subscriptions`: Quản lý mô phỏng gói Premium.
5. Vào **Authentication > Providers**:
   - Kích hoạt **Anonymous Sign-ins** (cho phép trải nghiệm app tức thì không cần đăng ký).
   - Kích hoạt **Email** provider.

---

## 🔒 4. Cam Kết Bảo Mật & Quyền Riêng Tư (Privacy)

- **Mặc định bảo mật chặt chẽ**: Toàn bộ các bảng trong database đều được kích hoạt **Row Level Security (RLS)**. Người dùng chỉ có quyền truy xuất dòng dữ liệu có `user_id = auth.uid()`.
- **Không log dữ liệu nhạy cảm**: Không in nhật ký triệu chứng, chu kỳ hay thông tin cá nhân ra log hệ thống.
- **Quyền tự quyết dữ liệu**: Cung cấp tính năng Xuất toàn bộ dữ liệu (JSON) và Xóa sạch dữ liệu vĩnh viễn trong màn hình Cài đặt.
- **Khóa bảo vệ ứng dụng**: Hỗ trợ xác thực sinh trắc học (Vân tay / Khuôn mặt / PIN) qua `BiometricPrompt`.

---

## 🧪 5. Kiểm Thử (Testing)

Chạy bộ unit test tự động cho thuật toán dự đoán chu kỳ:
```bash
.\gradlew.ps1 test
```
Tất cả các ca kiểm thử cho chu kỳ đều, không đều, ngoại lai, năm nhuận và timezone đều được tự động xác minh trước mỗi lần commit.
