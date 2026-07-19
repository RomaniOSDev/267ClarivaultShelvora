import SwiftUI

struct DecisionQueueView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = DecisionQueueViewModel()

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 16) {
                    SectionHeaderView(
                        title: "Decision inbox",
                        subtitle: "Clear the queue to keep your library intentional",
                        trailing: "\(viewModel.items.count)"
                    )

                    if viewModel.items.isEmpty {
                        EmptyStateView(
                            symbol: "checkmark.seal.fill",
                            title: "Inbox clear",
                            subtitle: "New showcase entries land here until you decide."
                        )
                    } else {
                        ForEach(viewModel.items) { entry in
                            DecisionQueueCell(entry: entry) { status in
                                viewModel.apply(status, to: entry)
                            }
                            .offset(x: viewModel.dragOffsets[entry.id] ?? 0)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        viewModel.dragOffsets[entry.id] = value.translation.width
                                    }
                                    .onEnded { value in
                                        let width = value.translation.width
                                        if width > 80 {
                                            viewModel.apply(.favorite, to: entry)
                                        } else if width < -80 {
                                            viewModel.apply(.archived, to: entry)
                                        } else {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                viewModel.dragOffsets[entry.id] = 0
                                            }
                                        }
                                    }
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, TabMetrics.tabBarClearance)
            }
            .clearScrollBackground()

            SuccessCheckOverlay(isVisible: viewModel.showSuccess)
        }
        .navigationTitle("Decision Queue")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppBackground"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
