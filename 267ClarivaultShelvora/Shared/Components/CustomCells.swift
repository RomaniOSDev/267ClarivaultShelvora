import SwiftUI

// MARK: - Chrome

struct SurfaceCard<Content: View>: View {
    var padding: CGFloat = 16
    var emphasized: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: DepthStyle.cardRadius, style: .continuous)
                        .fill(DepthStyle.panelGradient)
                    RoundedRectangle(cornerRadius: DepthStyle.cardRadius, style: .continuous)
                        .fill(DepthStyle.sheenGradient)
                        .allowsHitTesting(false)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: DepthStyle.cardRadius, style: .continuous))
            .volumeStroke(emphasized: emphasized)
            .softCardShadow(emphasized: emphasized)
    }
}

struct SectionHeaderView: View {
    let title: String
    var subtitle: String? = nil
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
            }
            Spacer(minLength: 8)
            if let trailing, !trailing.isEmpty {
                Text(trailing)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppAccent"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DepthStyle.chipGradient)
                    .clipShape(Capsule())
                    .volumeStroke(emphasized: false, radius: 12)
            }
        }
    }
}

struct MetricChip: View {
    let title: String
    let value: String
    var symbol: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppAccent"))
            }
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(DepthStyle.chipGradient)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .volumeStroke(emphasized: false, radius: 14)
        // No drop shadow on chips — keeps long lists smooth.
    }
}

struct StarRatingView: View {
    let rating: Int
    var size: Font = .caption

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { value in
                Image(systemName: value <= rating ? "star.fill" : "star")
                    .font(size)
                    .foregroundStyle(Color("AppAccent"))
            }
        }
    }
}

struct TagChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color("AppTextPrimary"))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(DepthStyle.chipGradient)
            .clipShape(Capsule())
    }
}

struct TagChipRow: View {
    let tags: [String]
    var limit: Int = 4

    var body: some View {
        if !tags.isEmpty {
            HStack(spacing: 6) {
                ForEach(Array(tags.prefix(limit)), id: \.self) { tag in
                    TagChip(text: tag)
                }
                if tags.count > limit {
                    TagChip(text: "+\(tags.count - limit)")
                }
            }
        }
    }
}

struct EmojiBadgeView: View {
    let emoji: String
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DepthStyle.chipGradient)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color("AppAccent").opacity(0.45), Color("AppPrimary").opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            Text(emoji)
                .font(.system(size: size * 0.42))
        }
        .frame(width: size, height: size)
    }
}

struct ProgressRail: View {
    let progress: Double
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color("AppBackground").opacity(0.7))
                Capsule()
                    .fill(DepthStyle.railGradient)
                    .frame(width: max(height, geo.size.width * min(max(progress, 0), 1)))
            }
        }
        .frame(height: height)
    }
}

// MARK: - Feature cells

struct GalleryEntryCell: View {
    let entry: GalleryEntry
    var highlighted: Bool = false
    var showsElo: Bool = true

    var body: some View {
        SurfaceCard(emphasized: highlighted) {
            HStack(alignment: .top, spacing: 14) {
                EmojiBadgeView(emoji: entry.emoji, size: 64)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        Text(entry.title)
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                        Spacer(minLength: 8)
                        VerdictBadge(verdict: entry.intentVerdict)
                    }

                    Text(entry.note.isEmpty ? "No notes yet" : entry.note)
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    HStack(spacing: 10) {
                        StarRatingView(rating: entry.rating)
                        if showsElo {
                            Text("Elo \(Int(entry.eloRating))")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color("AppAccent"))
                        }
                        Spacer(minLength: 0)
                        Text(entry.dateAdded.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }

                    moodBars
                    TagChipRow(tags: entry.tags)
                }
            }
        }
    }

    private var moodBars: some View {
        VStack(spacing: 6) {
            moodLine("Quality", entry.quality)
            moodLine("Emotion", entry.emotion)
            moodLine("Keep", entry.keepForever)
        }
    }

    private func moodLine(_ title: String, _ value: Int) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
                .frame(width: 52, alignment: .leading)
            ProgressRail(progress: Double(value) / 5.0, height: 6)
            Text("\(value)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
                .frame(width: 14, alignment: .trailing)
        }
    }
}

struct HubFeatureCell: View {
    let title: String
    let subtitle: String
    let symbol: String
    var badge: String? = nil

    var body: some View {
        SurfaceCard(padding: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(DepthStyle.chipGradient)
                    Image(systemName: symbol)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color("AppAccent"))
                }
                .frame(width: 52, height: 52)
                .volumeStroke(emphasized: false, radius: 16)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 8)

                VStack(spacing: 8) {
                    if let badge {
                        Text(badge)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(DepthStyle.primaryButtonGradient)
                            .clipShape(Capsule())
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
    }
}

struct DecisionQueueCell: View {
    let entry: GalleryEntry
    let onDecision: (DecisionStatus) -> Void

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    EmojiBadgeView(emoji: entry.emoji, size: 60)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.title)
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                        Text(entry.note.isEmpty ? "Awaiting your decision" : entry.note)
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .lineLimit(2)
                        HStack(spacing: 8) {
                            StarRatingView(rating: entry.rating)
                            VerdictBadge(verdict: entry.intentVerdict)
                        }
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 8) {
                    queueAction("Favorite", "star.fill", .favorite)
                    queueAction("Showcase", "square.grid.2x2.fill", .showcase)
                }
                HStack(spacing: 8) {
                    queueAction("Reflect", "text.bubble.fill", .needsReflection)
                    queueAction("Archive", "archivebox.fill", .archived)
                }

                Text("Swipe right → Favorite · Swipe left → Archive")
                    .font(.caption2)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
    }

    private func queueAction(_ title: String, _ symbol: String, _ status: DecisionStatus) -> some View {
        Button {
            onDecision(status)
        } label: {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(Color("AppTextPrimary"))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background {
                    if status == .archived {
                        DepthStyle.chipGradient
                    } else {
                        DepthStyle.primaryButtonGradient
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color("AppAccent").opacity(0.25), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct CollectionRuleCell: View {
    let collection: SmartCollection
    let matchCount: Int
    let summary: String

    var body: some View {
        SurfaceCard {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(DepthStyle.chipGradient)
                    Image(systemName: "rectangle.stack.fill")
                        .foregroundStyle(Color("AppAccent"))
                }
                .frame(width: 48, height: 48)
                .overlay(Circle().stroke(Color("AppAccent").opacity(0.3), lineWidth: 1))

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(collection.name)
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer()
                        Text("\(matchCount)")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color("AppAccent"))
                    }
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)

                    ProgressRail(progress: min(Double(matchCount) / 10.0, 1.0))
                }
            }
        }
    }
}

struct AchievementCell: View {
    let achievement: AchievementDefinition
    let unlocked: Bool
    var unlockedDate: Date? = nil

    var body: some View {
        SurfaceCard(padding: 14, emphasized: unlocked) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(unlocked ? Color("AppPrimary").opacity(0.35) : Color("AppBackground").opacity(0.6))
                        .frame(width: 54, height: 54)
                    Image(systemName: achievement.symbolName)
                        .font(.title2)
                        .foregroundStyle(unlocked ? Color("AppAccent") : Color("AppTextSecondary"))
                }

                Text(achievement.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text(achievement.detail)
                    .font(.caption2)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)

                Text(unlocked ? "Unlocked" : "Locked")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(unlocked ? Color("AppAccent") : Color("AppTextSecondary"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(unlocked ? Color("AppPrimary").opacity(0.3) : Color("AppBackground").opacity(0.5))
                    .clipShape(Capsule())

                if let unlockedDate {
                    Text(unlockedDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 180)
        }
        .opacity(unlocked ? 1 : 0.72)
    }
}

struct SettingsActionCell: View {
    let title: String
    let symbol: String
    var destructive: Bool = false

    var body: some View {
        SurfaceCard(padding: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color("AppBackground").opacity(0.01))
                        .overlay {
                            if destructive {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.red.opacity(0.18))
                            } else {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(DepthStyle.chipGradient)
                            }
                        }
                    Image(systemName: symbol)
                        .foregroundStyle(destructive ? Color.red : Color("AppAccent"))
                }
                .frame(width: 44, height: 44)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(destructive ? Color.red : Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()

                if !destructive {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
    }
}

struct DuelPickCell: View {
    let entry: GalleryEntry
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SurfaceCard(padding: 12) {
                VStack(spacing: 12) {
                    EmojiBadgeView(emoji: entry.emoji, size: 88)

                    Text(entry.title)
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.center)

                    Text("Elo \(Int(entry.eloRating))")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppAccent"))

                    StarRatingView(rating: entry.rating, size: .caption)
                    VerdictBadge(verdict: entry.intentVerdict)

                    Text("Tap to choose")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(ScalePressStyle())
    }
}

struct MediaGridCell: View {
    let emoji: String
    let title: String
    var subtitle: String? = nil
    var isFavorite: Bool = false
    var highlighted: Bool = false

    var body: some View {
        SurfaceCard(padding: 12, emphasized: highlighted) {
            VStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    EmojiBadgeView(emoji: emoji, size: 72)
                        .frame(maxWidth: .infinity)

                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color("AppAccent"))
                            .padding(6)
                            .background(Color("AppBackground").opacity(0.75))
                            .clipShape(Circle())
                    }
                }

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .aspectRatio(0.85, contentMode: .fit)
    }
}

struct InsightStatCell: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        SurfaceCard(padding: 12) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .foregroundStyle(Color("AppAccent"))
                    .frame(width: 36, height: 36)
                    .background(DepthStyle.chipGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color("AppAccent").opacity(0.25), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                    Text(value)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }
}

struct FloatingBottomBar<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 12)
        }
        .background(
            ZStack {
                Rectangle()
                    .fill(DepthStyle.panelGradient)
                LinearGradient(
                    colors: [Color("AppPrimary").opacity(0.18), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 28)
                .frame(maxHeight: .infinity, alignment: .top)
                .allowsHitTesting(false)
            }
        )
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [Color("AppAccent").opacity(0.35), Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
        }
        .softCardShadow(emphasized: true)
    }
}

struct ScalePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct FormFieldLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color("AppTextSecondary"))
    }
}

struct AppTextFieldChrome<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(14)
            .background(DepthStyle.chipGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .volumeStroke(emphasized: false, radius: 14)
            .foregroundStyle(Color("AppTextPrimary"))
    }
}
