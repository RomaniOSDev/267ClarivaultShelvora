import SwiftUI

struct StatsAchievementsView: View {
    @EnvironmentObject private var store: AppDataStore

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 18) {
                        SectionHeaderView(
                            title: "Activity",
                            subtitle: "Sessions, reflection streak, and time invested"
                        )

                        summaryCard
                        WeeklyInsightsView()

                        Button {
                            FeedbackService.lightTap()
                            ExportShareService.presentSummary(from: store)
                        } label: {
                            Label("Export Summary", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        SectionHeaderView(
                            title: "Achievements",
                            subtitle: "Decorative milestones from real usage",
                            trailing: "\(unlockedCount)/8"
                        )

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(AchievementCatalog.all) { achievement in
                                AchievementCell(
                                    achievement: achievement,
                                    unlocked: store.achievementsUnlocked[achievement.id] != nil,
                                    unlockedDate: store.achievementsUnlocked[achievement.id]
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, TabMetrics.tabBarClearance)
                }
                .clearScrollBackground()
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .transparentScreenChrome()
    }

    private var unlockedCount: Int {
        AchievementCatalog.all.filter { store.achievementsUnlocked[$0.id] != nil }.count
    }

    private var summaryCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    MetricChip(title: "Ratings", value: "\(store.itemsAdded)", symbol: "star.fill")
                    MetricChip(title: "Sessions", value: "\(store.entriesWritten)", symbol: "bolt.fill")
                    MetricChip(title: "Reflect", value: "\(store.reflectionStreakDays)d", symbol: "text.bubble")
                }

                ProgressRail(progress: minutesProgress)
                Text("Active time: \(formattedMinutes)")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
    }

    private var minutesProgress: Double {
        min(Double(store.totalMinutes) / 3600.0, 1.0)
    }

    private var formattedMinutes: String {
        let total = store.totalMinutes
        return "\(total / 60)m \(total % 60)s"
    }
}
