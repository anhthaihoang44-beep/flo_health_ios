import SwiftUI

struct OnboardingView: View {
    @ObservedObject var repository: CycleCareRepository
    var onComplete: () -> Void

    @State private var step = 1
    @State private var selectedGoal: HealthGoal = .track
    @State private var cycleLength: Double = 28
    @State private var periodLength: Double = 5
    @State private var lastPeriodDate: Date = Calendar.current.date(byAdding: .day, value: -12, to: Date()) ?? Date()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.cycleBackground, Color.cycleRoseLight.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                if step == 1 {
                    goalSelectionStep
                } else if step == 2 {
                    cycleParametersStep
                } else {
                    finalStep
                }
            }
            .padding(24)
        }
    }

    private var goalSelectionStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Welcome to CycleCare")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.primary)

            Text("Choose your primary health goal so we can tailor predictions specifically for you.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                ForEach(HealthGoal.allCases, id: \.self) { goal in
                    let isSelected = goal == selectedGoal
                    Button {
                        selectedGoal = goal
                    } label: {
                        HStack {
                            Text(goal.titleEn)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.cycleRose)
                                    .font(.title3)
                            }
                        }
                        .padding(20)
                        .background(isSelected ? Color.cycleRoseLight.opacity(0.5) : Color.cycleSurface)
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(isSelected ? Color.cycleRose : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                        )
                    }
                }
            }

            Spacer()

            Button {
                step = 2
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.cycleRose)
                    .foregroundColor(.white)
                    .cornerRadius(27)
            }
        }
    }

    private var cycleParametersStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Cycle Parameters")
                .font(.system(size: 28, weight: .bold))

            Text("Helps our algorithms accurately forecast your fertile window and next cycle.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Cycle Length Card
            VStack(alignment: .leading, spacing: 10) {
                Text("How long is your menstrual cycle?")
                    .font(.headline)
                Text("\(Int(cycleLength)) days")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.cycleRose)
                Slider(value: $cycleLength, in: 21...40, step: 1)
                    .tint(.cycleRose)
            }
            .padding(20)
            .background(Color.cycleSurface)
            .cornerRadius(20)

            // Period Length Card
            VStack(alignment: .leading, spacing: 10) {
                Text("How many days does your period last?")
                    .font(.headline)
                Text("\(Int(periodLength)) days")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.cycleLavender)
                Slider(value: $periodLength, in: 2...10, step: 1)
                    .tint(.cycleLavender)
            }
            .padding(20)
            .background(Color.cycleSurface)
            .cornerRadius(20)

            Spacer()

            Button {
                step = 3
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.cycleRose)
                    .foregroundColor(.white)
                    .cornerRadius(27)
            }
        }
    }

    private var finalStep: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.cycleRoseLight)
                    .frame(width: 100, height: 100)
                Image(systemName: "heart.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.cycleRose)
            }

            Text("You're All Set!")
                .font(.system(size: 28, weight: .bold))

            Text("CycleCare is strictly committed to protecting your private health data. 100% on-device encryption and no third-party data tracking.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Button {
                completeOnboarding(isAnonymous: true)
            } label: {
                HStack {
                    Image(systemName: "person.crop.circle")
                    Text("Start Instantly (100% Anonymous)")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.cycleRose)
                .foregroundColor(.white)
                .cornerRadius(27)
            }

            Button {
                completeOnboarding(isAnonymous: false)
            } label: {
                Text("Register Account")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.clear)
                    .foregroundColor(.cycleRose)
                    .overlay(
                        RoundedRectangle(cornerRadius: 27)
                            .stroke(Color.cycleRose, lineWidth: 1.5)
                    )
            }
        }
    }

    private func completeOnboarding(isAnonymous: Bool) {
        let uid = repository.getOrCreateUserId()
        let profile = UserProfile(
            id: uid,
            displayName: isAnonymous ? "Anonymous User" : "You",
            goal: selectedGoal,
            avgCycleLength: Int(cycleLength),
            avgPeriodLength: Int(periodLength),
            isAnonymous: isAnonymous,
            lastPeriodStartDate: lastPeriodDate
        )
        repository.saveProfile(profile)
        repository.logPeriodStart(date: lastPeriodDate)
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
        onComplete()
    }
}
