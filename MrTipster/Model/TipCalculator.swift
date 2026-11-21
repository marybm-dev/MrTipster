import Foundation

/// The result of splitting a bill. All money values are `Decimal`, rounded to the
/// currency's minor unit (cents for USD, whole yen for JPY).
struct TipBreakdown: Equatable, Sendable {
    var bill: Decimal
    var tipPercent: Int
    var people: Int
    var tip: Decimal
    var total: Decimal
    /// What each person pays. Never less than their exact share, so the group never
    /// comes up short.
    var perPerson: Decimal
    /// How much rounding up added on top of the plain percentage tip (0 when off).
    var roundingExtra: Decimal

    var isSplit: Bool { people > 1 }
}

enum TipCalculator {
    static let tipRange = 0...50
    static let peopleRange = 1...50

    /// - Parameters:
    ///   - bill: The bill before tip. Negative values are treated as zero.
    ///   - tipPercent: Whole-number percentage, clamped to `tipRange`.
    ///   - people: Number of people splitting, clamped to `peopleRange`.
    ///   - roundUp: Round up to the next whole unit (see `roundingIncrement`):
    ///     each person's share when splitting, otherwise the total. The difference
    ///     goes to the tip.
    ///   - fractionDigits: Minor-unit digits of the currency (2 for USD, 0 for JPY).
    ///   - roundingIncrement: What rounding up rounds to; defaults to
    ///     `roundingIncrement(fractionDigits:)`. Pass `Money.roundingIncrement` for the
    ///     currency-aware value.
    static func breakdown(
        bill: Decimal,
        tipPercent: Int,
        people: Int,
        roundUp: Bool,
        fractionDigits: Int,
        roundingIncrement: Decimal? = nil
    ) -> TipBreakdown {
        let bill = max(bill, 0)
        let percent = tipPercent.clamped(to: tipRange)
        let people = people.clamped(to: peopleRange)
        let digits = max(fractionDigits, 0)

        let plainTip = (bill * Decimal(percent) / 100).rounded(scale: digits, .plain)
        var tip = plainTip
        var total = bill + tip
        var perPerson = (total / Decimal(people)).rounded(scale: digits, .up)

        if roundUp && bill > 0 {
            let increment = roundingIncrement ?? Self.roundingIncrement(fractionDigits: digits)
            if people > 1 {
                perPerson = perPerson.roundedUp(toMultipleOf: increment)
                total = perPerson * Decimal(people)
            } else {
                total = total.roundedUp(toMultipleOf: increment)
                perPerson = total
            }
            tip = total - bill
        }

        return TipBreakdown(
            bill: bill,
            tipPercent: percent,
            people: people,
            tip: tip,
            total: total,
            perPerson: perPerson,
            roundingExtra: tip - plainTip
        )
    }

    /// Rounding goes to the next whole unit (1 dollar, euro, pound, rupee). For
    /// currencies without a minor unit (yen) a whole unit is tiny, so use 100.
    static func roundingIncrement(fractionDigits: Int) -> Decimal {
        fractionDigits == 0 ? 100 : 1
    }

    /// Currency-aware rounding step. Where one unit is worth very little, a whole unit
    /// is meaningless, so round to a step worth very roughly a US dollar or less
    /// (₩1,000, ₫10,000). Only the order of magnitude matters, so these don't need to
    /// track exchange rates closely.
    static func roundingIncrement(code: String, fractionDigits: Int) -> Decimal {
        if let step = lowValueCurrencySteps[code.uppercased()] { return step }
        return roundingIncrement(fractionDigits: fractionDigits)
    }

    private static let lowValueCurrencySteps: [String: Decimal] = [
        // About 100 per US dollar or more.
        "JPY": 100, "HUF": 100, "ISK": 100, "KZT": 100, "PKR": 100, "LKR": 100, "AMD": 100,
        "RSD": 100, "DZD": 100, "KES": 100, "JMD": 100, "XAF": 100, "XOF": 100, "NPR": 100,
        "MKD": 100, "KGS": 100, "YER": 100, "BDT": 100, "CRC": 100, "RWF": 100, "BIF": 100,
        // About 1,000 per US dollar or more.
        "KRW": 1000, "COP": 1000, "CLP": 1000, "NGN": 1000, "UZS": 1000, "TZS": 1000,
        "UGX": 1000, "MNT": 1000, "KHR": 1000, "PYG": 1000, "MMK": 1000, "IQD": 1000,
        "ARS": 1000, "MGA": 1000, "GNF": 1000,
        // About 10,000 per US dollar or more.
        "VND": 10000, "IDR": 10000, "LAK": 10000, "IRR": 10000, "LBP": 10000,
    ]
}

extension Decimal {
    func rounded(scale: Int, _ mode: NSDecimalNumber.RoundingMode) -> Decimal {
        var source = self
        var result = Decimal()
        NSDecimalRound(&result, &source, scale, mode)
        return result
    }

    func roundedUp(toMultipleOf increment: Decimal) -> Decimal {
        guard increment > 0 else { return self }
        return (self / increment).rounded(scale: 0, .up) * increment
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
