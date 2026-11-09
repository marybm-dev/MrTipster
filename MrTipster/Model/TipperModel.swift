import Foundation
import Observation

/// User preferences, persisted in UserDefaults.
@MainActor
@Observable
final class AppSettings {
    static let defaultTip = 18

    @ObservationIgnored private let defaults: UserDefaults

    var defaultTipPercent: Int {
        didSet { defaults.set(defaultTipPercent, forKey: Keys.defaultTip) }
    }
    var currency: CurrencyChoice {
        didSet { defaults.set(currency.rawValue, forKey: Keys.currency) }
    }
    var roundUp: Bool {
        didSet { defaults.set(roundUp, forKey: Keys.roundUp) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedTip = defaults.object(forKey: Keys.defaultTip) as? Int
        defaultTipPercent = (storedTip ?? Self.defaultTip).clamped(to: TipCalculator.tipRange)
        currency = defaults.string(forKey: Keys.currency).flatMap(CurrencyChoice.init) ?? .automatic
        roundUp = defaults.bool(forKey: Keys.roundUp)
    }

    private enum Keys {
        static let defaultTip = "defaultTipPercent"
        static let currency = "currency"
        static let roundUp = "roundUp"
    }
}

/// State for the calculator screen. The math lives in `TipCalculator`; this type
/// wires it to the UI, settings, and the 10-minute session memory.
@MainActor
@Observable
final class TipperModel {
    let settings: AppSettings
    @ObservationIgnored private let store: SessionStore
    @ObservationIgnored private let locale: Locale

    /// Raw editing text in the user's locale (e.g. "129,5" in Germany).
    var billText = ""
    var tipPercent: Int
    var people = 1

    init(settings: AppSettings, store: SessionStore = SessionStore(), locale: Locale = .current) {
        self.settings = settings
        self.store = store
        self.locale = locale
        self.tipPercent = settings.defaultTipPercent
        restoreOrReset()
    }

    var money: Money { Money(code: settings.currency.code(locale: locale), locale: locale) }

    var billAmount: Decimal {
        BillInput.amount(from: billText, decimalSeparator: money.decimalSeparator)
    }

    var hasBill: Bool { billAmount > 0 }

    var breakdown: TipBreakdown {
        TipCalculator.breakdown(
            bill: billAmount,
            tipPercent: tipPercent,
            people: people,
            roundUp: settings.roundUp,
            fractionDigits: money.fractionDigits
        )
    }

    var mood: Mood { Mood(tipPercent: tipPercent, hasBill: hasBill) }

    /// One sentence with the result, for VoiceOver announcements and values.
    var resultSummary: String {
        let result = breakdown
        if result.isSplit {
            return String(localized: "\(money.format(result.perPerson)) each, \(money.format(result.total)) total")
        }
        return String(localized: "Total \(money.format(result.total))")
    }

    // MARK: Editing

    /// Call after `billText` changes: keeps it a valid amount and remembers it.
    func billTextDidChange() {
        let clean = BillInput.sanitize(
            billText,
            decimalSeparator: money.decimalSeparator,
            maxFractionDigits: money.fractionDigits
        )
        if clean != billText {
            billText = clean // triggers another change, which then persists
            return
        }
        persist()
    }

    func setTip(_ percent: Int) {
        tipPercent = percent.clamped(to: TipCalculator.tipRange)
        persist()
    }

    func setPeople(_ count: Int) {
        people = count.clamped(to: TipCalculator.peopleRange)
        persist()
    }

    func clearBill() {
        billText = ""
        persist()
    }

    // MARK: Lifecycle and the 10-minute rule

    func restoreOrReset() {
        guard let session = store.restore() else { reset(); return }
        billText = BillInput.convert(session.billText, from: ".", to: money.decimalSeparator)
        tipPercent = session.tipPercent.clamped(to: TipCalculator.tipRange)
        people = session.people.clamped(to: TipCalculator.peopleRange)
    }

    /// Starts a fresh bill with the default tip.
    func reset() {
        billText = ""
        tipPercent = settings.defaultTipPercent
        people = 1
        store.clear()
    }

    func sceneWillResignActive() {
        if hasBill { store.touch() }
    }

    /// Coming back after more than 10 minutes away starts a new bill.
    func sceneDidBecomeActive() {
        if hasBill && !store.isFresh { reset() }
    }

    private func persist() {
        guard hasBill || people > 1 || tipPercent != settings.defaultTipPercent else {
            store.clear()
            return
        }
        store.save(BillSession(
            billText: BillInput.convert(billText, from: money.decimalSeparator, to: "."),
            tipPercent: tipPercent,
            people: people
        ))
    }
}
