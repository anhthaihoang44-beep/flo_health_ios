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
                    Label("Home", systemImage: "circle.circle")
                }
                .tag(0)

            CalendarView(repository: repository) { date in
                logDateForTab = date
                selectedTab = 2
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
            .tag(1)

            DailyLogView(repository: repository, initialDate: logDateForTab)
                .tabItem {
                    Label("Daily Log", systemImage: "plus.circle.fill")
                }
                .tag(2)

            InsightsView(repository: repository)
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.xaxis")
                }
                .tag(3)

            SettingsView(repository: repository)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(Color.cycleRose)
    }
}
