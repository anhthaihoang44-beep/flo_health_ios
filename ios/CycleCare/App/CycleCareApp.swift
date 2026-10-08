import SwiftUI

@main
struct CycleCareApp: App {
    @StateObject private var repository = CycleCareRepository.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(repository)
        }
    }
}
