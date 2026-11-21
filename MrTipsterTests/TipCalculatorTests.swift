import Foundation
import Testing
@testable import MrTipster

private func d(_ string: String) -> Decimal { Decimal(string: string, locale: Locale(identifier: "en_US_POSIX"))! }

@Suite("Tip math")
struct TipCalculatorTests {
    @Test func basicTip() {
        let r = TipCalculator.breakdown(bill: d("100"), tipPercent: 20, people: 1, roundUp: false, fractionDigits: 2)
        #expect(r.tip == d("20"))
        #expect(r.total == d("120"))
        #expect(r.perPerson == d("120"))
        #expect(r.roundingExtra == 0)
        #expect(!r.isSplit)
    }

    @Test func tipRoundsToCents() {
        // 18% of 86.43 = 15.5574 -> 15.56
        let r = TipCalculator.breakdown(bill: d("86.43"), tipPercent: 18, people: 1, roundUp: false, fractionDigits: 2)
        #expect(r.tip == d("15.56"))
        #expect(r.total == d("101.99"))
    }

    @Test func decimalAvoidsFloatingPointDrift() {
        // 0.1 + 0.2 style trouble in Double; exact in Decimal.
        let r = TipCalculator.breakdown(bill: d("0.30"), tipPercent: 10, people: 1, roundUp: false, fractionDigits: 2)
        #expect(r.tip == d("0.03"))
        #expect(r.total == d("0.33"))
    }

    @Test func splitRoundsEachShareUpToTheCent() {
        // 100 / 3 = 33.333... -> 33.34 so the group never comes up short.
        let r = TipCalculator.breakdown(bill: d("100"), tipPercent: 0, people: 3, roundUp: false, fractionDigits: 2)
        #expect(r.perPerson == d("33.34"))
        #expect(r.perPerson * 3 >= r.total)
        #expect(r.isSplit)
    }

    @Test func roundUpTotalWhenNotSplitting() {
        let r = TipCalculator.breakdown(bill: d("86.43"), tipPercent: 18, people: 1, roundUp: true, fractionDigits: 2)
        #expect(r.total == d("102"))
        #expect(r.tip == d("15.57"))
        #expect(r.roundingExtra == d("0.01"))
    }

    @Test func roundUpPerPersonWhenSplitting() {
        // 129 + 20% = 154.80; / 3 = 51.60 -> 52 each, 156 total, tip 27.
        let r = TipCalculator.breakdown(bill: d("129"), tipPercent: 20, people: 3, roundUp: true, fractionDigits: 2)
        #expect(r.perPerson == d("52"))
        #expect(r.total == d("156"))
        #expect(r.tip == d("27"))
        #expect(r.roundingExtra == d("1.2"))
    }

    @Test func roundUpLeavesWholeAmountsAlone() {
        let r = TipCalculator.breakdown(bill: d("100"), tipPercent: 20, people: 1, roundUp: true, fractionDigits: 2)
        #expect(r.total == d("120"))
        #expect(r.roundingExtra == 0)
    }

    @Test func roundUpWithEmptyBillStaysZero() {
        let r = TipCalculator.breakdown(bill: 0, tipPercent: 20, people: 2, roundUp: true, fractionDigits: 2)
        #expect(r.total == 0)
        #expect(r.perPerson == 0)
        #expect(r.tip == 0)
    }

    @Test func yenHasNoMinorUnitAndRoundsTo100() {
        let r = TipCalculator.breakdown(bill: d("4321"), tipPercent: 15, people: 1, roundUp: false, fractionDigits: 0)
        #expect(r.tip == d("648")) // 648.15 -> 648
        let rounded = TipCalculator.breakdown(bill: d("4321"), tipPercent: 15, people: 1, roundUp: true, fractionDigits: 0)
        #expect(rounded.total == d("5000"))
    }

    @Test(arguments: [(-5, 0), (0, 0), (20, 20), (51, 50), (500, 50)])
    func tipPercentIsClamped(input: Int, expected: Int) {
        let r = TipCalculator.breakdown(bill: d("10"), tipPercent: input, people: 1, roundUp: false, fractionDigits: 2)
        #expect(r.tipPercent == expected)
    }

    @Test func peopleAndBillAreClamped() {
        let r = TipCalculator.breakdown(bill: d("-10"), tipPercent: 20, people: 0, roundUp: false, fractionDigits: 2)
        #expect(r.bill == 0)
        #expect(r.people == 1)
        let many = TipCalculator.breakdown(bill: d("10"), tipPercent: 20, people: 999, roundUp: false, fractionDigits: 2)
        #expect(many.people == TipCalculator.peopleRange.upperBound)
    }
}

@Suite("Bill input")
struct BillInputTests {
    @Test(arguments: [
        ("129", "129"),
        ("12.50", "12.50"),
        ("12.505", "12.50"),        // too many decimals
        ("1.2.3", "1.23"),          // second separator ignored
        ("007", "7"),
        ("0", "0"),
        (".5", "0.5"),
        ("$1,234.56", "1234.56"),   // pasted with symbol and grouping
        ("abc", ""),
        ("123456789", "1234567"),   // integer digits capped
    ])
    func sanitizesUSStyle(raw: String, expected: String) {
        #expect(BillInput.sanitize(raw, decimalSeparator: ".", maxFractionDigits: 2) == expected)
    }

    @Test func sanitizesCommaDecimalLocales() {
        #expect(BillInput.sanitize("12,5", decimalSeparator: ",", maxFractionDigits: 2) == "12,5")
        #expect(BillInput.sanitize("1.234,56", decimalSeparator: ",", maxFractionDigits: 2) == "1234,56")
    }

    @Test func noDecimalsForYen() {
        #expect(BillInput.sanitize("1200.50", decimalSeparator: ".", maxFractionDigits: 0) == "1200")
    }

    @Test func parsesAmounts() {
        #expect(BillInput.amount(from: "12,5", decimalSeparator: ",") == d("12.5"))
        #expect(BillInput.amount(from: "129.99", decimalSeparator: ".") == d("129.99"))
        #expect(BillInput.amount(from: "", decimalSeparator: ".") == 0)
        #expect(BillInput.amount(from: "0.", decimalSeparator: ".") == 0)
    }
}

@Suite("Money formatting")
struct MoneyTests {
    @Test func usDollars() {
        let money = Money(code: "USD", locale: Locale(identifier: "en_US"))
        #expect(money.format(d("1234.5")) == "$1,234.50")
        #expect(money.fractionDigits == 2)
        #expect(money.symbolLeads)
        #expect(money.zeroPlaceholder == "0.00")
    }

    @Test func euroInGermany() {
        let money = Money(code: "EUR", locale: Locale(identifier: "de_DE"))
        #expect(money.format(d("154.8")).contains("154,80"))
        #expect(!money.symbolLeads)
        #expect(money.decimalSeparator == ",")
    }

    @Test func yen() {
        let money = Money(code: "JPY", locale: Locale(identifier: "en_US"))
        #expect(money.fractionDigits == 0)
        #expect(money.format(d("1548")) == "¥1,548")
        #expect(money.zeroPlaceholder == "0")
    }

    @Test func automaticFollowsLocale() {
        #expect(CurrencyChoice.automatic.code(locale: Locale(identifier: "en_IN")) == "INR")
        #expect(CurrencyChoice.gbp.code(locale: Locale(identifier: "en_IN")) == "GBP")
    }
}

@Suite("Currency choice")
struct CurrencyChoiceTests {
    private let us = Locale(identifier: "en_US")

    @Test func savedValuesFromEarlierBuildsStillLoad() {
        #expect(CurrencyChoice(rawValue: "automatic") == .automatic)
        #expect(CurrencyChoice(rawValue: "JPY") == .jpy)
        #expect(CurrencyChoice(rawValue: "eur") == .eur)
    }

    @Test func rejectsUnknownAndNonCurrencyCodes() {
        #expect(CurrencyChoice(rawValue: "ZZZ") == nil)
        #expect(CurrencyChoice(rawValue: "XAU") == nil) // gold
        #expect(CurrencyChoice(rawValue: "XOF") != nil) // West African CFA franc
    }

    @Test func listCoversEverydayCurrencies() {
        let codes = Set(CurrencyChoice.all(locale: us).map(\.rawValue))
        #expect(codes.count > 100)
        #expect(codes.isSuperset(of: ["USD", "EUR", "GBP", "JPY", "INR", "MXN", "KRW", "BRL", "CHF", "VND"]))
    }

    @Test func listIsSortedByLocalizedName() {
        let names = CurrencyChoice.all(locale: us).map { CurrencyChoice.name(for: $0.rawValue, locale: us) }
        #expect(names == names.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
    }

    @Test func suggestionsStartWithRegionAndHaveNoDuplicates() {
        let suggested = CurrencyChoice.suggested(locale: Locale(identifier: "es_MX"), preferredLanguages: ["es-MX", "en-US", "fr-FR"])
        #expect(suggested.first == CurrencyChoice(code: "MXN"))
        #expect(suggested.map(\.rawValue).prefix(3) == ["MXN", "USD", "EUR"])
        #expect(Set(suggested).count == suggested.count)
        #expect(suggested.count <= 6)
    }

    @Test func searchMatchesNameCodeAndSymbol() {
        let yen = CurrencyChoice.jpy
        #expect(yen.matches("yen", locale: us))
        #expect(yen.matches("jpy", locale: us))
        #expect(yen.matches("¥", locale: us))
        #expect(!yen.matches("euro", locale: us))
        #expect(CurrencyChoice(code: "EUR").matches("euro", locale: Locale(identifier: "de_DE")))
    }

    @Test func flags() {
        #expect(CurrencyChoice.usd.flag == "🇺🇸")
        #expect(CurrencyChoice.eur.flag == "🇪🇺")
        #expect(CurrencyChoice(code: "XOF").flag == nil)
        #expect(CurrencyChoice.automatic.flag == nil)
    }
}

@Suite("Rounding steps")
struct RoundingStepTests {
    @Test(arguments: [("USD", 2, Decimal(1)), ("EUR", 2, 1), ("INR", 2, 1), ("JPY", 0, 100),
                      ("KRW", 0, 1000), ("VND", 0, 10000), ("IDR", 2, 10000), ("CLP", 0, 1000), ("ISK", 0, 100)])
    func step(code: String, digits: Int, expected: Decimal) {
        #expect(TipCalculator.roundingIncrement(code: code, fractionDigits: digits) == expected)
    }

    @Test func wonRoundsToThousand() {
        let money = Money(code: "KRW", locale: Locale(identifier: "ko_KR"))
        let r = TipCalculator.breakdown(bill: d("45300"), tipPercent: 10, people: 1, roundUp: true,
                                        fractionDigits: money.fractionDigits, roundingIncrement: money.roundingIncrement)
        #expect(r.total == d("50000"))
    }
}

@Suite("Mood")
struct MoodTests {
    @Test(arguments: [(0, Mood.unimpressed), (9, .unimpressed), (10, .content), (15, .content),
                      (18, .pleased), (21, .pleased), (22, .delighted), (29, .delighted), (30, .ecstatic), (50, .ecstatic)])
    func moodForTip(percent: Int, mood: Mood) {
        #expect(Mood(tipPercent: percent, hasBill: true) == mood)
    }

    @Test func waitsForABill() {
        #expect(Mood(tipPercent: 30, hasBill: false) == .waiting)
        #expect(!Mood.waiting.celebrates)
        #expect(Mood.delighted.celebrates)
    }
}
