import Foundation
import Testing
@testable import MrTipster

/// A clock tests can move forward.
final class TestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var _now = Date(timeIntervalSince1970: 1_800_000_000)
    var now: Date { lock.withLock { _now } }
    func advance(minutes: Double) { lock.withLock { _now += minutes * 60 } }
}

private func makeDefaults() -> UserDefaults {
    let name = "MrTipsterTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return defaults
}

@Suite("Ten-minute session memory")
struct SessionStoreTests {
    let clock = TestClock()
    let defaults = makeDefaults()
    var store: SessionStore { SessionStore(defaults: defaults, now: { [clock] in clock.now }) }

    let session = BillSession(billText: "129.50", tipPercent: 20, people: 3)

    @Test func restoresWithinTenMinutes() {
        store.save(session)
        clock.advance(minutes: 9.9)
        #expect(store.restore() == session)
    }

    @Test func forgetsAfterTenMinutes() {
        store.save(session)
        clock.advance(minutes: 10)
        #expect(store.restore() == nil)
    }

    @Test func touchingExtendsTheSession() {
        store.save(session)
        clock.advance(minutes: 8)
        store.touch() // app went to the background
        clock.advance(minutes: 8)
        #expect(store.restore() == session)
    }

    @Test func clockGoingBackwardsIsNotTrusted() {
        store.save(session)
        clock.advance(minutes: -5)
        #expect(store.restore() == nil)
    }

    @Test func nothingSavedRestoresNothing() {
        #expect(store.restore() == nil)
        #expect(!store.isFresh)
    }

    @Test func clearForgets() {
        store.save(session)
        store.clear()
        #expect(store.restore() == nil)
    }
}

@Suite("Calculator model")
@MainActor
struct TipperModelTests {
    let clock = TestClock()
    let defaults = makeDefaults()
    let locale = Locale(identifier: "en_US")

    func makeModel() -> TipperModel {
        let settings = AppSettings(defaults: defaults)
        settings.currency = .usd
        let store = SessionStore(defaults: defaults, now: { [clock] in clock.now })
        return TipperModel(settings: settings, store: store, locale: locale)
    }

    @Test func startsWithDefaults() {
        let model = makeModel()
        #expect(model.billText.isEmpty)
        #expect(model.tipPercent == AppSettings.defaultTip)
        #expect(model.people == 1)
        #expect(model.mood == .waiting)
    }

    @Test func typingSanitizesAndComputes() {
        let model = makeModel()
        model.billText = "129.999"
        model.billTextDidChange()
        #expect(model.billText == "129.99")
        model.setTip(20)
        #expect(model.breakdown.total == Decimal(string: "155.99")!)
        #expect(model.resultSummary == "Total $155.99")
    }

    @Test func splitSummaryMentionsEachShare() {
        let model = makeModel()
        model.billText = "129"
        model.billTextDidChange()
        model.setTip(20)
        model.setPeople(3)
        #expect(model.resultSummary == "$51.60 each, $154.80 total")
    }

    @Test func relaunchWithinTenMinutesRestoresTheBill() {
        let model = makeModel()
        model.billText = "42.50"
        model.billTextDidChange()
        model.setTip(22)
        model.setPeople(2)
        clock.advance(minutes: 5)

        let relaunched = makeModel()
        #expect(relaunched.billText == "42.50")
        #expect(relaunched.tipPercent == 22)
        #expect(relaunched.people == 2)
    }

    @Test func relaunchAfterTenMinutesStartsFresh() {
        let model = makeModel()
        model.billText = "42.50"
        model.billTextDidChange()
        clock.advance(minutes: 11)

        let relaunched = makeModel()
        #expect(relaunched.billText.isEmpty)
    }

    @Test func returningFromBackgroundAfterTenMinutesResets() {
        let model = makeModel()
        model.billText = "42.50"
        model.billTextDidChange()
        model.setPeople(4)
        model.sceneWillResignActive()
        clock.advance(minutes: 3)
        model.sceneDidBecomeActive()
        #expect(model.billText == "42.50")

        model.sceneWillResignActive()
        clock.advance(minutes: 12)
        model.sceneDidBecomeActive()
        #expect(model.billText.isEmpty)
        #expect(model.people == 1)
    }

    @Test func settingsPersist() {
        let settings = AppSettings(defaults: defaults)
        settings.defaultTipPercent = 22
        settings.currency = .jpy
        settings.roundUp = true
        let reloaded = AppSettings(defaults: defaults)
        #expect(reloaded.defaultTipPercent == 22)
        #expect(reloaded.currency == .jpy)
        #expect(reloaded.roundUp)
    }

    @Test func switchingToYenDropsDecimals() {
        let model = makeModel()
        model.billText = "12.34"
        model.billTextDidChange()
        model.settings.currency = .jpy
        model.billTextDidChange()
        #expect(model.billText == "12")
    }
}
