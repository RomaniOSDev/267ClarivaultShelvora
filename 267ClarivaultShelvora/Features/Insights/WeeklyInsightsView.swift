import SwiftUI

struct WeeklyInsightsView: View {
    @EnvironmentObject private var store: AppDataStore

    private var insights: WeeklyInsightSnapshot {
        store.buildWeeklyInsights()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(
                title: "Weekly Insights",
                subtitle: "Taste patterns from your real actions",
                trailing: "\(insights.reflectionStreak)d"
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                InsightStatCell(title: "Top tag", value: insights.topTag, symbol: "tag.fill")
                InsightStatCell(title: "Avg rating", value: String(format: "%.1f", insights.averageRating), symbol: "star.fill")
                InsightStatCell(title: "Pending", value: "\(insights.pendingDecisions)", symbol: "tray.full")
                InsightStatCell(title: "Duels", value: "\(insights.duelCount)", symbol: "rectangle.split.2x1")
            }

            SurfaceCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text(insights.ratingTrendText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("AppTextPrimary"))

                    ProgressRail(progress: min(insights.averageRating / 5.0, 1.0))

                    Text("Forgotten gems")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppAccent"))
                        .padding(.top, 4)

                    if insights.forgottenGems.isEmpty {
                        Text("Rate a few keepers to surface gems you have not revisited.")
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                    } else {
                        ForEach(insights.forgottenGems) { gem in
                            HStack(spacing: 10) {
                                EmojiBadgeView(emoji: gem.emoji, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(gem.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color("AppTextPrimary"))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                    StarRatingView(rating: gem.rating)
                                }
                                Spacer()
                                VerdictBadge(verdict: gem.intentVerdict)
                            }
                        }
                    }
                }
            }
        }
    }
}
