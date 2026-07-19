import Foundation
import Combine

final class ReflectionsViewModel: ObservableObject {
    @Published var showEditor = false
    @Published var editingEntry: ReflectionEntry?
    @Published var titleText = ""
    @Published var emoji = "📷"
    @Published var captionText = ""
    @Published var tagsText = ""
    @Published var selectedPrompt = ReflectionPromptCatalog.all[0]
    @Published var titleShake: CGFloat = 0
    @Published var validationMessage: String?
    @Published var showSuccess = false
    @Published var pulseID: UUID?

    private let store: AppDataStore

    init(store: AppDataStore = .shared) {
        self.store = store
    }

    var entries: [ReflectionEntry] {
        store.reflectionEntries.sorted { $0.date > $1.date }
    }

    func openNew() {
        FeedbackService.lightTap()
        editingEntry = nil
        titleText = ""
        emoji = "📷"
        captionText = ""
        tagsText = ""
        selectedPrompt = ReflectionPromptCatalog.random()
        validationMessage = nil
        titleShake = 0
        showEditor = true
    }

    func open(_ entry: ReflectionEntry) {
        FeedbackService.lightTap()
        store.markRecentlyViewed(id: entry.photoId.uuidString)
        editingEntry = entry
        titleText = entry.title
        emoji = entry.emoji
        captionText = entry.caption
        tagsText = entry.tags.joined(separator: ", ")
        selectedPrompt = entry.prompt.isEmpty ? ReflectionPromptCatalog.random() : entry.prompt
        validationMessage = nil
        titleShake = 0
        showEditor = true
    }

    func delete(_ entry: ReflectionEntry) {
        FeedbackService.lightTap()
        store.deleteReflection(id: entry.id)
    }

    func shufflePrompt() {
        FeedbackService.tick()
        FeedbackService.lightTap()
        selectedPrompt = ReflectionPromptCatalog.random(excluding: selectedPrompt)
    }

    func save() {
        let trimmedTitle = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCaption = captionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            FeedbackService.warning()
            validationMessage = "Please enter a title."
            titleShake += 1
            return
        }
        guard !trimmedCaption.isEmpty else {
            FeedbackService.warning()
            validationMessage = "Please answer the reflection prompt."
            titleShake += 1
            return
        }

        let parsedTags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if var existing = editingEntry {
            existing.title = trimmedTitle
            existing.emoji = emoji
            existing.caption = trimmedCaption
            existing.tags = parsedTags
            existing.prompt = selectedPrompt
            existing.date = Date()
            store.updateReflection(existing)
            pulseID = existing.id
        } else {
            let entry = ReflectionEntry(
                title: trimmedTitle,
                emoji: emoji,
                caption: trimmedCaption,
                tags: parsedTags,
                prompt: selectedPrompt
            )
            store.addReflection(entry)
            pulseID = entry.id
        }

        FeedbackService.saveCaption()
        FeedbackService.success()
        showEditor = false
        showSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.showSuccess = false
            self?.pulseID = nil
        }
    }
}
