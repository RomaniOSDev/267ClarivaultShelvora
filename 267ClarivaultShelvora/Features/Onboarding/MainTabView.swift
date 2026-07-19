import SwiftUI

enum AppTab: Hashable {
    case showcase
    case media
    case stats
    case settings
}

struct MainTabView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selectedTab: AppTab = .showcase
    @State private var tabBarHiddenCount = 0

    private var showsTabBar: Bool { tabBarHiddenCount == 0 }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .showcase:
                    RatedShowcaseView()
                case .media:
                    MediaHubView(tabBarHiddenCount: $tabBarHiddenCount)
                case .stats:
                    StatsAchievementsView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showsTabBar {
                CustomTabBar(selectedTab: $selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showsTabBar)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab

    private let items: [(AppTab, String, String)] = [
        (.showcase, "house.fill", "Home"),
        (.media, "photo.on.rectangle", "Studio"),
        (.stats, "trophy.fill", "Stats"),
        (.settings, "gearshape.fill", "Settings")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.0) { item in
                Button {
                    FeedbackService.lightTap()
                    selectedTab = item.0
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.1)
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 28, height: 28)
                        Text(item.2)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(selectedTab == item.0 ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if selectedTab == item.0 {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(DepthStyle.primaryButtonGradient)
                            } else {
                                Color.clear
                            }
                        }
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(TabPressStyle())
            }
        }
        .padding(8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(DepthStyle.panelGradient)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(DepthStyle.sheenGradient)
                    .allowsHitTesting(false)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .volumeStroke(emphasized: true, radius: 24)
        .softCardShadow(emphasized: true)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

private struct TabPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

enum TabMetrics {
    static let tabBarClearance: CGFloat = 100
}

struct HidesTabBarModifier: ViewModifier {
    @Binding var tabBarHiddenCount: Int

    func body(content: Content) -> some View {
        content
            .onAppear { tabBarHiddenCount += 1 }
            .onDisappear { tabBarHiddenCount = max(0, tabBarHiddenCount - 1) }
    }
}

extension View {
    func hidesTabBar(count: Binding<Int>) -> some View {
        modifier(HidesTabBarModifier(tabBarHiddenCount: count))
    }
}
