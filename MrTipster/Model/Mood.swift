import Foundation

/// How Mr Tipster feels about your tip. Drives the mustache and the one-liner.
enum Mood: Int, Comparable, Sendable, CaseIterable {
    case waiting      // no bill yet
    case unimpressed  // under 10%
    case content      // 10–17%
    case pleased      // 18–21%
    case delighted    // 22–29%
    case ecstatic     // 30% and up

    init(tipPercent: Int, hasBill: Bool) {
        guard hasBill else { self = .waiting; return }
        switch tipPercent {
        case ..<10: self = .unimpressed
        case 10..<18: self = .content
        case 18..<22: self = .pleased
        case 22..<30: self = .delighted
        default: self = .ecstatic
        }
    }

    static func < (lhs: Mood, rhs: Mood) -> Bool { lhs.rawValue < rhs.rawValue }

    var line: String {
        switch self {
        case .waiting: String(localized: "What's the damage?")
        case .unimpressed: String(localized: "Mr Tipster raises an eyebrow.")
        case .content: String(localized: "A respectable tip.")
        case .pleased: String(localized: "Mr Tipster approves!")
        case .delighted: String(localized: "Splendid! Most generous.")
        case .ecstatic: String(localized: "Mr Tipster tips his hat to you!")
        }
    }

    /// Degrees each half of the mustache curls up (positive) or droops (negative).
    var curl: Double {
        switch self {
        case .waiting: 0
        case .unimpressed: -14
        case .content: 0
        case .pleased: 8
        case .delighted: 14
        case .ecstatic: 20
        }
    }

    /// Generous enough to deserve a celebratory twirl.
    var celebrates: Bool { self >= .delighted }
}
