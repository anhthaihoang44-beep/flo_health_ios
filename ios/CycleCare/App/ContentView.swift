import SwiftUI

struct ContentView: View {
    @StateObject private var repository = CycleCareRepository.shared

    @AppStorage("onboarding_completed") private var isOnboardingCompleted = false
    @AppStorage("biometrics_enabled") private var isBiometricsEnabled = false

    @State private var isUnlocked = false
    @State private var authenticationFailed = false

    private let biometric = BiometricAuthManager.shared

    var body: some View {
        ZStack {
            if !isOnboardingCompleted || repository.currentProfile == nil {
                OnboardingView(repository: repository) {
                    isOnboardingCompleted = true
                    isUnlocked = true
                }
            } else if isBiometricsEnabled && !isUnlocked {
                // Biometric Lock Screen Overlay
                biometricLockView
            } else {
                MainTabView(repository: repository)
            }
        }
        .onAppear {
            checkBiometricLock()
        }
    }

    private var biometricLockView: some View {
        ZStack {
            Color.cycleBackground.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.cycleRoseLight.opacity(0.4))
                        .frame(width: 100, height: 100)

                    Image(systemName: "faceid")
                        .font(.system(size: 48))
                        .foregroundColor(.cycleRose)
                }

                VStack(spacing: 8) {
                    Text("CycleCare đang khóa")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Xác thực Face ID hoặc Touch ID để mở khóa dữ liệu sức khỏe của bạn")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                if authenticationFailed {
                    Text("Xác thực không thành công. Vui lòng thử lại.")
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Spacer()

                Button {
                    authenticateWithBiometrics()
                } label: {
                    HStack {
                        Image(systemName: "lock.open.fill")
                        Text("Mở khóa ngay")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.cycleRose)
                    .cornerRadius(26)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
    }

    private func checkBiometricLock() {
        if isBiometricsEnabled {
            isUnlocked = false
            authenticateWithBiometrics()
        } else {
            isUnlocked = true
        }
    }

    private func authenticateWithBiometrics() {
        biometric.authenticateUser(reason: "Mở khóa ứng dụng CycleCare") { success, _ in
            if success {
                isUnlocked = true
                authenticationFailed = false
            } else {
                authenticationFailed = true
            }
        }
    }
}
