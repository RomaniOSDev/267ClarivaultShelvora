import SwiftUI

struct ContentView: View {
    @ObservedObject private var store = AppDataStore.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            AppBackgroundView()

            Group {
                if store.hasSeenOnboarding {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(store)
            .transition(.opacity)

            if let achievement = store.pendingAchievementBanner {
                VStack {
                    AchievementBannerView(achievement: achievement)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(10)
                    Spacer()
                }
                .padding(.top, 8)
                .allowsHitTesting(false)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            store.dismissAchievementBanner()
                        }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.hasSeenOnboarding)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: store.pendingAchievementBanner?.id)
        .preferredColorScheme(.dark)
        .onAppear {
            store.startSessionTracking()
            store.evaluateAchievements()
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                store.startSessionTracking()
            case .inactive, .background:
                store.pauseSessionTracking()
            @unknown default:
                break
            }
        }
    }
}

#Preview {
    ContentView()
}
