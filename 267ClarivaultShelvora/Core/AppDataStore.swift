import Foundation
import Combine

final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    private let defaults = UserDefaults.standard
    private var sessionStartedAt: Date?
    private var cancellables = Set<AnyCancellable>()

    @Published var hasSeenOnboarding: Bool {
        didSet { defaults.set(hasSeenOnboarding, forKey: Keys.hasSeenOnboarding) }
    }

    @Published var galleryEntries: [GalleryEntry] {
        didSet { saveCodable(galleryEntries, key: Keys.galleryEntries) }
    }

    @Published var reflectionEntries: [ReflectionEntry] {
        didSet {
            saveCodable(reflectionEntries, key: Keys.reflectionEntries)
            syncReflectionArrays()
        }
    }

    @Published var smartCollections: [SmartCollection] {
        didSet { saveCodable(smartCollections, key: Keys.smartCollections) }
    }

    @Published var favorites: [String] {
        didSet { defaults.set(favorites, forKey: Keys.favorites) }
    }

    @Published var recentlyViewed: [String] {
        didSet { defaults.set(recentlyViewed, forKey: Keys.recentlyViewed) }
    }

    @Published var totalSessionsCompleted: Int {
        didSet { defaults.set(totalSessionsCompleted, forKey: Keys.totalSessionsCompleted) }
    }

    @Published var totalMinutesUsed: Int {
        didSet { defaults.set(totalMinutesUsed, forKey: Keys.totalMinutesUsed) }
    }

    @Published var streakDays: Int {
        didSet { defaults.set(streakDays, forKey: Keys.streakDays) }
    }

    @Published var reflectionStreakDays: Int {
        didSet { defaults.set(reflectionStreakDays, forKey: Keys.reflectionStreakDays) }
    }

    @Published var lastReflectionAnswerDate: Date? {
        didSet { saveOptionalDate(lastReflectionAnswerDate, key: Keys.lastReflectionAnswerDate) }
    }

    @Published var lastActivityDate: Date? {
        didSet { saveOptionalDate(lastActivityDate, key: Keys.lastActivityDate) }
    }

    @Published var duelComparisonsCompleted: Int {
        didSet { defaults.set(duelComparisonsCompleted, forKey: Keys.duelComparisonsCompleted) }
    }

    @Published var previousWeekAverageRating: Double {
        didSet { defaults.set(previousWeekAverageRating, forKey: Keys.previousWeekAverageRating) }
    }

    @Published var lastInsightSnapshotDate: Date? {
        didSet { saveOptionalDate(lastInsightSnapshotDate, key: Keys.lastInsightSnapshotDate) }
    }

    @Published var achievementsUnlocked: [String: Date] {
        didSet { saveCodable(achievementsUnlocked, key: Keys.achievementsUnlocked) }
    }

    @Published var pendingAchievementBanner: AchievementDefinition?

    private var achievementQueue: [AchievementDefinition] = []
    private var isShowingAchievementBanner = false

    var itemsAdded: Int { galleryEntries.count }
    var entriesWritten: Int { totalSessionsCompleted }
    var totalMinutes: Int { totalMinutesUsed }

    var captions: [String] { reflectionEntries.map(\.caption) }
    var photoIds: [UUID] { reflectionEntries.map(\.photoId) }
    var dates: [Date] { reflectionEntries.map(\.date) }
    var tags: [String] { reflectionEntries.flatMap(\.tags) + galleryEntries.flatMap(\.tags) }

    var pendingDecisionEntries: [GalleryEntry] {
        galleryEntries
            .filter { $0.decisionStatus == .pending }
            .sorted { $0.dateAdded > $1.dateAdded }
    }

    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let galleryEntries = "galleryEntries"
        static let reflectionEntries = "reflectionEntries"
        static let smartCollections = "smartCollections"
        static let captions = "captions"
        static let photoIds = "photoIds"
        static let dates = "dates"
        static let tags = "tags"
        static let favorites = "favorites"
        static let recentlyViewed = "recentlyViewed"
        static let totalSessionsCompleted = "totalSessionsCompleted"
        static let totalMinutesUsed = "totalMinutesUsed"
        static let streakDays = "streakDays"
        static let reflectionStreakDays = "reflectionStreakDays"
        static let lastReflectionAnswerDate = "lastReflectionAnswerDate"
        static let lastActivityDate = "lastActivityDate"
        static let duelComparisonsCompleted = "duelComparisonsCompleted"
        static let previousWeekAverageRating = "previousWeekAverageRating"
        static let lastInsightSnapshotDate = "lastInsightSnapshotDate"
        static let achievementsUnlocked = "achievementsUnlocked"
        static let entryDateAdded = "entryDateAdded"
    }

    private init() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        galleryEntries = Self.loadCodable([GalleryEntry].self, key: Keys.galleryEntries) ?? []
        reflectionEntries = Self.loadCodable([ReflectionEntry].self, key: Keys.reflectionEntries) ?? []
        smartCollections = Self.loadCodable([SmartCollection].self, key: Keys.smartCollections) ?? []
        favorites = defaults.stringArray(forKey: Keys.favorites) ?? []
        recentlyViewed = defaults.stringArray(forKey: Keys.recentlyViewed) ?? []
        totalSessionsCompleted = defaults.integer(forKey: Keys.totalSessionsCompleted)
        totalMinutesUsed = defaults.integer(forKey: Keys.totalMinutesUsed)
        streakDays = defaults.integer(forKey: Keys.streakDays)
        reflectionStreakDays = defaults.integer(forKey: Keys.reflectionStreakDays)
        lastReflectionAnswerDate = Self.loadOptionalDateValue(Keys.lastReflectionAnswerDate)
        lastActivityDate = Self.loadOptionalDateValue(Keys.lastActivityDate)
        duelComparisonsCompleted = defaults.integer(forKey: Keys.duelComparisonsCompleted)
        previousWeekAverageRating = defaults.double(forKey: Keys.previousWeekAverageRating)
        lastInsightSnapshotDate = Self.loadOptionalDateValue(Keys.lastInsightSnapshotDate)
        achievementsUnlocked = Self.loadCodable([String: Date].self, key: Keys.achievementsUnlocked) ?? [:]
        syncReflectionArrays()
        refreshWeeklyInsightBaselineIfNeeded()

        NotificationCenter.default.publisher(for: .dataReset)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.reloadFromDefaults()
            }
            .store(in: &cancellables)
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
        recordMeaningfulAction()
    }

    func addGalleryEntry(_ entry: GalleryEntry) {
        var saved = entry
        if saved.decisionStatus != .archived {
            saved.decisionStatus = .pending
        }
        galleryEntries.insert(saved, at: 0)
        defaults.set(saved.dateAdded.timeIntervalSince1970, forKey: Keys.entryDateAdded)
        recordMeaningfulAction()
        completeSession()
        evaluateAchievements()
    }

    func updateGalleryEntry(_ entry: GalleryEntry) {
        guard let index = galleryEntries.firstIndex(where: { $0.id == entry.id }) else { return }
        galleryEntries[index] = entry
        recordMeaningfulAction()
        evaluateAchievements()
    }

    func deleteGalleryEntry(id: UUID) {
        galleryEntries.removeAll { $0.id == id }
        let idString = id.uuidString
        favorites.removeAll { $0 == idString }
        recentlyViewed.removeAll { $0 == idString }
        evaluateAchievements()
    }

    func applyDecision(_ status: DecisionStatus, to entryID: UUID) {
        guard let index = galleryEntries.firstIndex(where: { $0.id == entryID }) else { return }
        var entry = galleryEntries[index]
        entry.decisionStatus = status
        entry.lastOpenedAt = Date()
        galleryEntries[index] = entry

        let idString = entryID.uuidString
        switch status {
        case .favorite:
            if !favorites.contains(idString) {
                favorites.insert(idString, at: 0)
            }
        case .archived:
            favorites.removeAll { $0 == idString }
        case .showcase, .needsReflection, .pending:
            break
        }

        recordMeaningfulAction()
        completeSession()
        evaluateAchievements()
    }

    func resolveDuel(winnerID: UUID, loserID: UUID) {
        guard let winnerIndex = galleryEntries.firstIndex(where: { $0.id == winnerID }),
              let loserIndex = galleryEntries.firstIndex(where: { $0.id == loserID }) else { return }

        var winner = galleryEntries[winnerIndex]
        var loser = galleryEntries[loserIndex]
        EloEngine.apply(winner: &winner, loser: &loser)
        winner.lastOpenedAt = Date()
        loser.lastOpenedAt = Date()
        galleryEntries[winnerIndex] = winner
        galleryEntries[loserIndex] = loser
        duelComparisonsCompleted += 1
        recordMeaningfulAction()
        completeSession()
        evaluateAchievements()
    }

    func addSmartCollection(_ collection: SmartCollection) {
        smartCollections.insert(collection, at: 0)
        recordMeaningfulAction()
        completeSession()
    }

    func updateSmartCollection(_ collection: SmartCollection) {
        guard let index = smartCollections.firstIndex(where: { $0.id == collection.id }) else { return }
        smartCollections[index] = collection
        recordMeaningfulAction()
    }

    func deleteSmartCollection(id: UUID) {
        smartCollections.removeAll { $0.id == id }
    }

    func entries(matching collection: SmartCollection) -> [GalleryEntry] {
        galleryEntries
            .filter { collection.matches($0) }
            .sorted { $0.eloRating > $1.eloRating }
    }

    func addReflection(_ entry: ReflectionEntry) {
        reflectionEntries.insert(entry, at: 0)
        recordReflectionAnswer()
        recordMeaningfulAction()
        completeSession()
        evaluateAchievements()
    }

    func updateReflection(_ entry: ReflectionEntry) {
        guard let index = reflectionEntries.firstIndex(where: { $0.id == entry.id }) else { return }
        reflectionEntries[index] = entry
        recordReflectionAnswer()
        recordMeaningfulAction()
        evaluateAchievements()
    }

    func deleteReflection(id: UUID) {
        reflectionEntries.removeAll { $0.id == id }
        evaluateAchievements()
    }

    func toggleFavorite(id: String) {
        if let index = favorites.firstIndex(of: id) {
            favorites.remove(at: index)
            if let uuid = UUID(uuidString: id),
               let entryIndex = galleryEntries.firstIndex(where: { $0.id == uuid }),
               galleryEntries[entryIndex].decisionStatus == .favorite {
                galleryEntries[entryIndex].decisionStatus = .pending
            }
        } else {
            favorites.insert(id, at: 0)
            if let uuid = UUID(uuidString: id),
               let entryIndex = galleryEntries.firstIndex(where: { $0.id == uuid }) {
                galleryEntries[entryIndex].decisionStatus = .favorite
            }
            recordMeaningfulAction()
            completeSession()
        }
        markRecentlyViewed(id: id)
        evaluateAchievements()
    }

    func isFavorite(id: String) -> Bool {
        favorites.contains(id)
    }

    func markRecentlyViewed(id: String) {
        recentlyViewed.removeAll { $0 == id }
        recentlyViewed.insert(id, at: 0)
        if recentlyViewed.count > 20 {
            recentlyViewed = Array(recentlyViewed.prefix(20))
        }
        if let uuid = UUID(uuidString: id),
           let index = galleryEntries.firstIndex(where: { $0.id == uuid }) {
            galleryEntries[index].lastOpenedAt = Date()
        }
    }

    func reorderFavorites(from source: IndexSet, to destination: Int) {
        var updated = favorites
        let moving = source.sorted().map { updated[$0] }
        for index in source.sorted(by: >) {
            updated.remove(at: index)
        }
        var target = destination
        for index in source {
            if index < destination {
                target -= 1
            }
        }
        target = max(0, min(target, updated.count))
        for (offset, item) in moving.enumerated() {
            updated.insert(item, at: target + offset)
        }
        favorites = updated
    }

    func startSessionTracking() {
        if sessionStartedAt == nil {
            sessionStartedAt = Date()
        }
    }

    func pauseSessionTracking() {
        guard let started = sessionStartedAt else { return }
        let elapsed = Int(Date().timeIntervalSince(started))
        if elapsed > 0 {
            totalMinutesUsed += elapsed
            evaluateAchievements()
        }
        sessionStartedAt = nil
    }

    func completeSession() {
        totalSessionsCompleted += 1
        evaluateAchievements()
    }

    func recordMeaningfulAction() {
        streakDays = nextStreakValue(lastDate: lastActivityDate, current: streakDays)
        lastActivityDate = Date()
        evaluateAchievements()
    }

    func recordReflectionAnswer() {
        reflectionStreakDays = nextStreakValue(lastDate: lastReflectionAnswerDate, current: reflectionStreakDays)
        lastReflectionAnswerDate = Date()
    }

    func buildWeeklyInsights() -> WeeklyInsightSnapshot {
        refreshWeeklyInsightBaselineIfNeeded()

        let active = galleryEntries.filter { $0.decisionStatus != .archived }
        let allTags = (active.flatMap(\.tags) + reflectionEntries.flatMap(\.tags))
            .map { $0.lowercased() }
            .filter { !$0.isEmpty }
        let topTag = mostCommon(in: allTags) ?? "none"

        let average: Double
        if active.isEmpty {
            average = 0
        } else {
            average = active.map { Double($0.rating) }.reduce(0, +) / Double(active.count)
        }

        let forgotten = active
            .filter { $0.rating >= 4 }
            .sorted { lhs, rhs in
                let left = lhs.lastOpenedAt ?? lhs.dateAdded
                let right = rhs.lastOpenedAt ?? rhs.dateAdded
                return left < right
            }
            .prefix(3)
            .map { $0 }

        return WeeklyInsightSnapshot(
            topTag: topTag,
            averageRating: average,
            previousAverageRating: previousWeekAverageRating,
            forgottenGems: Array(forgotten),
            pendingDecisions: pendingDecisionEntries.count,
            reflectionStreak: reflectionStreakDays,
            duelCount: duelComparisonsCompleted
        )
    }

    func exportSummaryText() -> String {
        let insights = buildWeeklyInsights()
        let topEntries = galleryEntries
            .filter { $0.decisionStatus != .archived }
            .sorted { $0.eloRating > $1.eloRating }
            .prefix(10)

        var lines: [String] = []
        lines.append("Media Curation Summary")
        lines.append("Generated \(Date().formatted(date: .abbreviated, time: .shortened))")
        lines.append("")
        lines.append("Overview")
        lines.append("- Entries: \(galleryEntries.count)")
        lines.append("- Pending decisions: \(insights.pendingDecisions)")
        lines.append("- Favorites: \(favorites.count)")
        lines.append("- Reflections: \(reflectionEntries.count)")
        lines.append("- Reflection streak: \(reflectionStreakDays) day(s)")
        lines.append("- Duels completed: \(duelComparisonsCompleted)")
        lines.append("- Top tag: \(insights.topTag)")
        lines.append(String(format: "- Average rating: %.1f", insights.averageRating))
        lines.append("- \(insights.ratingTrendText)")
        lines.append("")
        lines.append("Top 10 by comparative ranking")
        if topEntries.isEmpty {
            lines.append("- No entries yet")
        } else {
            for (index, entry) in topEntries.enumerated() {
                let tagText = entry.tags.isEmpty ? "no tags" : entry.tags.joined(separator: ", ")
                lines.append("\(index + 1). \(entry.emoji) \(entry.title) — stars \(entry.rating)/5, Elo \(Int(entry.eloRating)), verdict \(entry.intentVerdict.title), tags: \(tagText)")
                if !entry.note.isEmpty {
                    lines.append("   Note: \(entry.note)")
                }
            }
        }
        lines.append("")
        lines.append("Smart collections: \(smartCollections.count)")
        for collection in smartCollections {
            let count = entries(matching: collection).count
            lines.append("- \(collection.name): \(count) item(s)")
        }
        return lines.joined(separator: "\n")
    }

    func evaluateAchievements() {
        for achievement in AchievementCatalog.all {
            guard achievement.isUnlocked(self) else { continue }
            guard achievementsUnlocked[achievement.id] == nil else { continue }
            achievementsUnlocked[achievement.id] = Date()
            enqueueAchievementBanner(achievement)
        }
    }

    func resetAllData() {
        let domain = Bundle.main.bundleIdentifier ?? ""
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()
        hasSeenOnboarding = false
        galleryEntries = []
        reflectionEntries = []
        smartCollections = []
        favorites = []
        recentlyViewed = []
        totalSessionsCompleted = 0
        totalMinutesUsed = 0
        streakDays = 0
        reflectionStreakDays = 0
        lastReflectionAnswerDate = nil
        lastActivityDate = nil
        duelComparisonsCompleted = 0
        previousWeekAverageRating = 0
        lastInsightSnapshotDate = nil
        achievementsUnlocked = [:]
        pendingAchievementBanner = nil
        achievementQueue.removeAll()
        isShowingAchievementBanner = false
        sessionStartedAt = nil
        NotificationCenter.default.post(name: .dataReset, object: nil)
    }

    func galleryEntry(for id: String) -> GalleryEntry? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        return galleryEntries.first { $0.id == uuid }
    }

    func dismissAchievementBanner() {
        pendingAchievementBanner = nil
        isShowingAchievementBanner = false
        showNextAchievementBannerIfNeeded()
    }

    private func enqueueAchievementBanner(_ achievement: AchievementDefinition) {
        achievementQueue.append(achievement)
        showNextAchievementBannerIfNeeded()
    }

    private func showNextAchievementBannerIfNeeded() {
        guard !isShowingAchievementBanner, let next = achievementQueue.first else { return }
        achievementQueue.removeFirst()
        isShowingAchievementBanner = true
        pendingAchievementBanner = next
        FeedbackService.achievementUnlocked()
        NotificationCenter.default.post(name: .achievementUnlocked, object: next.id)
    }

    private func nextStreakValue(lastDate: Date?, current: Int) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let last = lastDate else { return 1 }
        let lastDay = calendar.startOfDay(for: last)
        let dayDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
        if dayDiff == 0 { return max(current, 1) }
        if dayDiff == 1 { return current + 1 }
        return 1
    }

    private func refreshWeeklyInsightBaselineIfNeeded() {
        let calendar = Calendar.current
        let now = Date()
        if let last = lastInsightSnapshotDate {
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: last), to: calendar.startOfDay(for: now)).day ?? 0
            if days < 7 { return }
        } else if previousWeekAverageRating > 0 {
            lastInsightSnapshotDate = now
            return
        }

        let active = galleryEntries.filter { $0.decisionStatus != .archived }
        if !active.isEmpty {
            previousWeekAverageRating = active.map { Double($0.rating) }.reduce(0, +) / Double(active.count)
        }
        lastInsightSnapshotDate = now
    }

    private func mostCommon(in values: [String]) -> String? {
        guard !values.isEmpty else { return nil }
        var counts: [String: Int] = [:]
        for value in values {
            counts[value, default: 0] += 1
        }
        return counts.max { $0.value < $1.value }?.key
    }

    private func syncReflectionArrays() {
        defaults.set(captions, forKey: Keys.captions)
        defaults.set(photoIds.map(\.uuidString), forKey: Keys.photoIds)
        defaults.set(dates.map(\.timeIntervalSince1970), forKey: Keys.dates)
        defaults.set(tags, forKey: Keys.tags)
    }

    private func reloadFromDefaults() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        galleryEntries = Self.loadCodable([GalleryEntry].self, key: Keys.galleryEntries) ?? []
        reflectionEntries = Self.loadCodable([ReflectionEntry].self, key: Keys.reflectionEntries) ?? []
        smartCollections = Self.loadCodable([SmartCollection].self, key: Keys.smartCollections) ?? []
        favorites = defaults.stringArray(forKey: Keys.favorites) ?? []
        recentlyViewed = defaults.stringArray(forKey: Keys.recentlyViewed) ?? []
        totalSessionsCompleted = defaults.integer(forKey: Keys.totalSessionsCompleted)
        totalMinutesUsed = defaults.integer(forKey: Keys.totalMinutesUsed)
        streakDays = defaults.integer(forKey: Keys.streakDays)
        reflectionStreakDays = defaults.integer(forKey: Keys.reflectionStreakDays)
        lastReflectionAnswerDate = Self.loadOptionalDateValue(Keys.lastReflectionAnswerDate)
        lastActivityDate = Self.loadOptionalDateValue(Keys.lastActivityDate)
        duelComparisonsCompleted = defaults.integer(forKey: Keys.duelComparisonsCompleted)
        previousWeekAverageRating = defaults.double(forKey: Keys.previousWeekAverageRating)
        lastInsightSnapshotDate = Self.loadOptionalDateValue(Keys.lastInsightSnapshotDate)
        achievementsUnlocked = Self.loadCodable([String: Date].self, key: Keys.achievementsUnlocked) ?? [:]
    }

    private func saveOptionalDate(_ date: Date?, key: String) {
        if let date {
            defaults.set(date.timeIntervalSince1970, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    private static func loadOptionalDateValue(_ key: String) -> Date? {
        let interval = UserDefaults.standard.double(forKey: key)
        return interval > 0 ? Date(timeIntervalSince1970: interval) : nil
    }

    private func saveCodable<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private static func loadCodable<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
