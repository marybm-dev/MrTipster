import SwiftUI

/// One half of the mustache as a SwiftUI shape.
struct MustacheHalf: Shape {
    enum Side { case left, right }
    var side: Side

    func path(in rect: CGRect) -> Path {
        Path(side == .right ? MustacheGeometry.rightHalf(in: rect) : MustacheGeometry.leftHalf(in: rect))
    }
}

/// Mr Tipster himself. The mustache curls up for good tips, droops for stingy ones,
/// and gives a celebratory twirl when you're generous. Decorative: the mood line next
/// to it carries the meaning for VoiceOver.
struct MascotView: View {
    let mood: Mood
    var color: Color = .white

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var celebrations = 0

    private var pivot: UnitPoint {
        UnitPoint(x: MustacheGeometry.pivot.x, y: MustacheGeometry.pivot.y / MustacheGeometry.aspect)
    }

    var body: some View {
        ZStack {
            MustacheHalf(side: .left)
                .rotationEffect(.degrees(mood.curl), anchor: pivot)
            MustacheHalf(side: .right)
                .rotationEffect(.degrees(-mood.curl), anchor: pivot)
        }
        .foregroundStyle(color)
        .aspectRatio(1 / MustacheGeometry.aspect, contentMode: .fit)
        .keyframeAnimator(initialValue: Twirl(), trigger: celebrations) { content, twirl in
            content
                .rotationEffect(.degrees(twirl.angle))
                .scaleEffect(twirl.scale)
        } keyframes: { _ in
            KeyframeTrack(\.angle) {
                CubicKeyframe(-9, duration: 0.12)
                CubicKeyframe(8, duration: 0.14)
                CubicKeyframe(-5, duration: 0.12)
                SpringKeyframe(0, duration: 0.3, spring: .bouncy)
            }
            KeyframeTrack(\.scale) {
                CubicKeyframe(1.18, duration: 0.18)
                SpringKeyframe(1, duration: 0.5, spring: .bouncy)
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.55), value: mood)
        .onChange(of: mood) { old, new in
            if new.celebrates && new > old && !reduceMotion { celebrations += 1 }
        }
        .accessibilityHidden(true)
    }

    private struct Twirl {
        var angle = 0.0
        var scale = 1.0
    }
}

#Preview {
    VStack(spacing: 24) {
        ForEach(Mood.allCases, id: \.self) { mood in
            HStack {
                MascotView(mood: mood, color: Theme.accent).frame(width: 120)
                Text(mood.line)
            }
        }
    }
    .padding()
}
