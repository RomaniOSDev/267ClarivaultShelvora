import SwiftUI

struct RateDuelView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = RateDuelViewModel()

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 18) {
                    SectionHeaderView(
                        title: "Rate Duel",
                        subtitle: "Pick the stronger frame — Elo updates instantly",
                        trailing: "\(store.duelComparisonsCompleted)"
                    )

                    SurfaceCard(padding: 12) {
                        HStack {
                            MetricChip(title: "Pool", value: "\(activeCount)", symbol: "square.stack.3d.up")
                            MetricChip(title: "Wins left", value: leftWins, symbol: "arrow.left.circle")
                            MetricChip(title: "Wins right", value: rightWins, symbol: "arrow.right.circle")
                        }
                    }

                    if viewModel.canDuel, let left = viewModel.left, let right = viewModel.right {
                        HStack(alignment: .top, spacing: 12) {
                            DuelPickCell(entry: left, action: viewModel.chooseLeft)
                            DuelPickCell(entry: right, action: viewModel.chooseRight)
                        }

                        Button {
                            viewModel.skipPair()
                        } label: {
                            Text("Skip Pair")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        if let winner = viewModel.lastWinnerTitle, viewModel.showSuccess {
                            Text("Winner: \(winner)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color("AppAccent"))
                        }
                    } else {
                        EmptyStateView(
                            symbol: "rectangle.split.2x1",
                            title: "Need at least 2 entries",
                            subtitle: "Add showcase items first, then compare them side by side."
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, TabMetrics.tabBarClearance)
            }
            .clearScrollBackground()

            SuccessCheckOverlay(isVisible: viewModel.showSuccess)
        }
        .navigationTitle("Rate Duel")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppBackground"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { viewModel.dealPair() }
    }

    private var activeCount: Int {
        store.galleryEntries.filter { $0.decisionStatus != .archived }.count
    }

    private var leftWins: String {
        guard let left = viewModel.left else { return "—" }
        return "\(left.duelWins)"
    }

    private var rightWins: String {
        guard let right = viewModel.right else { return "—" }
        return "\(right.duelWins)"
    }
}
