import CoreGraphics

/// Mr Tipster's handlebar mustache, as vector geometry.
///
/// Plain CoreGraphics so `Scripts/make-icon.swift` can draw the app icon from the
/// same shape. Coordinates are in a unit space where the full mustache is 1 wide
/// and `aspect` tall, with the center joint at x = 0.5.
enum MustacheGeometry {
    static let aspect: CGFloat = 0.36

    /// Where the halves meet; each half rotates around this point to curl or droop.
    static let pivot = CGPoint(x: 0.5, y: 0.18)

    /// The right half. Mirror it for the left half.
    static func rightHalf(in rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y / aspect * rect.height)
        }
        // Start a hair left of center so the halves overlap without a seam.
        path.move(to: p(0.485, 0.125))
        path.addCurve(to: p(0.76, 0.085), control1: p(0.55, -0.025), control2: p(0.68, -0.03))
        path.addCurve(to: p(0.915, 0.185), control1: p(0.82, 0.15), control2: p(0.86, 0.215))
        path.addCurve(to: p(0.945, 0.04), control1: p(0.955, 0.165), control2: p(0.97, 0.09))
        path.addCurve(to: p(0.955, 0.255), control1: p(1.005, 0.07), control2: p(1.02, 0.19))
        path.addCurve(to: p(0.70, 0.30), control1: p(0.89, 0.325), control2: p(0.79, 0.345))
        path.addCurve(to: p(0.485, 0.225), control1: p(0.61, 0.26), control2: p(0.54, 0.215))
        path.closeSubpath()
        return path
    }

    static func leftHalf(in rect: CGRect) -> CGPath {
        var mirror = CGAffineTransform(translationX: rect.midX * 2, y: 0).scaledBy(x: -1, y: 1)
        return rightHalf(in: rect).copy(using: &mirror) ?? CGMutablePath()
    }
}
