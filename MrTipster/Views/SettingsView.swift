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
                    Text("Tipping")
                } footer: {
                    Text("Every new bill starts with this tip.")
                }

                Section {
                    Picker("Currency", selection: $settings.currency) {
                        ForEach(CurrencyChoice.allCases) { choice in
                            HStack(spacing: 12) {
                                Text(choice.flag)
                                    .accessibilityHidden(true)
                                Text(choice.displayName())
                            }
                            .tag(choice)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Currency")
                } footer: {
                    Text("Amounts use your device's number format.")
                }

                Section {
                    HStack(spacing: 16) {
                        MascotView(mood: .pleased, color: Theme.accent)
                            .frame(width: 56)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mr Tipster")
                                .font(.headline)
                            Text("Version \(version)")
                                .font(.subheadline)
                                .foregroundStyle(Theme.ink2)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    Text("Originally built in 2017 for CodePath. Revived in 2026, mustache intact.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink2)
                } header: {
                    Text("About")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
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
