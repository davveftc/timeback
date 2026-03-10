import SwiftUI

/// Root view: shows onboarding on first launch, then the main tab view.
struct ContentView: View {
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete = false
    @EnvironmentObject var appState: AppState

    var body: some View {
        if isOnboardingComplete {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

/// Main tab bar with Home, Modes, and Stats tabs.
struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            ModeListView()
                .tabItem {
                    Label("Modes", systemImage: "square.grid.2x2.fill")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
        }
        .tint(Color(hex: "2E86C1"))
    }
}
