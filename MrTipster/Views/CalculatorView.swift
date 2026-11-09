import SwiftUI

struct CalculatorView: View {
    @Bindable var model: TipperModel
    var autoFocus = true
    var debug = DebugOptions()

    /// Launch-argument hooks for screenshots and UI tests (Debug builds only).
    struct DebugOptions {
        var scrollToBottom = false
        var showSettings = false
    }

    @FocusState private var billFocused: Bool
    @State private var showingSettings = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var headlineSize: CGFloat = 48

    static let presets = [15, 18, 20, 22, 25]

    private var money: Money { model.money }
    private var result: TipBreakdown { model.breakdown }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    billCard
                    resultCard
                    tipCard
                    splitCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .defaultScrollAnchor(debug.scrollToBottom ? .bottom : .top)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Mr Tipster")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { billFocused = false }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(settings: model.settings)
            }
        }
        .tint(Theme.accent)
        .task {
            if debug.showSettings { showingSettings = true }
            if autoFocus { billFocused = true }
        }
        .onChange(of: model.billText) { model.billTextDidChange() }
        .task(id: model.billText) {
            // After a pause in typing, tell VoiceOver users the new total.
            // Only while editing, not when a restored bill appears at launch.
            guard model.hasBill, billFocused else { return }
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled, billFocused else { return }
            Announcer.announce(model.resultSummary)
        }
        .onChange(of: model.settings.roundUp) { announceResult() }
        .onChange(of: model.settings.defaultTipPercent) { _, new in model.setTip(new) }
        .onChange(of: model.settings.currency) { model.billTextDidChange() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                model.sceneDidBecomeActive()
                if autoFocus && !model.hasBill && !showingSettings { billFocused = true }
            case .inactive, .background:
                model.sceneWillResignActive()
            @unknown default:
                break
            }
        }
        .sensoryFeedback(trigger: model.mood) { old, new in
            new.celebrates && new > old ? .success : nil
        }
        .sensoryFeedback(.increase, trigger: model.settings.roundUp) { _, new in new }
    }

    private func announceResult() {
        guard model.hasBill else { return }
        Announcer.announce(model.resultSummary)
    }

    // MARK: Bill

    private var billCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text("Bill")
                    .font(.headline)
                    .accessibilityHidden(true) // the field carries this label
                Spacer(minLength: 12)
                MascotView(mood: model.mood)
                    .frame(width: 76)
                    .padding(.top, 2)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if money.symbolLeads { symbol }
                TextField(
                    "Bill amount",
                    text: $model.billText,
                    prompt: Text(money.zeroPlaceholder).foregroundStyle(.white.opacity(0.9))
                )
                .keyboardType(.decimalPad)
                .focused($billFocused)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .monospacedDigit()
                .tint(.white)
                .accessibilityIdentifier("billField")
                .accessibilityLabel("Bill amount")
                .accessibilityValue(model.hasBill ? money.format(model.billAmount) : "")
                if !money.symbolLeads { symbol }

                if !model.billText.isEmpty {
                    Button {
                        model.clearBill()
                        billFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear bill")
                    .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 8 }
                }
            }

            Text(model.mood.line)
                .font(.subheadline.weight(.semibold))
                .contentTransition(.opacity)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: model.mood)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("moodLine")
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            LinearGradient(
                colors: [Theme.heroTop, Theme.heroBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(.rect(cornerRadius: Theme.radius))
        }
        .contentShape(.rect)
        .onTapGesture { billFocused = true }
    }

    private var symbol: some View {
        Text(money.symbol)
            .font(.system(.title, design: .rounded, weight: .semibold))
            .accessibilityHidden(true)
    }

    // MARK: Result

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(result.isSplit ? "Each person pays" : "Total")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink2)
                amountText(result.isSplit ? result.perPerson : result.total)
                    .font(.system(size: headlineSize, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accent)
                    .accessibilityIdentifier("headlineAmount")
            }
            .accessibilityElement(children: .combine)

            Divider()

            VStack(spacing: 10) {
                ResultRow(label: tipLabel) { amountText(result.tip) }
                if result.isSplit {
                    ResultRow(label: String(localized: "Total")) { amountText(result.total) }
                }
                if result.roundingExtra > 0 {
                    ResultRow(label: String(localized: "Rounded up by")) { amountText(result.roundingExtra) }
                }
            }
            .font(.body.weight(.medium))
        }
        .card()
        .animation(reduceMotion ? nil : .snappy, value: result.isSplit)
        .animation(reduceMotion ? nil : .snappy, value: result.roundingExtra > 0)
    }

    private var tipLabel: String {
        let percent = (Decimal(result.tipPercent) / 100).formatted(.percent)
        return String(localized: "Tip (\(percent))")
    }

    private func amountText(_ amount: Decimal) -> some View {
        Text(money.format(amount))
            .monospacedDigit()
            .contentTransition(reduceMotion ? .identity : .numericText(value: NSDecimalNumber(decimal: amount).doubleValue))
            .animation(reduceMotion ? nil : .snappy, value: amount)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Tip

    private var tipCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle("Tip", systemImage: "heart.circle.fill")

            StepperControl(
                label: String(localized: "Tip"),
                value: Binding(get: { model.tipPercent }, set: { model.setTip($0) }),
                range: TipCalculator.tipRange,
                display: percentText(model.tipPercent),
                accessibilityValue: "\(percentText(model.tipPercent)), \(model.hasBill ? model.resultSummary : "")",
                decrementLabel: String(localized: "Decrease tip"),
                incrementLabel: String(localized: "Increase tip")
            )
            .accessibilityIdentifier("tipStepper")

            EqualWidthGrid(spacing: 8) {
                ForEach(Self.presets, id: \.self) { preset in
                    PresetChip(title: percentText(preset), isSelected: model.tipPercent == preset) {
                        model.setTip(preset)
                        announceResult()
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Quick tips")
        }
        .card()
    }

    private func percentText(_ percent: Int) -> String {
        (Decimal(percent) / 100).formatted(.percent)
    }

    // MARK: Split

    private var splitCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle("Split", systemImage: "person.2.fill")

            StepperControl(
                label: String(localized: "People"),
                value: Binding(get: { model.people }, set: { model.setPeople($0) }),
                range: TipCalculator.peopleRange,
                display: peopleText(model.people),
                accessibilityValue: model.hasBill && result.isSplit
                    ? "\(peopleText(model.people)), \(model.resultSummary)"
                    : peopleText(model.people),
                decrementLabel: String(localized: "Remove a person"),
                incrementLabel: String(localized: "Add a person")
            )
            .accessibilityIdentifier("peopleStepper")

            PeopleRow(count: model.people)

            Divider()

            Toggle(isOn: Binding(get: { model.settings.roundUp }, set: { model.settings.roundUp = $0 })) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Round up")
                        .font(.body.weight(.semibold))
                    Text(roundingExplanation)
                        .font(.footnote)
                        .foregroundStyle(Theme.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityIdentifier("roundUpToggle")
        }
        .card()
    }

    private func peopleText(_ count: Int) -> String {
        String(localized: "\(count) people")
    }

    private var roundingExplanation: String {
        let increment = money.format(TipCalculator.roundingIncrement(fractionDigits: money.fractionDigits), fractionDigits: 0)
        return result.isSplit
            ? String(localized: "Round each share up to the next \(increment).")
            : String(localized: "Round the total up to the next \(increment).")
    }
}

// MARK: - Pieces

private struct SectionTitle: View {
    let title: LocalizedStringKey
    let systemImage: String

    init(_ title: LocalizedStringKey, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: systemImage).foregroundStyle(Theme.accent)
        }
        .font(.headline)
        .accessibilityAddTraits(.isHeader)
    }
}

private struct ResultRow<Amount: View>: View {
    let label: String
    @ViewBuilder var amount: Amount
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
        layout {
            Text(label)
                .foregroundStyle(Theme.ink2)
                .fixedSize(horizontal: false, vertical: true)
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 12) }
            amount
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct PresetChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .monospacedDigit()
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(isSelected ? Theme.onAccent : Theme.accent)
                .background(isSelected ? Theme.accent : Theme.chip, in: .capsule)
                .overlay { ContrastBorder(shape: Capsule()) }
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .sensoryFeedback(.selection, trigger: isSelected) { _, new in new }
    }
}

/// A little crowd of people, like the 2017 split rows. Decorative.
private struct PeopleRow: View {
    let count: Int
    private let maxShown = 8
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<min(count, maxShown), id: \.self) { _ in
                Image(systemName: "person.fill")
                    .transition(.scale.combined(with: .opacity))
            }
            if count > maxShown {
                Text("+\(count - maxShown)")
                    .font(.subheadline.weight(.semibold))
            }
        }
        .font(.title3)
        .foregroundStyle(Theme.accent)
        .animation(reduceMotion ? nil : .snappy, value: count)
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityHidden(true)
    }
}
