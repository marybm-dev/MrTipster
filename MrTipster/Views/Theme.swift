import SwiftUI
import UIKit

/// Mr Tipster's palette. Every text/background pair is checked against WCAG AA
/// (4.5:1) in light and dark; Increase Contrast swaps in stronger variants.
enum Theme {
    /// Brand blue, a deeper take on the 2017 #3399CC so white text passes AA.
    static let accent = Color(light: 0x1B6AA5, dark: 0x6CB8EE, lightHC: 0x0E4F80, darkHC: 0xA6D6F7)
    /// Text/icons drawn on top of `accent`.
    static let onAccent = Color(light: 0xFFFFFF, dark: 0x0B0F14, lightHC: 0xFFFFFF, darkHC: 0x000000)

    static let heroTop = Color(light: 0x1A6CAB, dark: 0x1A5A8C, lightHC: 0x0E4F80, darkHC: 0x0D3A5E)
    static let heroBottom = Color(light: 0x124F80, dark: 0x0F3A5E, lightHC: 0x0E4F80, darkHC: 0x0D3A5E)

    static let background = Color(light: 0xEEF3F8, dark: 0x0B0F14, lightHC: 0xFFFFFF, darkHC: 0x000000)
    static let card = Color(light: 0xFFFFFF, dark: 0x161C24, lightHC: 0xFFFFFF, darkHC: 0x10151C)
    static let cardBorder = Color(light: 0xDCE5EE, dark: 0x243040, lightHC: 0x4B5563, darkHC: 0xA9B4C2)
    static let chip = Color(light: 0xE3EEF8, dark: 0x1F2A36, lightHC: 0xFFFFFF, darkHC: 0x000000)

    /// Secondary text. Darker than `.secondary`, which misses AA on tinted backgrounds.
    static let ink2 = Color(light: 0x4B5563, dark: 0xA9B4C2, lightHC: 0x1F2937, darkHC: 0xE2E8F0)

    /// Corner radius for cards.
    static let radius: CGFloat = 24
}

extension Color {
    init(light: UInt32, dark: UInt32, lightHC: UInt32, darkHC: UInt32) {
        self.init(uiColor: UIColor { traits in
            let highContrast = traits.accessibilityContrast == .high
            switch (traits.userInterfaceStyle == .dark, highContrast) {
            case (false, false): return UIColor(hex: light)
            case (true, false): return UIColor(hex: dark)
            case (false, true): return UIColor(hex: lightHC)
            case (true, true): return UIColor(hex: darkHC)
            }
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

/// A rounded card used for each section of the calculator.
struct CardBackground: ViewModifier {
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: .rect(cornerRadius: Theme.radius))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.radius)
                    .strokeBorder(Theme.cardBorder, lineWidth: contrast == .increased ? 2 : 1)
            }
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}

/// Posts VoiceOver announcements without interrupting what VoiceOver is saying.
@MainActor
enum Announcer {
    static func announce(_ message: String) {
        var text = AttributedString(message)
        text.accessibilitySpeechAnnouncementPriority = .default
        AccessibilityNotification.Announcement(text).post()
    }
}
