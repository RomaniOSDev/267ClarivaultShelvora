import Foundation
import Combine

final class SmartCollectionsViewModel: ObservableObject {
    @Published var showEditor = false
    @Published var editing: SmartCollection?
    @Published var nameText = ""
    @Published var minRating = 4
    @Published var tagText = ""
    @Published var onlyLastWeek = false
    @Published var verdictFilter = ""
    @Published var nameShake: CGFloat = 0
    @Published var validationMessage: String?
    @Published var selectedCollection: SmartCollection?

    private let store: AppDataStore

    init(store: AppDataStore = .shared) {
        self.store = store
    }

    var collections: [SmartCollection] {
        store.smartCollections.sorted { $0.dateCreated > $1.dateCreated }
    }

    func openNew() {
        FeedbackService.lightTap()
        editing = nil
        nameText = ""
        minRating = 4
        tagText = ""
        onlyLastWeek = false
        verdictFilter = ""
        validationMessage = nil
        nameShake = 0
        showEditor = true
    }

    func openEdit(_ collection: SmartCollection) {
        FeedbackService.lightTap()
        editing = collection
        nameText = collection.name
        minRating = collection.minRating
        tagText = collection.requiredTag
        onlyLastWeek = collection.onlyLastWeek
        verdictFilter = collection.verdictFilter
        validationMessage = nil
        nameShake = 0
        showEditor = true
    }

    func delete(_ collection: SmartCollection) {
        FeedbackService.lightTap()
        store.deleteSmartCollection(id: collection.id)
    }

    func save() {
        let trimmed = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            FeedbackService.warning()
            validationMessage = "Please enter a collection name."
            nameShake += 1
            return
        }

        if var existing = editing {
            existing.name = trimmed
            existing.minRating = minRating
            existing.requiredTag = tagText.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.onlyLastWeek = onlyLastWeek
            existing.verdictFilter = verdictFilter
            store.updateSmartCollection(existing)
        } else {
            let collection = SmartCollection(
                name: trimmed,
                minRating: minRating,
                requiredTag: tagText.trimmingCharacters(in: .whitespacesAndNewlines),
                onlyLastWeek: onlyLastWeek,
                verdictFilter: verdictFilter
            )
            store.addSmartCollection(collection)
        }

        FeedbackService.saveEntry()
        FeedbackService.success()
        showEditor = false
    }

    func matchedCount(for collection: SmartCollection) -> Int {
        store.entries(matching: collection).count
    }
}
