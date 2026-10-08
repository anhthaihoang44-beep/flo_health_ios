import SwiftUI

struct MainTabView: View {
    @ObservedObject var repository: CycleCareRepository
    @State private var selectedTab = 0
    @State private var logDateForTab: Date = Date()
    @State private var showLogModal = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(repository: repository, selectedTab: $selectedTab)
                .tabItem {
                    Label("Trang chủ", systemImage: "circle.circle")
                }
                .tag(0)

            CalendarView(repository: repository) { date in
                logDateForTab = date
                selectedTab = 2
            }
            .tabItem {
                Label("Lịch", systemImage: "calendar")
            }
            .tag(1)

            DailyLogView(repository: repository, initialDate: logDateForTab)
                .tabItem {
                    Label("Nhật ký", systemImage: "plus.circle.fill")
                }
                .tag(2)

            InsightsView(repository: repository)
                .tabItem {
                    Label("Khám phá", systemImage: "chart.bar.xaxis")
                }
                .tag(3)

            SettingsView(repository: repository)
                .tabItem {
                    Label("Cài đặt", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(Color.cycleRose)
    }
}
