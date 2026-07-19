import SwiftUI

struct SmartCollectionsView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = SmartCollectionsViewModel()

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 16) {
                    SectionHeaderView(
                        title: "Smart Collections",
                        subtitle: "Membership updates automatically from your rules",
                        trailing: "\(viewModel.collections.count)"
                    )

                    if viewModel.collections.isEmpty {
                        EmptyStateView(
                            symbol: "rectangle.stack.badge.person.crop",
                            title: "No smart collections",
                            subtitle: "Create a rule like Rating ≥ 4, tag evening, or last week only."
                        )
                    } else {
                        ForEach(viewModel.collections) { collection in
                            Button {
                                FeedbackService.lightTap()
                                viewModel.selectedCollection = collection
                            } label: {
                                CollectionRuleCell(
                                    collection: collection,
                                    matchCount: viewModel.matchedCount(for: collection),
                                    summary: ruleSummary(collection)
                                )
                            }
                            .buttonStyle(ScalePressStyle())
                            .contextMenu {
                                Button("Edit") { viewModel.openEdit(collection) }
                                Button("Delete", role: .destructive) { viewModel.delete(collection) }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, TabMetrics.tabBarClearance + 80)
            }
            .clearScrollBackground()

            VStack {
                Spacer()
                FloatingBottomBar {
                    Button {
                        viewModel.openNew()
                    } label: {
                        Text("Add Collection Rule")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.bottom, 8)
            }
        }
        .navigationTitle("Smart Collections")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppBackground"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $viewModel.showEditor) {
            collectionEditor
        }
        .sheet(item: $viewModel.selectedCollection) { collection in
            collectionDetail(collection)
        }
    }

    private func ruleSummary(_ collection: SmartCollection) -> String {
        var parts: [String] = []
        if collection.minRating > 0 { parts.append("Rating ≥ \(collection.minRating)") }
        if !collection.requiredTag.isEmpty { parts.append("Tag: \(collection.requiredTag)") }
        if collection.onlyLastWeek { parts.append("Last 7 days") }
        if !collection.verdictFilter.isEmpty { parts.append("Verdict: \(collection.verdictFilter)") }
        return parts.isEmpty ? "All active entries" : parts.joined(separator: " · ")
    }

    private var collectionEditor: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        FormFieldLabel(text: "Name")
                        AppTextFieldChrome {
                            TextField("Evening keepers", text: $viewModel.nameText)
                        }
                        .modifier(ShakeEffect(animatableData: viewModel.nameShake))

                        if let validationMessage = viewModel.validationMessage {
                            Text(validationMessage)
                                .font(.caption)
                                .foregroundStyle(Color.red.opacity(0.9))
                        }

                        FormFieldLabel(text: "Minimum rating")
                        SurfaceCard(padding: 10) {
                            Picker("Min rating", selection: $viewModel.minRating) {
                                Text("Any").tag(0)
                                ForEach(1...5, id: \.self) { value in
                                    Text("\(value)+").tag(value)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        FormFieldLabel(text: "Required tag")
                        AppTextFieldChrome {
                            TextField("evening, trip…", text: $viewModel.tagText)
                        }

                        Toggle(isOn: $viewModel.onlyLastWeek) {
                            Text("Only last 7 days")
                                .foregroundStyle(Color("AppTextPrimary"))
                        }
                        .tint(Color("AppAccent"))
                        .padding(14)
                        .background(Color("AppSurface"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        FormFieldLabel(text: "Intent verdict filter")
                        SurfaceCard(padding: 10) {
                            Picker("Verdict", selection: $viewModel.verdictFilter) {
                                Text("Any").tag("")
                                Text("Keep").tag(IntentVerdict.keep.rawValue)
                                Text("Revisit").tag(IntentVerdict.revisit.rawValue)
                                Text("Archive").tag(IntentVerdict.archive.rawValue)
                            }
                            .pickerStyle(.segmented)
                        }

                        Button {
                            viewModel.save()
                        } label: {
                            Text("Save Rule")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(20)
                }
                .clearScrollBackground()
            }
            .navigationTitle(viewModel.editing == nil ? "New Collection" : "Edit Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        FeedbackService.lightTap()
                        viewModel.showEditor = false
                    }
                    .foregroundStyle(Color("AppAccent"))
                }
            }
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func collectionDetail(_ collection: SmartCollection) -> some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    let matches = store.entries(matching: collection)
                    VStack(spacing: 14) {
                        SectionHeaderView(
                            title: collection.name,
                            subtitle: ruleSummary(collection),
                            trailing: "\(matches.count)"
                        )

                        if matches.isEmpty {
                            EmptyStateView(
                                symbol: "line.3.horizontal.decrease.circle",
                                title: "No matches yet",
                                subtitle: "Add or rate entries that fit this rule."
                            )
                        } else {
                            ForEach(matches) { entry in
                                GalleryEntryCell(entry: entry, showsElo: true)
                            }
                        }
                    }
                    .padding(20)
                }
                .clearScrollBackground()
            }
            .navigationTitle(collection.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        FeedbackService.lightTap()
                        viewModel.selectedCollection = nil
                    }
                    .foregroundStyle(Color("AppAccent"))
                }
            }
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
