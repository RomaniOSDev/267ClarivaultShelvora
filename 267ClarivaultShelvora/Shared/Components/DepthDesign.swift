import SwiftUI

/// Lightweight depth tokens — no blur, no nested shadows, no animated meshes.
enum DepthStyle {
    static let cardRadius: CGFloat = 20
    static let controlRadius: CGFloat = 14

    /// Soft drop for primary cards (one shadow only).
    static func cardShadow(emphasized: Bool = false) -> (color: Color, radius: CGFloat, y: CGFloat) {
        (
            Color("AppBackground").opacity(emphasized ? 0.55 : 0.38),
            emphasized ? 14 : 10,
            emphasized ? 8 : 5
        )
    }

    static var panelGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppSurface"),
                Color("AppBackground").opacity(0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var sheenGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppPrimary").opacity(0.22),
                Color("AppAccent").opacity(0.06),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var primaryButtonGradient: LinearGradient {
        LinearGradient(
            colors: [Color("AppAccent"), Color("AppPrimary")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var chipGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppPrimary").opacity(0.28),
                Color("AppBackground").opacity(0.55)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var railGradient: LinearGradient {
        LinearGradient(
            colors: [Color("AppPrimary"), Color("AppAccent")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct SoftCardShadow: ViewModifier {
    var emphasized: Bool = false

    func body(content: Content) -> some View {
        let shadow = DepthStyle.cardShadow(emphasized: emphasized)
        content
            .shadow(color: shadow.color, radius: shadow.radius, x: 0, y: shadow.y)
    }
}

struct VolumeStroke: ViewModifier {
    var emphasized: Bool = false
    var radius: CGFloat = DepthStyle.cardRadius

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color("AppAccent").opacity(emphasized ? 0.55 : 0.28),
                            Color("AppPrimary").opacity(emphasized ? 0.35 : 0.12),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: emphasized ? 1.4 : 1
                )
        )
    }
}

extension View {
    func softCardShadow(emphasized: Bool = false) -> some View {
        modifier(SoftCardShadow(emphasized: emphasized))
    }

    func volumeStroke(emphasized: Bool = false, radius: CGFloat = DepthStyle.cardRadius) -> some View {
        modifier(VolumeStroke(emphasized: emphasized, radius: radius))
    }
}
