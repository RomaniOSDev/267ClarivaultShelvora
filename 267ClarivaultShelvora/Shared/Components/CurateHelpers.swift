import UIKit
import SwiftUI

enum ExportShareService {
    static func presentSummary(from store: AppDataStore) {
        let text = store.exportSummaryText()
        let activity = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }

        var presenter = root
        while let presented = presenter.presentedViewController {
            presenter = presented
        }

        if let popover = activity.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
                x: presenter.view.bounds.midX,
                y: presenter.view.bounds.midY,
                width: 1,
                height: 1
            )
            popover.permittedArrowDirections = []
        }

        presenter.present(activity, animated: true)
    }
}

struct AxisRatingRow: View {
    let title: String
    @Binding var value: Int

    var body: some View {
        SurfaceCard(padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("AppTextPrimary"))
                    Spacer()
                    Text("\(value)/5")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppAccent"))
                }
                ProgressRail(progress: Double(value) / 5.0)
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { level in
                        Button {
                            FeedbackService.lightTap()
                            value = level
                        } label: {
                            Text("\(level)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(level <= value ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(level <= value ? Color("AppPrimary") : Color("AppBackground").opacity(0.55))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct VerdictBadge: View {
    let verdict: IntentVerdict

    var body: some View {
        Label(verdict.title, systemImage: verdict.symbolName)
            .font(.caption2.weight(.bold))
            .foregroundStyle(Color("AppTextPrimary"))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(DepthStyle.chipGradient)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color("AppAccent").opacity(0.35), lineWidth: 1)
            )
    }
}
