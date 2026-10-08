import SwiftUI
import Charts

struct CycleDataPoint: Identifiable {
    let id = UUID()
    let month: String
    let days: Int
}

struct InsightsView: View {
    @ObservedObject var repository: CycleCareRepository

    @State private var selectedCategory: String = "all"
    @State private var selectedArticle: Article? = nil
    @State private var showPaywall = false

    private let categories = [
        ("all", "All"),
        ("cycle", "Cycle"),
        ("fertility", "Fertility"),
        ("wellness", "Wellness"),
        ("pregnancy", "Pregnancy")
    ]

    private var chartData: [CycleDataPoint] {
        if !repository.cycles.isEmpty {
            let sorted = repository.cycles.sorted { $0.startDate < $1.startDate }
            return sorted.suffix(6).enumerated().map { index, cycle in
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/yy"
                let monthLabel = formatter.string(from: cycle.startDate)
                return CycleDataPoint(month: monthLabel, days: cycle.cycleLength ?? (repository.currentProfile?.avgCycleLength ?? 28))
            }
        }
        // Simulated default historical trends for a great visual experience
        return [
            CycleDataPoint(month: "May", days: 28),
            CycleDataPoint(month: "Jun", days: 29),
            CycleDataPoint(month: "Jul", days: 27),
            CycleDataPoint(month: "Aug", days: 28),
            CycleDataPoint(month: "Sep", days: 30),
            CycleDataPoint(month: "Oct", days: 28)
        ]
    }

    private var averageCycleLength: Double {
        Double(repository.currentProfile?.avgCycleLength ?? 28)
    }

    private var filteredArticles: [Article] {
        if selectedCategory == "all" {
            return repository.articles
        }
        return repository.articles.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Swift Charts Card: 6-Month Cycle Trend
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Cycle Length Trends")
                                    .font(.headline)
                                Text("Average: \(Int(averageCycleLength)) days")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chart.bar.xaxis")
                                .foregroundColor(.cycleRose)
                                .font(.title3)
                        }

                        // Swift Charts Bar Plot
                        Chart {
                            ForEach(chartData) { point in
                                BarMark(
                                    x: .value("Month", point.month),
                                    y: .value("Days", point.days)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.cycleRose, .cycleRoseLight],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .cornerRadius(6)
                            }

                            RuleMark(y: .value("Average", averageCycleLength))
                                .foregroundStyle(Color.cycleLavender)
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                .annotation(position: .top, alignment: .trailing) {
                                    Text("Avg: \(Int(averageCycleLength))d")
                                        .font(.caption2)
                                        .foregroundColor(.cycleLavender)
                                        .padding(.horizontal, 4)
                                        .background(Color.cycleSurface)
                                }
                        }
                        .frame(height: 180)
                        .chartYScale(domain: 20...40)

                        HStack {
                            Circle().fill(Color.cycleRose).frame(width: 8, height: 8)
                            Text("Actual cycle").font(.caption2).foregroundColor(.secondary)
                            Spacer()
                            Circle().fill(Color.cycleLavender).frame(width: 8, height: 8)
                            Text("Personal average").font(.caption2).foregroundColor(.secondary)
                        }
                    }
                    .padding(20)
                    .background(Color.cycleSurface)
                    .cornerRadius(20)

                    // Educational Articles Section Header & Categories Filter
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Expert Insights & Articles")
                                .font(.headline)
                            Spacer()
                            Text("\(filteredArticles.count) articles")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.0) { cat in
                                    let isSelected = selectedCategory == cat.0
                                    Button {
                                        selectedCategory = cat.0
                                    } label: {
                                        Text(cat.1)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(isSelected ? Color.cycleRose : Color.cycleSurfaceVariant)
                                            .foregroundColor(isSelected ? .white : .primary)
                                            .cornerRadius(20)
                                    }
                                }
                            }
                        }

                        // Article List
                        LazyVStack(spacing: 12) {
                            ForEach(filteredArticles) { article in
                                ArticleCard(article: article) {
                                    if article.isPremium {
                                        showPaywall = true
                                    } else {
                                        selectedArticle = article
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.cycleBackground.ignoresSafeArea())
            .navigationTitle("Insights & Statistics")
            .sheet(item: $selectedArticle) { article in
                ArticleDetailSheet(article: article)
            }
            .sheet(isPresented: $showPaywall) {
                PremiumPaywallSheet()
            }
        }
    }
}

// MARK: - Article Card Component
struct ArticleCard: View {
    let article: Article
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Category Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(article.isPremium ? Color.cycleLavenderLight : Color.cycleRoseLight)
                        .frame(width: 50, height: 50)

                    Image(systemName: iconName(for: article.category))
                        .foregroundColor(article.isPremium ? .cycleLavender : .cycleRose)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if article.isPremium {
                            HStack(spacing: 2) {
                                Image(systemName: "crown.fill")
                                Text("PREMIUM")
                            }
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(6)
                        }

                        Text(categoryLabel(for: article.category))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Text(article.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    Text(article.body)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(Color.cycleSurface)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    private func iconName(for category: String) -> String {
        switch category {
        case "cycle": return "calendar.circle.fill"
        case "fertility": return "sparkles"
        case "wellness": return "heart.text.square.fill"
        case "pregnancy": return "figure.and.child.holdinghands"
        default: return "book.closed.fill"
        }
    }

    private func categoryLabel(for category: String) -> String {
        switch category {
        case "cycle": return "Cycle"
        case "fertility": return "Fertility"
        case "wellness": return "Wellness"
        case "pregnancy": return "Pregnancy"
        default: return "Guide"
        }
    }
}

// MARK: - Article Detail Sheet
struct ArticleDetailSheet: View {
    let article: Article
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(article.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack {
                        Label(article.category.capitalized, systemImage: "tag.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Label("3 min read", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    Text(article.body)
                        .font(.body)
                        .lineSpacing(6)

                    // Medical note disclaimer
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "shield.lefthalf.filled")
                                .foregroundColor(.cycleRose)
                            Text("Medical Disclaimer")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        Text("This content is intended for educational purposes only and does not replace personalized medical advice from a gynecologist.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.cycleSurfaceVariant)
                    .cornerRadius(12)
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Premium Paywall Sheet (Flo inspired)
struct PremiumPaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var purchased = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Banner
                    ZStack {
                        LinearGradient(
                            colors: [.cycleRose, .cycleLavender],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 180)
                        .cornerRadius(24)

                        VStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.yellow)

                            Text("CycleCare Premium")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text("Comprehensive & scientific women's health companion")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }

                    // Feature List
                    VStack(alignment: .leading, spacing: 14) {
                        FeatureRow(icon: "sparkles", text: "AI-powered cycle & ovulation prediction with 95% accuracy")
                        FeatureRow(icon: "doc.text.fill", text: "Exportable monthly PDF health reports for your doctor")
                        FeatureRow(icon: "book.pages.fill", text: "100+ exclusive articles by OB-GYN & fertility experts")
                        FeatureRow(icon: "person.2.fill", text: "Unlimited partner synchronization (Partner Mode)")
                    }
                    .padding()
                    .background(Color.cycleSurface)
                    .cornerRadius(20)

                    // Price Trial Card
                    VStack(spacing: 6) {
                        Text("Start 7-Day FREE Trial")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Then $4.99/month • Cancel anytime in App Store")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.cycleSurfaceVariant)
                    .cornerRadius(16)

                    // Subscribe Button
                    Button {
                        isPurchasing = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            isPurchasing = false
                            purchased = true
                        }
                    } label: {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(purchased ? "Upgraded Successfully!" : "Start 7-Day Free Trial")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(purchased ? Color.green : Color.cycleRose)
                    .cornerRadius(26)
                    .disabled(isPurchasing || purchased)

                    // Footer links
                    HStack(spacing: 20) {
                        Button("Restore Purchases") {}
                        Text("•").foregroundColor(.secondary)
                        Button("Terms of Service") {}
                        Text("•").foregroundColor(.secondary)
                        Button("Privacy Policy") {}
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.cycleRose)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
        }
    }
}
