import SwiftUI

/// Pick from every everyday currency, with search by name, code or symbol.
/// Automatic sits on top; suggestions (device region, preferred-language regions and
/// the 2017 app's five) follow; then the full list, alphabetical.
struct CurrencyPickerView: View {
    @Binding var selection: CurrencyChoice
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private let all = CurrencyChoice.all()
    private let suggested = CurrencyChoice.suggested()

    var body: some View {
        List {
            if query.isEmpty {
                Section {
                    row(.automatic)
                } footer: {
                    Text("Follows your device's region.")
                        .foregroundStyle(Theme.ink2)
                }
                .listRowBackground(Theme.card)

                Section {
                    ForEach(suggested) { row($0) }
                } header: {
                    header("Suggested")
                }
                .listRowBackground(Theme.card)
            }

            Section {
                ForEach(results) { row($0) }
            } header: {
                header(query.isEmpty ? "All currencies" : "Results")
            }
            .listRowBackground(Theme.card)
        }
        .overlay {
            if results.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Name, code or symbol")
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Currency")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var results: [CurrencyChoice] {
        query.isEmpty ? all : all.filter { $0.matches(query) }
    }

    private func row(_ choice: CurrencyChoice) -> some View {
        let isSelected = choice == selection
        let money = Money(code: choice.code())
        return Button {
            selection = choice
            dismiss()
        } label: {
            HStack(spacing: 12) {
                CurrencyFlag(choice: choice)
                VStack(alignment: .leading, spacing: 2) {
                    Text(choice.displayName())
                        .foregroundStyle(Color.primary)
                    Text(Self.detail(for: money))
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink2)
                }
                Spacer(minLength: 8)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .contentShape(Rectangle())
        }
        // Keep names in the normal text color; only the checkmark uses the accent.
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(choice.displayName())
        .accessibilityValue(money.code)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("currency-\(choice.rawValue)")
    }

    private func header(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.ink2)
            .textCase(nil)
            .accessibilityAddTraits(.isHeader)
    }

    /// "EUR · €", or just "CHF" when the symbol is the code.
    static func detail(for money: Money) -> String {
        money.symbol == money.code ? money.code : "\(money.code) · \(money.symbol)"
    }
}

/// The currency's flag emoji, or a globe for Automatic and shared currencies.
struct CurrencyFlag: View {
    let choice: CurrencyChoice
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 28

    var body: some View {
        Group {
            if let flag = choice.flag {
                Text(flag).font(.system(size: min(size, 40) * 0.85))
            } else {
                Image(systemName: "globe")
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
            }
        }
        .frame(width: min(size, 40), height: min(size, 40))
        .accessibilityHidden(true)
    }
}
