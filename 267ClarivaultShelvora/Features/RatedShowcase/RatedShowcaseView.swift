import SwiftUI

struct RatedShowcaseView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = RatedShowcaseViewModel()
    @State private var heroAppeared = false

    private let topPreviewLimit = 5

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 18) {
                        HomeHeroBanner()
                            .scaleEffect(heroAppeared ? 1 : 0.96)
                            .opacity(heroAppeared ? 1 : 0)
                            .animation(.spring(response: 0.45, dampingFraction: 0.78), value: heroAppeared)

                        HStack(spacing: 10) {
                            MetricChip(title: "Entries", value: "\(viewModel.entries.count)", symbol: "square.stack.3d.up")
                            MetricChip(title: "Queue", value: "\(store.pendingDecisionEntries.count)", symbol: "tray.full")
                            MetricChip(title: "Avg", value: averageRatingText, symbol: "star.fill")
                        }

                        SectionHeaderView(
                            title: "Quick actions",
                            subtitle: "Jump into the curation workflow"
                        )

                        VStack(spacing: 12) {
                            NavigationLink {
                                DecisionQueueView()
                            } label: {
                                HomeActionImageCard(
                                    title: "Decision Queue",
                                    subtitle: "Swipe and sort pending frames",
                                    imageName: "home_queue",
                                    badge: store.pendingDecisionEntries.isEmpty ? nil : "\(store.pendingDecisionEntries.count)"
                                )
                            }
                            .buttonStyle(ScalePressStyle())
                            .simultaneousGesture(TapGesture().onEnded { FeedbackService.lightTap() })

                            NavigationLink {
                                RateDuelView()
                            } label: {
                                HomeActionImageCard(
                                    title: "Rate Duel",
                                    subtitle: "Compare two cards and update Elo",
                                    imageName: "home_duel",
                                    badge: "\(store.duelComparisonsCompleted)"
                                )
                            }
                            .buttonStyle(ScalePressStyle())
                            .simultaneousGesture(TapGesture().onEnded { FeedbackService.lightTap() })

                            NavigationLink {
                                SmartCollectionsView()
                            } label: {
                                HomeActionImageCard(
                                    title: "Smart Collections",
                                    subtitle: "Auto-group by rating, tags, and intent",
                                    imageName: "home_collections",
                                    badge: "\(store.smartCollections.count)"
                                )
                            }
                            .buttonStyle(ScalePressStyle())
                            .simultaneousGesture(TapGesture().onEnded { FeedbackService.lightTap() })
                        }

                        if viewModel.entries.isEmpty {
                            HomeEmptyArtCard()
                        } else {
                            SectionHeaderView(
                                title: "Recent entries",
                                subtitle: "Tap to edit mood, tags, and notes",
                                trailing: "\(viewModel.entries.count)"
                            )

                            if let top = topRanked {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Top ranked")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color("AppAccent"))
                                    GalleryEntryCell(entry: top, highlighted: true)
                                        .onTapGesture {
                                            FeedbackService.lightTap()
                                            viewModel.openEdit(top)
                                        }
                                }
                            }

                            LazyVStack(spacing: 12) {
                                ForEach(previewEntries) { entry in
                                    GalleryEntryCell(
                                        entry: entry,
                                        highlighted: viewModel.highlightEntryID == entry.id
                                    )
                                    .scaleEffect(viewModel.highlightEntryID == entry.id ? 1.02 : 1)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.highlightEntryID)
                                    .contextMenu {
                                        Button("Edit") { viewModel.openEdit(entry) }
                                        Button("Delete", role: .destructive) { viewModel.delete(entry) }
                                        Button(store.isFavorite(id: entry.id.uuidString) ? "Remove Favorite" : "Add Favorite") {
                                            if store.isFavorite(id: entry.id.uuidString) {
                                                FeedbackService.lightTap()
                                            } else {
                                                FeedbackService.favorite()
                                            }
                                            store.toggleFavorite(id: entry.id.uuidString)
                                        }
                                    }
                                    .onTapGesture {
                                        FeedbackService.lightTap()
                                        viewModel.openEdit(entry)
                                    }
                                }
                            }

                            if viewModel.entries.count > topPreviewLimit {
                                Text("Showing latest \(topPreviewLimit) of \(viewModel.entries.count)")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, TabMetrics.tabBarClearance + 88)
                }
                .clearScrollBackground()

                VStack {
                    Spacer()
                    FloatingBottomBar {
                        HStack(spacing: 10) {
                            NavigationLink {
                                DecisionQueueView()
                            } label: {
                                Label("Queue", systemImage: "tray.full")
                                    .font(.subheadline.weight(.bold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(Color("AppPrimary").opacity(0.4))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .simultaneousGesture(TapGesture().onEnded { FeedbackService.lightTap() })

                            Button {
                                viewModel.openAddSheet()
                            } label: {
                                Text("Add Entry")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    }
                    .padding(.bottom, TabMetrics.tabBarClearance - 12)
                }

                SuccessCheckOverlay(isVisible: viewModel.showSuccess)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $viewModel.showAddSheet) {
                EntryEditorSheet(viewModel: viewModel)
            }
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                    heroAppeared = true
                }
            }
        }
        .transparentScreenChrome()
    }

    private var averageRatingText: String {
        guard !viewModel.entries.isEmpty else { return "—" }
        let avg = viewModel.entries.map { Double($0.rating) }.reduce(0, +) / Double(viewModel.entries.count)
        return String(format: "%.1f", avg)
    }

    private var previewEntries: [GalleryEntry] {
        Array(viewModel.entries.prefix(topPreviewLimit))
    }

    private var topRanked: GalleryEntry? {
        viewModel.entries.max(by: { $0.eloRating < $1.eloRating })
    }
}

private struct EntryEditorSheet: View {
    @ObservedObject var viewModel: RatedShowcaseViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        FormFieldLabel(text: "Title")
                        AppTextFieldChrome {
                            TextField("Entry title", text: $viewModel.titleText)
                        }
                        .modifier(ShakeEffect(animatableData: viewModel.titleShake))

                        if let validationMessage = viewModel.validationMessage {
                            Text(validationMessage)
                                .font(.caption)
                                .foregroundStyle(Color.red.opacity(0.9))
                        }

                        FormFieldLabel(text: "Notes")
                        AppTextFieldChrome {
                            TextEditor(text: $viewModel.noteText)
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                        }

                        FormFieldLabel(text: "Emoji")
                        EmojiPickerView(selected: $viewModel.emoji)

                        FormFieldLabel(text: "Tags")
                        AppTextFieldChrome {
                            TextField("evening, trip, calm", text: $viewModel.tagsText)
                        }

                        SectionHeaderView(title: "Mood & Intent", subtitle: "Three axes drive Keep / Revisit / Archive")

                        AxisRatingRow(title: "Quality", value: $viewModel.quality)
                        AxisRatingRow(title: "Emotion", value: $viewModel.emotion)
                        AxisRatingRow(title: "Keep forever", value: $viewModel.keepForever)

                        SurfaceCard(padding: 12) {
                            HStack {
                                Text("Suggested action")
                                    .foregroundStyle(Color("AppTextSecondary"))
                                Spacer()
                                VerdictBadge(verdict: viewModel.previewVerdict)
                            }
                        }

                        FormFieldLabel(text: "Overall stars")
                        SurfaceCard(padding: 12) {
                            HStack(spacing: 10) {
                                ForEach(1...5, id: \.self) { value in
                                    Button {
                                        FeedbackService.lightTap()
                                        viewModel.rating = value
                                    } label: {
                                        Image(systemName: value <= viewModel.rating ? "star.fill" : "star")
                                            .font(.title2)
                                            .foregroundStyle(Color("AppAccent"))
                                            .frame(width: 44, height: 44)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Button {
                            viewModel.save()
                        } label: {
                            Text(viewModel.editingEntry == nil ? "Save Entry" : "Update Entry")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.top, 4)
                    }
                    .padding(20)
                }
                .clearScrollBackground()
            }
            .navigationTitle(viewModel.editingEntry == nil ? "New Entry" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        FeedbackService.lightTap()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppAccent"))
                }
            }
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.large])
    }
}
