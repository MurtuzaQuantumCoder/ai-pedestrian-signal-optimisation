import SwiftUI

@main
struct KlikApp: App {
    @StateObject private var locationService = LocationService()
    @StateObject private var historyStore = ActionHistoryStore()
    @StateObject private var agent = PatternLearningAgent()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(locationService)
                .environmentObject(historyStore)
                .environmentObject(agent)
                .onAppear {
                    locationService.requestPermission()
                    agent.bind(to: historyStore)
                }
        }
    }
}
