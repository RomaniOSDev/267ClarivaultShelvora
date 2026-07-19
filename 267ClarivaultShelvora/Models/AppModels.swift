import Foundation

enum DecisionStatus: String, Codable, CaseIterable, Identifiable {
    case pending
    case favorite
    case showcase
    case needsReflection
    case archived

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending: return "Pending"
        case .favorite: return "Favorite"
        case .showcase: return "Showcase"
        case .needsReflection: return "Needs Reflection"
        case .archived: return "Archive"
        }
    }

    var symbolName: String {
        switch self {
        case .pending: return "tray"
        case .favorite: return "star.fill"
        case .showcase: return "square.grid.2x2.fill"
        case .needsReflection: return "text.bubble"
        case .archived: return "archivebox"
        }
    }
}

enum IntentVerdict: String, Codable, CaseIterable {
    case keep
    case archive
    case revisit

    var title: String {
        switch self {
        case .keep: return "Keep"
        case .archive: return "Archive"
        case .revisit: return "Revisit"
        }
    }

    var symbolName: String {
        switch self {
        case .keep: return "checkmark.seal.fill"
        case .archive: return "archivebox.fill"
        case .revisit: return "arrow.clockwise.circle.fill"
        }
    }

    static func from(quality: Int, emotion: Int, keepForever: Int) -> IntentVerdict {
        let avg = Double(quality + emotion + keepForever) / 3.0
        if keepForever >= 4 && avg >= 3.5 { return .keep }
        if avg < 2.5 || keepForever <= 2 { return .archive }
        return .revisit
    }
}

struct GalleryEntry: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String
    var emoji: String
    var note: String
    var rating: Int
    var dateAdded: Date
    var eloRating: Double
    var quality: Int
    var emotion: Int
    var keepForever: Int
    var tags: [String]
    var decisionStatus: DecisionStatus
    var lastOpenedAt: Date?
    var duelWins: Int
    var duelLosses: Int

    var intentVerdict: IntentVerdict {
        IntentVerdict.from(quality: quality, emotion: emotion, keepForever: keepForever)
    }

    var compositeScore: Double {
        Double(quality + emotion + keepForever) / 3.0
    }

    init(
        id: UUID = UUID(),
        title: String,
        emoji: String,
        note: String,
        rating: Int,
        dateAdded: Date = Date(),
        eloRating: Double = 1000,
        quality: Int = 3,
        emotion: Int = 3,
        keepForever: Int = 3,
        tags: [String] = [],
        decisionStatus: DecisionStatus = .pending,
        lastOpenedAt: Date? = nil,
        duelWins: Int = 0,
        duelLosses: Int = 0
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.note = note
        self.rating = min(max(rating, 1), 5)
        self.dateAdded = dateAdded
        self.eloRating = eloRating
        self.quality = min(max(quality, 1), 5)
        self.emotion = min(max(emotion, 1), 5)
        self.keepForever = min(max(keepForever, 1), 5)
        self.tags = tags
        self.decisionStatus = decisionStatus
        self.lastOpenedAt = lastOpenedAt
        self.duelWins = duelWins
        self.duelLosses = duelLosses
    }

    enum CodingKeys: String, CodingKey {
        case id, title, emoji, note, rating, dateAdded
        case eloRating, quality, emotion, keepForever, tags
        case decisionStatus, lastOpenedAt, duelWins, duelLosses
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        emoji = try container.decode(String.self, forKey: .emoji)
        note = try container.decode(String.self, forKey: .note)
        rating = try container.decode(Int.self, forKey: .rating)
        dateAdded = try container.decode(Date.self, forKey: .dateAdded)
        eloRating = try container.decodeIfPresent(Double.self, forKey: .eloRating) ?? 1000
        quality = try container.decodeIfPresent(Int.self, forKey: .quality) ?? rating
        emotion = try container.decodeIfPresent(Int.self, forKey: .emotion) ?? rating
        keepForever = try container.decodeIfPresent(Int.self, forKey: .keepForever) ?? rating
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        decisionStatus = try container.decodeIfPresent(DecisionStatus.self, forKey: .decisionStatus) ?? .pending
        lastOpenedAt = try container.decodeIfPresent(Date.self, forKey: .lastOpenedAt)
        duelWins = try container.decodeIfPresent(Int.self, forKey: .duelWins) ?? 0
        duelLosses = try container.decodeIfPresent(Int.self, forKey: .duelLosses) ?? 0
    }
}

struct ReflectionEntry: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var photoId: UUID
    var title: String
    var emoji: String
    var caption: String
    var tags: [String]
    var date: Date
    var prompt: String

    init(
        id: UUID = UUID(),
        photoId: UUID = UUID(),
        title: String,
        emoji: String,
        caption: String,
        tags: [String] = [],
        date: Date = Date(),
        prompt: String = ""
    ) {
        self.id = id
        self.photoId = photoId
        self.title = title
        self.emoji = emoji
        self.caption = caption
        self.tags = tags
        self.date = date
        self.prompt = prompt
    }

    enum CodingKeys: String, CodingKey {
        case id, photoId, title, emoji, caption, tags, date, prompt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        photoId = try container.decode(UUID.self, forKey: .photoId)
        title = try container.decode(String.self, forKey: .title)
        emoji = try container.decode(String.self, forKey: .emoji)
        caption = try container.decode(String.self, forKey: .caption)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        date = try container.decode(Date.self, forKey: .date)
        prompt = try container.decodeIfPresent(String.self, forKey: .prompt) ?? ""
    }
}

struct SmartCollection: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var minRating: Int
    var requiredTag: String
    var onlyLastWeek: Bool
    var verdictFilter: String
    var dateCreated: Date

    init(
        id: UUID = UUID(),
        name: String,
        minRating: Int = 0,
        requiredTag: String = "",
        onlyLastWeek: Bool = false,
        verdictFilter: String = "",
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.minRating = minRating
        self.requiredTag = requiredTag
        self.onlyLastWeek = onlyLastWeek
        self.verdictFilter = verdictFilter
        self.dateCreated = dateCreated
    }

    func matches(_ entry: GalleryEntry, now: Date = Date()) -> Bool {
        if entry.decisionStatus == .archived { return false }
        if minRating > 0 && entry.rating < minRating { return false }
        let tag = requiredTag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !tag.isEmpty {
            let entryTags = entry.tags.map { $0.lowercased() }
            if !entryTags.contains(where: { $0 == tag || $0.contains(tag) }) {
                return false
            }
        }
        if onlyLastWeek {
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
            if entry.dateAdded < weekAgo { return false }
        }
        if !verdictFilter.isEmpty, entry.intentVerdict.rawValue != verdictFilter {
            return false
        }
        return true
    }
}

enum ReflectionPromptCatalog {
    static let all: [String] = [
        "Why did this matter?",
        "What would you change?",
        "What feeling does this bring back?",
        "Who would you share this with?",
        "What detail stands out most?",
        "Would you keep this forever? Why?"
    ]

    static func random(excluding current: String = "") -> String {
        let options = all.filter { $0 != current }
        return options.randomElement() ?? all[0]
    }
}

struct WeeklyInsightSnapshot: Equatable {
    var topTag: String
    var averageRating: Double
    var previousAverageRating: Double
    var forgottenGems: [GalleryEntry]
    var pendingDecisions: Int
    var reflectionStreak: Int
    var duelCount: Int

    var ratingTrendText: String {
        let delta = averageRating - previousAverageRating
        if previousAverageRating <= 0 { return "No prior week to compare" }
        if abs(delta) < 0.05 { return "Average rating is steady" }
        if delta > 0 { return String(format: "Average rating up %.1f", delta) }
        return String(format: "Average rating down %.1f", abs(delta))
    }
}

enum EloEngine {
    static func apply(winner: inout GalleryEntry, loser: inout GalleryEntry, k: Double = 32) {
        let expectedWinner = 1.0 / (1.0 + pow(10, (loser.eloRating - winner.eloRating) / 400.0))
        let expectedLoser = 1.0 - expectedWinner
        winner.eloRating += k * (1.0 - expectedWinner)
        loser.eloRating += k * (0.0 - expectedLoser)
        winner.duelWins += 1
        loser.duelLosses += 1
        winner.rating = starFromElo(winner.eloRating)
        loser.rating = starFromElo(loser.eloRating)
    }

    static func starFromElo(_ elo: Double) -> Int {
        switch elo {
        case ..<900: return 1
        case ..<1000: return 2
        case ..<1100: return 3
        case ..<1200: return 4
        default: return 5
        }
    }
}

struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbolName: String
    let isUnlocked: (AppDataStore) -> Bool
}

enum AchievementCatalog {
    static let all: [AchievementDefinition] = [
        AchievementDefinition(
            id: "first_rated",
            title: "First Rated",
            detail: "Rated your first photo.",
            symbolName: "star.fill",
            isUnlocked: { $0.itemsAdded >= 1 }
        ),
        AchievementDefinition(
            id: "top_ten",
            title: "Top Ten",
            detail: "Added ten ratings.",
            symbolName: "10.circle.fill",
            isUnlocked: { $0.itemsAdded >= 10 }
        ),
        AchievementDefinition(
            id: "dedicated_rater",
            title: "Dedicated Rater",
            detail: "Reached fifty photo ratings.",
            symbolName: "flame.fill",
            isUnlocked: { $0.itemsAdded >= 50 }
        ),
        AchievementDefinition(
            id: "active_user",
            title: "Active User",
            detail: "Completed 10 sessions.",
            symbolName: "bolt.fill",
            isUnlocked: { $0.entriesWritten >= 10 }
        ),
        AchievementDefinition(
            id: "dedicated_user",
            title: "Dedicated User",
            detail: "Completed 50 sessions.",
            symbolName: "person.fill.checkmark",
            isUnlocked: { $0.entriesWritten >= 50 }
        ),
        AchievementDefinition(
            id: "three_day_streak",
            title: "Three-Day Streak",
            detail: "Used the app 3 days in a row.",
            symbolName: "calendar",
            isUnlocked: { $0.streakDays >= 3 }
        ),
        AchievementDefinition(
            id: "week_long_habit",
            title: "Week-Long Habit",
            detail: "Used the app 7 days in a row.",
            symbolName: "calendar.badge.clock",
            isUnlocked: { $0.streakDays >= 7 }
        ),
        AchievementDefinition(
            id: "time_invested",
            title: "Time Invested",
            detail: "Spent 60 minutes total in the app.",
            symbolName: "clock.fill",
            isUnlocked: { $0.totalMinutes >= 3600 }
        )
    ]
}

extension Notification.Name {
    static let dataReset = Notification.Name("dataReset")
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}
