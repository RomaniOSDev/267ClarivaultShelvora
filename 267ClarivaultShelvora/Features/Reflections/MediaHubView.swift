import SwiftUI

struct MediaHubView: View {
    @Binding var tabBarHiddenCount: Int
    @EnvironmentObject private var store: AppDataStore

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 16) {
                        SectionHeaderView(
                            title: "Media Studio",
                            subtitle: "Compare, decide, auto-group, and journal",
                            trailing: "\(store.pendingDecisionEntries.count) inbox"
                        )

                        HStack(spacing: 10) {
                            MetricChip(title: "Queue", value: "\(store.pendingDecisionEntries.count)", symbol: "tray.full")
                            MetricChip(title: "Rules", value: "\(store.smartCollections.count)", symbol: "slider.horizontal.3")
                            MetricChip(title: "Reflect", value: "\(store.reflectionStreakDays)d", symbol: "text.bubble")
                        }

                        hubLink(
                            title: "Decision Queue",
                            subtitle: "Swipe to Favorite, Showcase, Reflect, or Archive",
                            symbol: "tray.full.fill",
                            badge: store.pendingDecisionEntries.isEmpty ? nil : "\(store.pendingDecisionEntries.count)",
                            destination: DecisionQueueView()
                        )

                        hubLink(
                            title: "Rate Duel",
                            subtitle: "Side-by-side picks with live Elo ranking",
                            symbol: "rectangle.split.2x1.fill",
                            badge: "\(store.duelComparisonsCompleted)",
                            destination: RateDuelView()
                        )

                        hubLink(
                            title: "Smart Collections",
                            subtitle: "Rules rebuild membership as your library changes",
                            symbol: "rectangle.stack.badge.person.crop",
                            badge: "\(store.smartCollections.count)",
                            destination: SmartCollectionsView()
                        )

                        hubLink(
                            title: "Image Reflections",
                            subtitle: "Prompted journaling with answer streaks",
                            symbol: "text.bubble.fill",
                            badge: "\(store.reflectionEntries.count)",
                            destination: ImageReflectionsView(tabBarHiddenCount: $tabBarHiddenCount)
                        )

                        hubLink(
                            title: "Favorites",
                            subtitle: "Quick access to keepers you marked",
                            symbol: "star.circle.fill",
                            badge: "\(store.favorites.count)",
                            destination: PhotoFavoritesView(tabBarHiddenCount: $tabBarHiddenCount)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, TabMetrics.tabBarClearance)
                }
                .clearScrollBackground()
            }
            .navigationTitle("Media Studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .transparentScreenChrome()
    }

    private func hubLink<Destination: View>(
        title: String,
        subtitle: String,
        symbol: String,
        badge: String?,
        destination: Destination
    ) -> some View {
        NavigationLink {
            destination
        } label: {
            HubFeatureCell(title: title, subtitle: subtitle, symbol: symbol, badge: badge)
        }
        .buttonStyle(ScalePressStyle())
        .simultaneousGesture(TapGesture().onEnded {
            FeedbackService.lightTap()
        })
    }
}
