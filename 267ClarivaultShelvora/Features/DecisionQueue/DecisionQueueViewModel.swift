import Foundation
import Combine

final class DecisionQueueViewModel: ObservableObject {
    @Published var dragOffsets: [UUID: CGFloat] = [:]
    @Published var showSuccess = false

    private let store: AppDataStore

    init(store: AppDataStore = .shared) {
        self.store = store
    }

    var items: [GalleryEntry] { store.pendingDecisionEntries }

    func apply(_ status: DecisionStatus, to entry: GalleryEntry) {
        FeedbackService.mediumTap()
        store.applyDecision(status, to: entry.id)
        if status == .favorite {
            FeedbackService.favorite()
        } else {
            FeedbackService.success()
        }
        dragOffsets.removeValue(forKey: entry.id)
        showSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            self?.showSuccess = false
        }
    }
}
