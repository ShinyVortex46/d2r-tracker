import CoreText
import SwiftUI

// MARK: - Color hex initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

// MARK: - Theme

enum Theme {

    // MARK: Colors

    enum C {
        static let backgroundDeep = Color(hex: "#0D0A06")
        static let surfaceCard    = Color(hex: "#1A1207")
        static let surfaceRaised  = Color(hex: "#231A0A")
        static let borderStone    = Color(hex: "#4A4040")
        static let goldPrimary    = Color(hex: "#C8A951")
        static let goldBright     = Color(hex: "#E8C97A")
        static let textParchment  = Color(hex: "#D4C5A0")
        static let textMuted      = Color(hex: "#9A8E72")
        static let bloodRed       = Color(hex: "#8B1A1A")
        static let bloodRedBright = Color(hex: "#CC2222")
        static let emerald        = Color(hex: "#3A8A5A")
        static let amberWarning   = Color(hex: "#D4880A")
    }

    // MARK: Fonts

    static func exocet(_ size: CGFloat) -> Font {
        Font.custom("ExocetHeavy", size: size)
    }

    static func exocetLight(_ size: CGFloat) -> Font {
        Font.custom("ExocetLight", size: size)
    }

    static let navTitle:      Font = exocet(17)
    static let largeTitle:    Font = exocet(28)
    static let sectionHeader: Font = exocetLight(11)
    static let cardTitle:     Font = exocet(15)
    static let statValue:     Font = exocet(22)
    static let timerLarge:    Font = exocetLight(64)
    static let badge:         Font = exocetLight(11)
}

// MARK: - GoldDivider

struct GoldDivider: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: Theme.C.goldPrimary.opacity(0.4), location: 0.15),
                .init(color: Theme.C.goldBright, location: 0.5),
                .init(color: Theme.C.goldPrimary.opacity(0.4), location: 0.85),
                .init(color: .clear, location: 1),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 1)
    }
}

// MARK: - StoneCard modifier

struct StoneCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.C.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Theme.C.borderStone.opacity(0.8),
                                Theme.C.goldPrimary.opacity(0.15),
                                Theme.C.borderStone.opacity(0.8),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

extension View {
    func stoneCard() -> some View { modifier(StoneCardModifier()) }
}

// MARK: - ChiselRect (angular badge shape)

struct ChiselRect: Shape {
    var cut: CGFloat = 5
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to:    CGPoint(x: rect.minX + cut, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX,       y: rect.minY + cut))
            p.addLine(to: CGPoint(x: rect.maxX,       y: rect.maxY - cut))
            p.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX + cut, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX,       y: rect.maxY - cut))
            p.addLine(to: CGPoint(x: rect.minX,       y: rect.minY + cut))
            p.closeSubpath()
        }
    }
}

// MARK: - DiabloSectionHeader

struct DiabloSectionHeader: View {
    let title: String
    var body: some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(Theme.sectionHeader)
                .foregroundStyle(Theme.C.textMuted)
                .tracking(1.8)
                .frame(maxWidth: .infinity, alignment: .leading)
            GoldDivider()
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 4, trailing: 16))
        .listRowBackground(Color.clear)
    }
}
