import Foundation

/// The currency used for amounts: "Automatic" (follow the device region) or a specific
/// ISO 4217 code. Numbers are always formatted in the device's locale; only the
/// currency changes.
///
/// Stored as its raw value ("automatic" or a code such as "EUR"), which matches what
/// earlier 2.0 builds saved, so existing settings carry over.
struct CurrencyChoice: Hashable, Identifiable, Sendable, RawRepresentable {
    let rawValue: String

    static let automatic = CurrencyChoice(uncheckedRawValue: "automatic")
    static let usd = CurrencyChoice(uncheckedRawValue: "USD")
    static let eur = CurrencyChoice(uncheckedRawValue: "EUR")
    static let gbp = CurrencyChoice(uncheckedRawValue: "GBP")
    static let jpy = CurrencyChoice(uncheckedRawValue: "JPY")
    static let inr = CurrencyChoice(uncheckedRawValue: "INR")

    /// "automatic", or a currency code the system knows (case-insensitive).
    init?(rawValue: String) {
        if rawValue == Self.automatic.rawValue {
            self = .automatic
            return
        }
        let code = rawValue.uppercased()
        guard Self.knownCodes.contains(code) else { return nil }
        self.rawValue = code
    }

    private init(uncheckedRawValue: String) {
        self.rawValue = uncheckedRawValue
    }

    init(code: String) {
        self = CurrencyChoice(rawValue: code) ?? CurrencyChoice(uncheckedRawValue: code.uppercased())
    }

    var id: String { rawValue }
    var isAutomatic: Bool { self == .automatic }

    func code(locale: Locale = .current) -> String {
        isAutomatic ? (locale.currency?.identifier ?? "USD") : rawValue
    }

    /// "US Dollar", or "Automatic (US Dollar)".
    func displayName(locale: Locale = .current) -> String {
        let name = Self.name(for: code(locale: locale), locale: locale)
        return isAutomatic ? String(localized: "Automatic (\(name))") : name
    }

    /// Regional-indicator flag for the currency's country, the EU flag for the euro, or
    /// nil for currencies shared by several countries (CFA franc, East Caribbean dollar…).
    var flag: String? {
        guard !isAutomatic else { return nil }
        if rawValue == "EUR" { return "🇪🇺" }
        let region = String(rawValue.prefix(2))
        guard !rawValue.hasPrefix("X"), Locale.Region(region).isISORegion else { return nil }
        return region.unicodeScalars
            .compactMap { Unicode.Scalar(127_397 + $0.value) }
            .map(String.init)
            .joined()
    }

    /// True when `query` matches the currency's name (in the device language or
    /// English), its code, or its symbol.
    func matches(_ query: String, locale: Locale = .current) -> Bool {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return true }
        let code = code(locale: locale)
        let haystack = [
            code,
            Self.name(for: code, locale: locale),
            Self.name(for: code, locale: Locale(identifier: "en")),
            Money(code: code, locale: locale).symbol,
        ]
        return haystack.contains { $0.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }

    // MARK: - Lists

    /// Every everyday currency the system knows, sorted by localized name.
    static func all(locale: Locale = .current) -> [CurrencyChoice] {
        knownCodes
            .map { CurrencyChoice(uncheckedRawValue: $0) }
            .sorted { name(for: $0.rawValue, locale: locale).localizedStandardCompare(name(for: $1.rawValue, locale: locale)) == .orderedAscending }
    }

    /// The device region's currency, the currencies of regions in the user's preferred
    /// languages (handy for travelers), then the classic five from the 2017 app.
    static func suggested(locale: Locale = .current, preferredLanguages: [String] = Locale.preferredLanguages) -> [CurrencyChoice] {
        let regional = ([locale] + preferredLanguages.map(Locale.init(identifier:)))
            .compactMap { $0.currency?.identifier }
        var seen = Set<String>()
        return (regional + ["USD", "EUR", "GBP", "JPY", "INR"])
            .filter { knownCodes.contains($0) && seen.insert($0).inserted }
            .prefix(6)
            .map { CurrencyChoice(uncheckedRawValue: $0) }
    }

    // MARK: - Helpers

    static func name(for code: String, locale: Locale) -> String {
        locale.localizedString(forCurrencyCode: code) ?? code
    }

    /// Codes in everyday use. Funds, precious metals and test codes (XAU, XDR, XTS…)
    /// are left out, but the shared CFA and East Caribbean currencies stay.
    static let knownCodes: Set<String> = {
        let multinational: Set<String> = ["XAF", "XOF", "XCD", "XPF", "XCG"]
        return Set(Locale.commonISOCurrencyCodes.filter { !$0.hasPrefix("X") || multinational.contains($0) })
    }()
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

    /// What "Round up" rounds to for this currency.
    var roundingIncrement: Decimal { TipCalculator.roundingIncrement(code: code, fractionDigits: fractionDigits) }

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
