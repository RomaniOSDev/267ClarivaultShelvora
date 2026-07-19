import Foundation
import Combine

final class FavoritesViewModel: ObservableObject {
    @Published var selectedEntry: GalleryEntry?
    @Published var showRecentSheet = false
    @Published var showDetail = false
    @Published var pulseID: String?

    private let store: AppDataStore

    init(store: AppDataStore = .shared) {
        self.store = store
    }

    var favoriteEntries: [GalleryEntry] {
        store.favorites.compactMap { store.galleryEntry(for: $0) }
    }

    var recentEntries: [GalleryEntry] {
        store.recentlyViewed.compactMap { store.galleryEntry(for: $0) }
    }

    func toggleFavorite(_ entry: GalleryEntry) {
        let id = entry.id.uuidString
        if store.isFavorite(id: id) {
            FeedbackService.lightTap()
            store.toggleFavorite(id: id)
        } else {
            FeedbackService.favorite()
            store.toggleFavorite(id: id)
            pulseID = id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.pulseID = nil
            }
        }
    }

    func openDetail(_ entry: GalleryEntry) {
        FeedbackService.lightTap()
        store.markRecentlyViewed(id: entry.id.uuidString)
        selectedEntry = entry
        showDetail = true
    }

    func openRecent() {
        FeedbackService.lightTap()
        showRecentSheet = true
    }

    func moveFavorites(from source: IndexSet, to destination: Int) {
        store.reorderFavorites(from: source, to: destination)
    }
}
