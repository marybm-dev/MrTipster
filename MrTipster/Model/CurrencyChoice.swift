import Foundation

/// The currencies from the 2017 app, plus "Automatic" (follow the device region).
/// Numbers are always formatted in the device's locale; only the currency changes.
enum CurrencyChoice: String, CaseIterable, Identifiable, Sendable {
    case automatic
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    case inr = "INR"

    var id: String { rawValue }

    func code(locale: Locale = .current) -> String {
        switch self {
        case .automatic: locale.currency?.identifier ?? "USD"
        default: rawValue
        }
    }

    /// Flag image from the 2017 app's assets; nil for automatic (uses a globe symbol).
    var flagImageName: String? {
        self == .automatic ? nil : "Flag-\(rawValue)"
    }

    func displayName(locale: Locale = .current) -> String {
        let code = code(locale: locale)
        let name = locale.localizedString(forCurrencyCode: code) ?? code
        switch self {
        case .automatic: return String(localized: "Automatic (\(name))")
        default: return name
        }
    }
}

/// Formatting helpers bound to one currency and locale.
struct Money: Sendable {
    let code: String
    let locale: Locale

    init(code: String, locale: Locale = .current) {
        self.code = code
        self.locale = locale
    }

    var fractionDigits: Int { Self.fractionDigits(for: code) }

    var decimalSeparator: String { locale.decimalSeparator ?? "." }

    var symbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.currencyCode = code
        return formatter.currencySymbol
    }

    /// Whether the symbol comes before the number in this locale ("$5" vs "5 €").
    var symbolLeads: Bool {
        guard let first = format(1).first else { return true }
        return !first.isNumber
    }

    func format(_ amount: Decimal, fractionDigits digits: Int? = nil) -> String {
        amount.formatted(
            .currency(code: code)
                .locale(locale)
                .precision(.fractionLength(digits ?? fractionDigits))
        )
    }

    /// Placeholder for the empty bill field, e.g. "0.00" or "0".
    var zeroPlaceholder: String {
        fractionDigits == 0 ? "0" : "0" + decimalSeparator + String(repeating: "0", count: fractionDigits)
    }

    static func fractionDigits(for code: String) -> Int {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.maximumFractionDigits
    }
}
