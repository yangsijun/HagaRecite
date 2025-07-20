import SwiftUI
import SwiftData

@main
struct HagaReciteApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [RecitationPlan.self, DailyVerse.self, TestResult.self])
    }
} 