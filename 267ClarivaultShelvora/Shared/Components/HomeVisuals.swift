import SwiftUI

struct HomeHeroBanner: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image("home_hero")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipped()

            LinearGradient(
                colors: [
                    Color("AppBackground").opacity(0.02),
                    Color("AppPrimary").opacity(0.20),
                    Color("AppBackground").opacity(0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Soft top sheen for volume (no blur).
            LinearGradient(
                colors: [Color("AppAccent").opacity(0.18), Color.clear],
                startPoint: .topLeading,
                endPoint: .center
            )
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 8) {
                Text("Curate what matters")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text("Rate, compare, decide, and keep your best frames organized.")
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .padding(18)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .volumeStroke(emphasized: true, radius: 24)
        .softCardShadow(emphasized: true)
    }
}

struct HomeActionImageCard: View {
    let title: String
    let subtitle: String
    let imageName: String
    let badge: String?

    var body: some View {
        SurfaceCard(padding: 0) {
            HStack(spacing: 0) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 88, height: 88)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color("AppAccent").opacity(0.3), lineWidth: 1)
                    )
                    .padding(12)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer(minLength: 6)
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color("AppTextPrimary"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(DepthStyle.primaryButtonGradient)
                                .clipShape(Capsule())
                        }
                    }

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    HStack(spacing: 4) {
                        Text("Open")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color("AppAccent"))
                        Image(systemName: "arrow.right")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color("AppAccent"))
                    }
                    .padding(.top, 2)
                }
                .padding(.trailing, 14)
                .padding(.vertical, 12)

                Spacer(minLength: 0)
            }
        }
    }
}

struct HomeEmptyArtCard: View {
    var body: some View {
        SurfaceCard(padding: 20, emphasized: true) {
            VStack(spacing: 16) {
                Image("home_empty")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .volumeStroke(emphasized: true, radius: 20)
                    .softCardShadow(emphasized: false)

                Text("Create your first rated showcase!")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .multilineTextAlignment(.center)

                Text("Add an entry, score Quality / Emotion / Keep Forever, then send it through the Decision Queue.")
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
