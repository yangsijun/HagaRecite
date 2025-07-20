import SwiftUI

// MARK: - 메인 탭 뷰
struct MainTabView: View {
    @StateObject private var planManager = PlanManager()
    @StateObject private var testManager = TestManager()
    
    var body: some View {
        TabView {
            HomeView()
                .environmentObject(planManager)
                .environmentObject(testManager)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("홈")
                }
            
            PlanListView()
                .environmentObject(planManager)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("계획")
                }
            
            TestView()
                .environmentObject(testManager)
                .environmentObject(planManager)
                .tabItem {
                    Image(systemName: "checkmark.circle")
                    Text("테스트")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("설정")
                }
        }
    }
} 