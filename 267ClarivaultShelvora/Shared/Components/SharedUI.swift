import SwiftUI

struct AppBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color("AppBackground"),
                    Color("AppSurface"),
                    Color("AppBackground")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Soft volume orbs — no blur, no Canvas loops (cheap on scroll).
            Ellipse()
                .fill(Color("AppPrimary").opacity(0.16))
                .frame(width: 340, height: 240)
                .offset(x: -110, y: -220)
                .allowsHitTesting(false)

            Ellipse()
                .fill(Color("AppAccent").opacity(0.10))
                .frame(width: 300, height: 220)
                .offset(x: 140, y: 260)
                .allowsHitTesting(false)

            Ellipse()
                .fill(Color("AppPrimary").opacity(0.08))
                .frame(width: 220, height: 180)
                .offset(x: 40, y: -40)
                .allowsHitTesting(false)
        }
        .drawingGroup() // flatten once; static background stays cheap while scrolling
        .ignoresSafeArea()
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
                y: 0
            )
        )
    }
}

extension View {
    func clearScrollBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.clear)
    }

    func transparentScreenChrome() -> some View {
        background(Color.clear)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color("AppTextPrimary"))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: DepthStyle.controlRadius, style: .continuous)
                    .fill(DepthStyle.primaryButtonGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: DepthStyle.controlRadius, style: .continuous)
                            .fill(Color("AppTextPrimary").opacity(configuration.isPressed ? 0.08 : 0.05))
                            .allowsHitTesting(false)
                    )
            )
            .volumeStroke(emphasized: true, radius: DepthStyle.controlRadius)
            .softCardShadow(emphasized: false)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

struct SuccessCheckOverlay: View {
    let isVisible: Bool

    var body: some View {
        if isVisible {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color("AppAccent"))
                .transition(.scale.combined(with: .opacity))
        }
    }
}

struct AchievementBannerView: View {
    let achievement: AchievementDefinition

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.symbolName)
                .font(.title2)
                .foregroundStyle(Color("AppAccent"))
                .frame(width: 44, height: 44)
                .background(DepthStyle.chipGradient)
                .clipShape(Circle())
                .volumeStroke(emphasized: true, radius: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Unlocked")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                Text(achievement.title)
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(DepthStyle.panelGradient)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .volumeStroke(emphasized: true, radius: 16)
        .softCardShadow(emphasized: true)
        .padding(.horizontal, 16)
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let subtitle: String

    var body: some View {
        SurfaceCard(padding: 28) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color("AppPrimary").opacity(0.28))
                        .frame(width: 96, height: 96)
                    Image(systemName: symbol)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(Color("AppAccent"))
                }

                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
    }
}

struct EmojiPickerView: View {
    @Binding var selected: String
    private let emojis = ["⭐️", "📷", "🖼", "🌙", "☀️", "🌊", "🌿", "🎯", "💫", "🔥", "💙", "🌈"]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
            ForEach(emojis, id: \.self) { emoji in
                Button {
                    FeedbackService.lightTap()
                    selected = emoji
                } label: {
                    Text(emoji)
                        .font(.title2)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(selected == emoji ? Color("AppPrimary") : Color("AppBackground").opacity(0.55))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(selected == emoji ? Color("AppAccent") : Color.clear, lineWidth: 1.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct MediaThumbnailView: View {
    let emoji: String
    let title: String
    var isFavorite: Bool = false

    var body: some View {
        MediaGridCell(emoji: emoji, title: title, isFavorite: isFavorite)
    }
}
