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
                        .accessibilityIdentifier("defaultTipStepper")
                    }
                    .accessibilityElement(children: .contain)
                } header: {
                    SectionHeader("Tipping")
                } footer: {
                    Text("Every new bill starts with this tip.")
                        .foregroundStyle(Theme.ink2)
                }

                Section {
                    Picker("Currency", selection: $settings.currency) {
                        ForEach(CurrencyChoice.allCases) { choice in
                            CurrencyRow(choice: choice)
                            .tag(choice)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    SectionHeader("Currency")
                } footer: {
                    Text("Amounts use your device's number format.")
                        .foregroundStyle(Theme.ink2)
                }

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

private struct CurrencyRow: View {
    let choice: CurrencyChoice
    @ScaledMetric(relativeTo: .body) private var flagSize: CGFloat = 28

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let name = choice.flagImageName {
                    Image(decorative: name)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "globe")
                        .font(.title3)
                        .foregroundStyle(Theme.accent)
                }
            }
            .frame(width: flagSize, height: flagSize)
            .accessibilityHidden(true)
            Text(choice.displayName())
        }
    }
}
