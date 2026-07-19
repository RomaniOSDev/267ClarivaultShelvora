import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showResetAlert = false

    private var versionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 16) {
                        SectionHeaderView(
                            title: "Settings",
                            subtitle: "Local data only — nothing leaves this device"
                        )

                        statsCard

                        Button {
                            FeedbackService.lightTap()
                            ExportShareService.presentSummary(from: store)
                        } label: {
                            SettingsActionCell(title: "Export Summary", symbol: "square.and.arrow.up")
                        }
                        .buttonStyle(ScalePressStyle())

                        Button {
                            FeedbackService.lightTap()
                            rateApp()
                        } label: {
                            SettingsActionCell(title: "Rate Us", symbol: "star.fill")
                        }
                        .buttonStyle(ScalePressStyle())

                        Button {
                            FeedbackService.lightTap()
                            openLink(.privacyPolicy)
                        } label: {
                            SettingsActionCell(title: "Privacy", symbol: "hand.raised.fill")
                        }
                        .buttonStyle(ScalePressStyle())

                        Button {
                            FeedbackService.lightTap()
                            openLink(.termsOfUse)
                        } label: {
                            SettingsActionCell(title: "Terms", symbol: "doc.text.fill")
                        }
                        .buttonStyle(ScalePressStyle())

                        Button {
                            FeedbackService.lightTap()
                            showResetAlert = true
                        } label: {
                            SettingsActionCell(title: "Reset All Data", symbol: "trash", destructive: true)
                        }
                        .buttonStyle(ScalePressStyle())

                        Text("Version \(versionString)")
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, TabMetrics.tabBarClearance)
                }
                .clearScrollBackground()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Reset All Data", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {
                    FeedbackService.lightTap()
                }
                Button("Reset", role: .destructive) {
                    FeedbackService.warning()
                    store.resetAllData()
                }
            } message: {
                Text("This will permanently clear all local entries, favorites, stats, and achievements.")
            }
        }
        .transparentScreenChrome()
    }

    private var statsCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Activity")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                HStack(spacing: 10) {
                    MetricChip(title: "Entries", value: "\(store.itemsAdded)", symbol: "square.stack")
                    MetricChip(title: "Sessions", value: "\(store.entriesWritten)", symbol: "bolt")
                    MetricChip(title: "Reflect", value: "\(store.reflectionStreakDays)d", symbol: "text.bubble")
                }

                Text("App streak: \(store.streakDays) days · Queue: \(store.pendingDecisionEntries.count)")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))

                ProgressRail(progress: min(Double(store.totalMinutes) / 3600.0, 1.0))
                Text("Time used: \(store.totalMinutes / 60) min")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
    }

    private func openLink(_ link: AppLink) {
        if let url = link.url {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
