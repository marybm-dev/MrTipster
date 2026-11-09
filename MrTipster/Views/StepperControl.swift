import SwiftUI

/// A big, friendly − value + control.
///
/// For VoiceOver it is a single adjustable element (swipe up/down), and its value can
/// include the updated result so people hear the new total right away. The −/+
/// buttons are also exposed as custom actions for Voice Control and Switch Control.
struct StepperControl: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    /// What's shown, e.g. "20%" or "3 people".
    let display: String
    /// What VoiceOver says as the value, e.g. "20%, Total $154.80".
    let accessibilityValue: String
    var decrementLabel: String
    var incrementLabel: String
    var compact = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title3) private var buttonSize: CGFloat = 52
    @ScaledMetric(relativeTo: .body) private var compactButtonSize: CGFloat = 44

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                // Too big to sit side by side: value on top, buttons below.
                VStack(alignment: .leading, spacing: 12) {
                    valueText.frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 16) {
                        button(.decrement)
                        button(.increment)
                        Spacer(minLength: 0)
                    }
                }
            } else {
                HStack(spacing: 12) {
                    button(.decrement)
                    valueText
                        .frame(maxWidth: compact ? nil : .infinity)
                        .frame(minWidth: compact ? 64 : nil)
                    button(.increment)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: value)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(accessibilityValue)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: step(+1)
            case .decrement: step(-1)
            @unknown default: break
            }
        }
        .accessibilityAction(named: incrementLabel) { step(+1) }
        .accessibilityAction(named: decrementLabel) { step(-1) }
    }

    private var valueText: some View {
        Text(display)
            .font(.system(compact ? .title3 : .title, design: .rounded, weight: .bold))
            .monospacedDigit()
            .contentTransition(reduceMotion ? .identity : .numericText(value: Double(value)))
            .animation(reduceMotion ? nil : .snappy, value: value)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private enum Direction { case decrement, increment }

    private func button(_ direction: Direction) -> some View {
        let isIncrement = direction == .increment
        let enabled = isIncrement ? value < range.upperBound : value > range.lowerBound
        return Button {
            step(isIncrement ? +1 : -1)
        } label: {
            Image(systemName: isIncrement ? "plus" : "minus")
                .font(.system(compact ? .body : .title3, weight: .bold))
                .frame(width: compact ? compactButtonSize : buttonSize, height: compact ? compactButtonSize : buttonSize)
                .background(Theme.chip, in: .circle)
                .overlay { ContrastBorder(shape: Circle()) }
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.accent)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
        .buttonRepeatBehavior(.enabled)
    }

    private func step(_ delta: Int) {
        value = (value + delta).clamped(to: range)
    }
}

/// An accent outline that only appears with Increase Contrast, so controls whose
/// fill is subtle still have a visible edge.
struct ContrastBorder<S: InsettableShape>: View {
    let shape: S
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        if contrast == .increased {
            shape.strokeBorder(Theme.accent, lineWidth: 2)
        }
    }
}

/// Lays out equal-width items in as many columns as fit, wrapping to new rows.
/// Used for the tip presets so they fill the row normally and wrap at large text sizes.
struct EqualWidthGrid: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? idealWidth(subviews) * CGFloat(subviews.count)
        let rows = rows(width: width, subviews: subviews)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(width: row.itemWidth, height: row.height)
                )
                x += row.itemWidth + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: Range<Int>
        var itemWidth: CGFloat
        var height: CGFloat
    }

    private func idealWidth(_ subviews: Subviews) -> CGFloat {
        subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
    }

    private func rows(width: CGFloat, subviews: Subviews) -> [Row] {
        guard !subviews.isEmpty else { return [] }
        let ideal = idealWidth(subviews)
        let columns = max(1, min(subviews.count, Int((width + spacing) / (ideal + spacing))))
        let itemWidth = (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        return stride(from: 0, to: subviews.count, by: columns).map { start in
            let indices = start..<min(start + columns, subviews.count)
            let height = indices.map {
                subviews[$0].sizeThatFits(ProposedViewSize(width: itemWidth, height: nil)).height
            }.max() ?? 0
            return Row(indices: indices, itemWidth: itemWidth, height: height)
        }
    }
}
