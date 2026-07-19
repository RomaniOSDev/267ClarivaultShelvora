import Foundation
import Combine

final class RateDuelViewModel: ObservableObject {
    @Published var left: GalleryEntry?
    @Published var right: GalleryEntry?
    @Published var showSuccess = false
    @Published var lastWinnerTitle: String?

    private let store: AppDataStore

    init(store: AppDataStore = .shared) {
        self.store = store
        dealPair()
    }

    var canDuel: Bool {
        store.galleryEntries.filter { $0.decisionStatus != .archived }.count >= 2
    }

    func dealPair() {
        let pool = store.galleryEntries.filter { $0.decisionStatus != .archived }
        guard pool.count >= 2 else {
            left = nil
            right = nil
            return
        }
        let shuffled = pool.shuffled()
        left = shuffled[0]
        right = shuffled[1]
    }

    func chooseLeft() {
        guard let left, let right else { return }
        pick(winner: left, loser: right)
    }

    func chooseRight() {
        guard let left, let right else { return }
        pick(winner: right, loser: left)
    }

    func skipPair() {
        FeedbackService.lightTap()
        dealPair()
    }

    private func pick(winner: GalleryEntry, loser: GalleryEntry) {
        FeedbackService.mediumTap()
        store.resolveDuel(winnerID: winner.id, loserID: loser.id)
        lastWinnerTitle = winner.title
        showSuccess = true
        FeedbackService.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.showSuccess = false
            self?.dealPair()
        }
    }
}
