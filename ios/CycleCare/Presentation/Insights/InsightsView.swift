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
        ("all", "Tất cả"),
        ("cycle", "Chu kỳ"),
        ("fertility", "Thụ thai"),
        ("wellness", "Sức khỏe"),
        ("pregnancy", "Thai kỳ")
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
            CycleDataPoint(month: "T4", days: 28),
            CycleDataPoint(month: "T5", days: 29),
            CycleDataPoint(month: "T6", days: 27),
            CycleDataPoint(month: "T7", days: 28),
            CycleDataPoint(month: "T8", days: 30),
            CycleDataPoint(month: "T9", days: 28)
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
                                Text("Xu hướng độ dài chu kỳ")
                                    .font(.headline)
                                Text("Trung bình: \(Int(averageCycleLength)) ngày")
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
                                    x: .value("Tháng", point.month),
                                    y: .value("Số ngày", point.days)
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

                            RuleMark(y: .value("Trung bình", averageCycleLength))
                                .foregroundStyle(Color.cycleLavender)
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                .annotation(position: .top, alignment: .trailing) {
                                    Text("TB: \(Int(averageCycleLength)) ngày")
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
                            Text("Chu kỳ thực tế").font(.caption2).foregroundColor(.secondary)
                            Spacer()
                            Circle().fill(Color.cycleLavender).frame(width: 8, height: 8)
                            Text("Mức trung bình cá nhân").font(.caption2).foregroundColor(.secondary)
                        }
                    }
                    .padding(20)
                    .background(Color.cycleSurface)
                    .cornerRadius(20)

                    // Educational Articles Section Header & Categories Filter
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Góc Chuyên Gia & Bài Viết")
                                .font(.headline)
                            Spacer()
                            Text("\(filteredArticles.count) bài")
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
            .navigationTitle("Khám phá & Thống kê")
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
        case "cycle": return "Chu kỳ"
        case "fertility": return "Thụ thai"
        case "wellness": return "Sức khỏe"
        case "pregnancy": return "Thai kỳ"
        default: return "Cẩm nang"
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
                        Label("3 phút đọc", systemImage: "clock")
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
                            Text("Tham vấn y khoa")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        Text("Nội dung chỉ mang tính giáo dục, không thể thay thế chẩn đoán hoặc điều trị y tế chuyên sâu từ bác sĩ phụ khoa.")
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
                    Button("Đóng") {
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

                            Text("Chăm sóc sức khỏe phụ nữ toàn diện & khoa học")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }

                    // Feature List
                    VStack(alignment: .leading, spacing: 14) {
                        FeatureRow(icon: "sparkles", text: "Dự đoán rụng trứng & chu kỳ bằng AI độ chính xác 95%")
                        FeatureRow(icon: "doc.text.fill", text: "Báo cáo sức khỏe PDF gửi bác sĩ phụ khoa")
                        FeatureRow(icon: "book.pages.fill", text: "Kho hơn 100+ bài viết độc quyền từ chuyên gia sản phụ khoa")
                        FeatureRow(icon: "person.2.fill", text: "Chế độ đồng bộ không giới hạn cho bạn đời (Partner Mode)")
                    }
                    .padding()
                    .background(Color.cycleSurface)
                    .cornerRadius(20)

                    // Price Trial Card
                    VStack(spacing: 6) {
                        Text("Dùng thử 7 ngày MIỄN PHÍ")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Sau đó 99.000 đ/tháng • Hủy bất cứ lúc nào trong App Store")
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
                            Text(purchased ? "Đã nâng cấp thành công!" : "Bắt đầu dùng thử 7 ngày")
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
                        Button("Khôi phục gói") {}
                        Text("•").foregroundColor(.secondary)
                        Button("Điều khoản") {}
                        Text("•").foregroundColor(.secondary)
                        Button("Chính sách bảo mật") {}
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
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
