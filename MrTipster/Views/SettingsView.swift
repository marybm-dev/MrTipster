import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    let layout = dynamicTypeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                        : AnyLayout(HStackLayout())
                    layout {
                        Text("Default tip")
                        if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                        StepperControl(
                            label: String(localized: "Default tip"),
                            value: $settings.defaultTipPercent,
                            range: TipCalculator.tipRange,
                            display: percentText,
                            accessibilityValue: percentText,
                            decrementLabel: String(localized: "Decrease default tip"),
                            incrementLabel: String(localized: "Increase default tip"),
                            compact: true
                        )
                    }
                    // A Form row merges its children, which hides the stepper's
                    // adjustable behavior, so the row itself is the adjustable element.
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Default tip")
                    .accessibilityValue(percentText)
                    .accessibilityAdjustableAction { direction in
                        switch direction {
                        case .increment: stepDefaultTip(+1)
                        case .decrement: stepDefaultTip(-1)
                        @unknown default: break
                        }
                    }
                    .accessibilityAction(named: "Increase default tip") { stepDefaultTip(+1) }
                    .accessibilityAction(named: "Decrease default tip") { stepDefaultTip(-1) }
                    .accessibilityIdentifier("defaultTipStepper")
                } header: {
                    SectionHeader("Tipping")
                } footer: {
                    Text("Every new bill starts with this tip.")
                        .foregroundStyle(Theme.ink2)
                }
                .listRowBackground(Theme.card)

                Section {
                    NavigationLink {
                        CurrencyPickerView(selection: $settings.currency)
                    } label: {
                        CurrencyLabel(choice: settings.currency)
                    }
                    .accessibilityIdentifier("currencyRow")
                } header: {
                    SectionHeader("Currency")
                } footer: {
                    Text("Amounts use your device's number format.")
                        .foregroundStyle(Theme.ink2)
                }
                .listRowBackground(Theme.card)

                Section {
                    VStack(spacing: 8) {
                        MascotView(mood: .delighted, color: Theme.accent)
                            .frame(width: 112)
                            .padding(.vertical, 8)
                        Text("Mr Tipster")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .accessibilityAddTraits(.isHeader)
                        Text("Version \(version)")
                            .font(.subheadline)
                            .foregroundStyle(Theme.ink2)
                        Text("Originally built in 2017 for CodePath. Revived in 2026, mustache intact.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.ink2)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .listRowBackground(Theme.card)
            }
            .scrollContentBackground(.hidden)
            // Keep the first header clear of the navigation bar's scroll-edge fade.
            .contentMargins(.top, 16, for: .scrollContent)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(Theme.accent)
    }

    private func stepDefaultTip(_ delta: Int) {
        settings.defaultTipPercent = (settings.defaultTipPercent + delta).clamped(to: TipCalculator.tipRange)
    }

    private var percentText: String {
        (Decimal(settings.defaultTipPercent) / 100).formatted(.percent)
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "2.0"
    }
}

private struct SectionHeader: View {
    let title: LocalizedStringKey
    init(_ title: LocalizedStringKey) { self.title = title }

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.ink2)
            .textCase(nil)
            .accessibilityAddTraits(.isHeader)
    }
}

/// The Settings row: flag, currency name, and code with symbol, e.g. "EUR · €".
private struct CurrencyLabel: View {
    let choice: CurrencyChoice

    var body: some View {
        let money = Money(code: choice.code())
        HStack(spacing: 12) {
            CurrencyFlag(choice: choice)
            Text(choice.displayName())
            Spacer(minLength: 8)
            Text(CurrencyPickerView.detail(for: money))
                .foregroundStyle(Theme.ink2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Currency")
        .accessibilityValue(choice.displayName())
    }
}
