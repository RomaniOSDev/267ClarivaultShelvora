import Foundation
import Combine

final class RatedShowcaseViewModel: ObservableObject {
    @Published var titleText = ""
    @Published var noteText = ""
    @Published var emoji = "⭐️"
    @Published var rating = 4
    @Published var quality = 3
    @Published var emotion = 3
    @Published var keepForever = 3
    @Published var tagsText = ""
    @Published var showAddSheet = false
    @Published var editingEntry: GalleryEntry?
    @Published var showSuccess = false
    @Published var titleShake: CGFloat = 0
    @Published var validationMessage: String?
    @Published var highlightEntryID: UUID?

    private let store: AppDataStore

    init(store: AppDataStore = .shared) {
        self.store = store
    }

    var entries: [GalleryEntry] {
        store.galleryEntries
            .filter { $0.decisionStatus != .archived }
            .sorted { $0.dateAdded > $1.dateAdded }
    }

    var previewVerdict: IntentVerdict {
        IntentVerdict.from(quality: quality, emotion: emotion, keepForever: keepForever)
    }

    func openAddSheet() {
        FeedbackService.lightTap()
        editingEntry = nil
        titleText = ""
        noteText = ""
        emoji = "⭐️"
        rating = 4
        quality = 3
        emotion = 3
        keepForever = 3
        tagsText = ""
        validationMessage = nil
        titleShake = 0
        showAddSheet = true
    }

    func openEdit(_ entry: GalleryEntry) {
        FeedbackService.lightTap()
        store.markRecentlyViewed(id: entry.id.uuidString)
        editingEntry = entry
        titleText = entry.title
        noteText = entry.note
        emoji = entry.emoji
        rating = entry.rating
        quality = entry.quality
        emotion = entry.emotion
        keepForever = entry.keepForever
        tagsText = entry.tags.joined(separator: ", ")
        validationMessage = nil
        titleShake = 0
        showAddSheet = true
    }

    func delete(_ entry: GalleryEntry) {
        FeedbackService.lightTap()
        store.deleteGalleryEntry(id: entry.id)
    }

    func save() {
        let trimmed = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            FeedbackService.warning()
            validationMessage = "Please enter a title."
            titleShake += 1
            return
        }

        let parsedTags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let moodAverage = Int(round(Double(quality + emotion + keepForever) / 3.0))
        let resolvedRating = max(rating, moodAverage)

        if var existing = editingEntry {
            existing.title = trimmed
            existing.note = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.emoji = emoji
            existing.rating = resolvedRating
            existing.quality = quality
            existing.emotion = emotion
            existing.keepForever = keepForever
            existing.tags = parsedTags
            store.updateGalleryEntry(existing)
            highlightEntryID = existing.id
        } else {
            let entry = GalleryEntry(
                title: trimmed,
                emoji: emoji,
                note: noteText.trimmingCharacters(in: .whitespacesAndNewlines),
                rating: resolvedRating,
                quality: quality,
                emotion: emotion,
                keepForever: keepForever,
                tags: parsedTags,
                decisionStatus: .pending
            )
            store.addGalleryEntry(entry)
            highlightEntryID = entry.id
        }

        FeedbackService.saveEntry()
        FeedbackService.success()
        showAddSheet = false
        withSuccessAnimation()
    }

    private func withSuccessAnimation() {
        showSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.showSuccess = false
            self?.highlightEntryID = nil
        }
    }
}
