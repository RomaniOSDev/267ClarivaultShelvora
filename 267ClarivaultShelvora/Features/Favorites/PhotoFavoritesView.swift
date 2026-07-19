import SwiftUI
import UniformTypeIdentifiers

struct PhotoFavoritesView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = FavoritesViewModel()
    @Binding var tabBarHiddenCount: Int
    @State private var draggingID: String?

    private var bottomInset: CGFloat {
        _ = tabBarHiddenCount
        return TabMetrics.tabBarClearance
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 16) {
                    SectionHeaderView(
                        title: "Favorites",
                        subtitle: "Drag tiles to reorder · swipe rows to remove",
                        trailing: "\(viewModel.favoriteEntries.count)"
                    )

                    if viewModel.favoriteEntries.isEmpty {
                        EmptyStateView(
                            symbol: "star.circle",
                            title: "No Favorites Yet",
                            subtitle: "Mark showcase entries as favorites from Rated Showcase or Decision Queue."
                        )
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.favoriteEntries) { entry in
                                favoriteCell(entry)
                            }
                        }

                        SectionHeaderView(title: "Manage list", subtitle: "Swipe to remove, drag handles to reorder")

                        ForEach(viewModel.favoriteEntries) { entry in
                            GalleryEntryCell(entry: entry, showsElo: false)
                                .contextMenu {
                                    Button("Open") { viewModel.openDetail(entry) }
                                    Button("Remove Favorite", role: .destructive) {
                                        viewModel.toggleFavorite(entry)
                                    }
                                }
                                .onTapGesture {
                                    viewModel.openDetail(entry)
                                }
                                .swipeActionsCompat {
                                    viewModel.toggleFavorite(entry)
                                }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, bottomInset + 80)
            }
            .clearScrollBackground()

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        viewModel.openRecent()
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(Color("AppPrimary"))
                                    .overlay(Circle().stroke(Color("AppAccent").opacity(0.4), lineWidth: 1))
                            )
                    }
                    .buttonStyle(ScalePressStyle())
                    .padding(.trailing, 20)
                    .padding(.bottom, bottomInset)
                }
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppBackground"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $viewModel.showDetail) {
            if let entry = viewModel.selectedEntry {
                FavoriteDetailSheet(entry: entry, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $viewModel.showRecentSheet) {
            RecentItemsSheet(viewModel: viewModel)
        }
    }

    private func favoriteCell(_ entry: GalleryEntry) -> some View {
        Button {
            viewModel.openDetail(entry)
        } label: {
            MediaGridCell(
                emoji: entry.emoji,
                title: entry.title,
                subtitle: "\(entry.rating)/5 · \(entry.intentVerdict.title)",
                isFavorite: true,
                highlighted: viewModel.pulseID == entry.id.uuidString
            )
            .opacity(draggingID == entry.id.uuidString ? 0.7 : 1)
        }
        .buttonStyle(ScalePressStyle())
        .onDrag {
            FeedbackService.lightTap()
            draggingID = entry.id.uuidString
            return NSItemProvider(object: entry.id.uuidString as NSString)
        }
        .onDrop(of: [.text], delegate: FavoriteDropDelegate(
            targetID: entry.id.uuidString,
            favorites: store.favorites,
            draggingID: $draggingID,
            onMove: { from, to in
                store.reorderFavorites(from: IndexSet(integer: from), to: to)
            }
        ))
        .contextMenu {
            Button("Remove Favorite", role: .destructive) {
                viewModel.toggleFavorite(entry)
            }
        }
    }
}

private extension View {
    func swipeActionsCompat(remove: @escaping () -> Void) -> some View {
        self
            .gesture(
                DragGesture(minimumDistance: 40)
                    .onEnded { value in
                        if value.translation.width < -80 {
                            FeedbackService.lightTap()
                            remove()
                        }
                    }
            )
    }
}

private struct FavoriteDropDelegate: DropDelegate {
    let targetID: String
    let favorites: [String]
    @Binding var draggingID: String?
    let onMove: (Int, Int) -> Void

    func performDrop(info: DropInfo) -> Bool {
        draggingID = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggingID,
              draggingID != targetID,
              let from = favorites.firstIndex(of: draggingID),
              let to = favorites.firstIndex(of: targetID) else { return }
        onMove(from, to > from ? to + 1 : to)
    }
}

private struct FavoriteDetailSheet: View {
    let entry: GalleryEntry
    @ObservedObject var viewModel: FavoritesViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(spacing: 16) {
                        GalleryEntryCell(entry: entry)
                        Button {
                            viewModel.toggleFavorite(entry)
                            dismiss()
                        } label: {
                            Text("Remove from Favorites")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(20)
                }
                .clearScrollBackground()
            }
            .navigationTitle("Favorites")
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
    }
}

private struct RecentItemsSheet: View {
    @ObservedObject var viewModel: FavoritesViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(spacing: 12) {
                        SectionHeaderView(title: "Recently Viewed", subtitle: "Jump back into entries you opened")

                        if viewModel.recentEntries.isEmpty {
                            EmptyStateView(
                                symbol: "clock",
                                title: "No recent items",
                                subtitle: "Open showcase entries to build your recently viewed list."
                            )
                        } else {
                            ForEach(viewModel.recentEntries) { entry in
                                Button {
                                    dismiss()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        viewModel.openDetail(entry)
                                    }
                                } label: {
                                    GalleryEntryCell(entry: entry, showsElo: false)
                                }
                                .buttonStyle(ScalePressStyle())
                            }
                        }
                    }
                    .padding(20)
                }
                .clearScrollBackground()
            }
            .navigationTitle("Recently Viewed")
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
    }
}
