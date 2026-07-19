import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var page = 0

    private let pages: [OnboardingPageModel] = [
        OnboardingPageModel(
            headline: "Organize Media",
            detail: "Use the app to structure your media collection with ease.",
            imageName: "home_collections",
            symbol: "square.stack.3d.up.fill",
            accentLabel: "Collections"
        ),
        OnboardingPageModel(
            headline: "Rate Photos",
            detail: "Assign ratings to your photos based on quality or importance.",
            imageName: "home_duel",
            symbol: "star.circle.fill",
            accentLabel: "Mood & Elo"
        ),
        OnboardingPageModel(
            headline: "Start Rating",
            detail: "Begin by selecting a photo and giving it a score.",
            imageName: "home_empty",
            symbol: "hand.tap.fill",
            accentLabel: "Decision flow"
        )
    ]

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                HStack {
                    Text("Step \(page + 1) of \(pages.count)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppAccent"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(DepthStyle.chipGradient)
                        .clipShape(Capsule())
                        .volumeStroke(emphasized: false, radius: 12)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                ProgressRail(progress: Double(page + 1) / Double(pages.count), height: 6)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(
                            model: pages[index],
                            isActive: page == index
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: page)

                pageIndicator
                    .padding(.bottom, 18)

                VStack(spacing: 10) {
                    Button {
                        FeedbackService.lightTap()
                        advance()
                    } label: {
                        Text(page < pages.count - 1 ? "Next" : "Get Started")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    if page > 0 {
                        Button {
                            FeedbackService.lightTap()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                page -= 1
                            }
                        } label: {
                            Text("Back")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color("AppTextSecondary"))
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
                .padding(.top, 4)
                .background(
                    LinearGradient(
                        colors: [Color.clear, Color("AppBackground").opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .allowsHitTesting(false)
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(
                        index == page
                            ? DepthStyle.primaryButtonGradient
                            : LinearGradient(
                                colors: [
                                    Color("AppTextSecondary").opacity(0.35),
                                    Color("AppTextSecondary").opacity(0.2)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .frame(width: index == page ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: page)
                    .onTapGesture {
                        FeedbackService.lightTap()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            page = index
                        }
                    }
            }
        }
    }

    private func advance() {
        if page < pages.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                page += 1
            }
        } else {
            store.completeOnboarding()
        }
    }
}

private struct OnboardingPageModel {
    let headline: String
    let detail: String
    let imageName: String
    let symbol: String
    let accentLabel: String
}

private struct OnboardingPageView: View {
    let model: OnboardingPageModel
    let isActive: Bool
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Spacer(minLength: 8)

                SurfaceCard(padding: 0, emphasized: true) {
                    VStack(spacing: 0) {
                        ZStack(alignment: .topTrailing) {
                            Image(model.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 210)
                                .clipped()

                            LinearGradient(
                                colors: [
                                    Color("AppPrimary").opacity(0.15),
                                    Color("AppBackground").opacity(0.55)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .allowsHitTesting(false)

                            Label(model.accentLabel, systemImage: model.symbol)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color("AppTextPrimary"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(DepthStyle.chipGradient)
                                .clipShape(Capsule())
                                .volumeStroke(emphasized: true, radius: 14)
                                .padding(14)
                        }

                        VStack(spacing: 14) {
                            HStack(spacing: 10) {
                                Image(systemName: model.symbol)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(Color("AppAccent"))
                                    .frame(width: 44, height: 44)
                                    .background(DepthStyle.chipGradient)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .volumeStroke(emphasized: false, radius: 12)

                                Text(model.headline)
                                    .font(.title.bold())
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.7)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Text(model.detail)
                                .font(.body)
                                .foregroundStyle(Color("AppTextSecondary"))
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 8) {
                                featurePill("Local only")
                                featurePill("No accounts")
                                featurePill("Fast setup")
                            }
                        }
                        .padding(18)
                    }
                }
                .padding(.horizontal, 20)
                .scaleEffect(appeared ? 1 : 0.94)
                .opacity(appeared ? 1 : 0)

                Spacer(minLength: 20)
            }
        }
        .clearScrollBackground()
        .onAppear { playAppear() }
        .onChange(of: isActive) { active in
            if active { playAppear() }
        }
    }

    private func featurePill(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color("AppTextPrimary"))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(DepthStyle.chipGradient)
            .clipShape(Capsule())
    }

    private func playAppear() {
        appeared = false
        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
            appeared = true
        }
    }
}
