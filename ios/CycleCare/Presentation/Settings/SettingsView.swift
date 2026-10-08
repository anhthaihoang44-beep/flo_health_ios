import SwiftUI

struct SettingsView: View {
    @ObservedObject var repository: CycleCareRepository

    @AppStorage("biometrics_enabled") private var isBiometricsEnabled = false
    @AppStorage("reminders_enabled") private var isRemindersEnabled = true
    @AppStorage("reminder_time") private var reminderTimeStorage: Double = 20.0 * 3600 // 20:00 default

    @State private var reminderDate = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var showLinkIdentitySheet = false
    @State private var showExportSheet = false
    @State private var showDeleteConfirmAlert = false
    @State private var exportedJsonString = ""

    private let biometric = BiometricAuthManager.shared
    private let notifications = NotificationManager.shared
    private let healthKit = HealthKitManager.shared

    private var profile: UserProfile {
        repository.currentProfile ?? UserProfile()
    }

    var body: some View {
        NavigationStack {
            List {
                // Section: User Profile
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(LinearGradient(colors: [.cycleRose, .cycleLavender], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Text(profile.displayName.prefix(1).uppercased())
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile.displayName)
                                .font(.headline)

                            HStack(spacing: 6) {
                                Text(profile.goal.titleVi)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.cycleRoseLight)
                                    .foregroundColor(.cycleRose)
                                    .cornerRadius(8)

                                if profile.isAnonymous {
                                    Text("Tài khoản ẩn danh")
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.gray.opacity(0.15))
                                        .foregroundColor(.secondary)
                                        .cornerRadius(8)
                                } else {
                                    Text("Đã liên kết")
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.15))
                                        .foregroundColor(.green)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    if profile.isAnonymous {
                        Button {
                            showLinkIdentitySheet = true
                        } label: {
                            HStack {
                                Image(systemName: "envelope.badge")
                                    .foregroundColor(.cycleRose)
                                Text("Liên kết Email để bảo lưu dữ liệu")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Hồ sơ người dùng")
                }

                // Section: Security & Privacy
                Section {
                    Toggle(isOn: $isBiometricsEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "faceid")
                                .foregroundColor(.cycleRose)
                            VStack(alignment: .leading) {
                                Text("Khóa bằng Face ID / Touch ID")
                                    .font(.subheadline)
                                Text("Bảo vệ dữ liệu riêng tư khi mở app")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onChange(of: isBiometricsEnabled) { enabled in
                        if enabled {
                            biometric.authenticateUser(reason: "Bật bảo mật Face ID cho CycleCare") { success, _ in
                                if !success {
                                    isBiometricsEnabled = false
                                }
                            }
                        }
                    }

                    Button {
                        healthKit.requestAuthorization { success, _ in
                            // UI feedback
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.periodRed)
                            VStack(alignment: .leading) {
                                Text("Đồng bộ Apple Health")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Text("Chia sẻ dữ liệu kinh nguyệt với ứng dụng Sức khỏe")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Bảo mật & Tích hợp")
                }

                // Section: Reminders & Notifications
                Section {
                    Toggle(isOn: $isRemindersEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.cycleLavender)
                            Text("Nhắc nhở chu kỳ & uống thuốc")
                                .font(.subheadline)
                        }
                    }
                    .onChange(of: isRemindersEnabled) { enabled in
                        if enabled {
                            notifications.requestPermission { granted in
                                if granted {
                                    notifications.scheduleDailyLogReminder(at: reminderDate)
                                }
                            }
                        } else {
                            notifications.cancelAllReminders()
                        }
                    }

                    if isRemindersEnabled {
                        DatePicker(
                            "Giờ nhắc hàng ngày",
                            selection: $reminderDate,
                            displayedComponents: [.hourAndMinute]
                        )
                        .font(.subheadline)
                        .onChange(of: reminderDate) { newDate in
                            notifications.scheduleDailyLogReminder(at: newDate)
                        }
                    }
                } header: {
                    Text("Thông báo")
                }

                // Section: Data Ownership & GDPR
                Section {
                    Button {
                        exportedJsonString = repository.exportAllUserDataJson()
                        showExportSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("Xuất toàn bộ dữ liệu (JSON)")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }

                    Button(role: .destructive) {
                        showDeleteConfirmAlert = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("Xóa vĩnh viễn tài khoản & dữ liệu")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text("Dữ liệu & Quyền riêng tư")
                }

                // Section: Medical Disclaimer & Info
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "cross.case.fill")
                                .foregroundColor(.cycleRose)
                            Text("Tuyên bố miễn trừ trách nhiệm y tế")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        Text("CycleCare không phải là thiết bị y tế và không đưa ra chẩn đoán lâm sàng. Các dự đoán chu kỳ chỉ mang tính chất tham khảo dựa trên thuật toán thống kê. Vui lòng tham khảo ý kiến bác sĩ phụ khoa khi có dấu hiệu bất thường.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    .padding(.vertical, 4)

                    HStack {
                        Text("Phiên bản")
                            .font(.subheadline)
                        Spacer()
                        Text("CycleCare 1.0.0 (Build 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Thông tin pháp lý")
                }
            }
            .navigationTitle("Cài đặt")
            .sheet(isPresented: $showLinkIdentitySheet) {
                LinkIdentitySheet(repository: repository)
            }
            .sheet(isPresented: $showExportSheet) {
                ExportDataSheet(jsonString: exportedJsonString)
            }
            .alert("Xác nhận xóa toàn bộ dữ liệu?", isPresented: $showDeleteConfirmAlert) {
                Button("Hủy", role: .cancel) {}
                Button("Xóa vĩnh viễn", role: .destructive) {
                    repository.clearAllData()
                }
            } message: {
                Text("Hành động này sẽ xóa sạch dữ liệu chu kỳ, nhật ký sức khỏe trên thiết bị này và không thể phục hồi.")
            }
        }
    }
}

// MARK: - Link Identity Sheet
struct LinkIdentitySheet: View {
    @ObservedObject var repository: CycleCareRepository
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var successAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Bảo vệ dữ liệu chu kỳ của bạn khi đổi điện thoại hoặc đăng nhập nhiều thiết bị.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Email của bạn", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Mật khẩu mới", text: $password)
                } header: {
                    Text("Thông tin đăng nhập")
                }

                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Button {
                        linkAccount()
                    } label: {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Liên kết tài khoản")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                    }
                    .listRowBackground(Color.cycleRose)
                    .disabled(email.isEmpty || password.count < 6 || isLoading)
                }
            }
            .navigationTitle("Nâng cấp tài khoản")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
            .alert("Liên kết thành công!", isPresented: $successAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Tài khoản của bạn đã được liên kết với email \(email).")
            }
        }
    }

    private func linkAccount() {
        isLoading = true
        errorMessage = nil

        Task {
            let res = await repository.linkIdentity(email: email, pass: password)
            await MainActor.run {
                isLoading = false
                switch res {
                case .success:
                    successAlert = true
                case .failure(let err):
                    errorMessage = err
                }
            }
        }
    }
}

// MARK: - Export Data Sheet
struct ExportDataSheet: View {
    let jsonString: String
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ScrollView {
                    Text(jsonString)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.cycleSurfaceVariant)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                HStack(spacing: 12) {
                    Button {
                        UIPasteboard.general.string = jsonString
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copied = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            Text(copied ? "Đã sao chép!" : "Sao chép JSON")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.cycleRose)
                        .cornerRadius(25)
                    }

                    ShareLink(item: jsonString) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.cycleLavender)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle("Dữ liệu cá nhân JSON")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") {
                        dismiss()
                    }
                }
            }
        }
    }
}
