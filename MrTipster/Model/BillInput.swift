import Foundation

/// Cleans up what's typed into the bill field and turns it into a `Decimal`.
///
/// The field keeps the raw editing text (e.g. "129.5") in the user's locale, using
/// the locale's decimal separator. Grouping separators and other characters are
/// dropped, so pasting "$1,234.56" works too.
enum BillInput {
    static let maxIntegerDigits = 7

    static func sanitize(_ raw: String, decimalSeparator: String, maxFractionDigits: Int) -> String {
        var integer = ""
        var fraction = ""
        var seenSeparator = false

        for character in raw {
            if character.isASCII, character.isNumber {
                if seenSeparator {
                    if fraction.count < maxFractionDigits { fraction.append(character) }
                } else if integer.count < maxIntegerDigits {
                    integer.append(character)
                }
            } else if String(character) == decimalSeparator, !seenSeparator {
                seenSeparator = true
            }
        }

        // Drop leading zeros ("007" -> "7") but keep a single "0" before a separator.
        while integer.count > 1, integer.hasPrefix("0") { integer.removeFirst() }
        if seenSeparator && integer.isEmpty && maxFractionDigits > 0 { integer = "0" }

        // Currencies without a minor unit (yen) keep only the whole part.
        return seenSeparator && maxFractionDigits > 0 ? integer + decimalSeparator + fraction : integer
    }

    static func amount(from text: String, decimalSeparator: String) -> Decimal {
        let normalized = text.replacingOccurrences(of: decimalSeparator, with: ".")
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }

    /// Converts editing text between a locale-specific form and the POSIX form we persist.
    static func convert(_ text: String, from: String, to: String) -> String {
        from == to ? text : text.replacingOccurrences(of: from, with: to)
    }
}
