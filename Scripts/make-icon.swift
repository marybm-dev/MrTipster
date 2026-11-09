// Renders the Mr Tipster app icons from the same mustache path the app uses.
//
//   swiftc -O Scripts/make-icon.swift MrTipster/Views/MustachePath.swift -o /tmp/make-icon
//   /tmp/make-icon MrTipster/Resources/Assets.xcassets/AppIcon.appiconset
//
// Produces light, dark and tinted 1024px variants (iOS 18 icon appearances).

import AppKit
import CoreGraphics

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

enum Variant: String, CaseIterable { case light, dark, tinted }

func render(_ variant: Variant, size: Int = 1024) -> CGImage {
    let s = CGFloat(size)
    let ctx = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    // Flip so y grows downward, matching the mustache geometry.
    ctx.translateBy(x: 0, y: s)
    ctx.scaleBy(x: 1, y: -1)

    let full = CGRect(x: 0, y: 0, width: s, height: s)
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    switch variant {
    case .light:
        let gradient = CGGradient(colorsSpace: space, colors: [color(0x2A86C9), color(0x0F4A7A)] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: s * 0.4, y: s), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        // Soft glow behind the mustache.
        let glow = CGGradient(colorsSpace: space, colors: [color(0xFFFFFF, 0.22), color(0xFFFFFF, 0)] as CFArray, locations: [0, 1])!
        ctx.drawRadialGradient(glow, startCenter: CGPoint(x: s / 2, y: s * 0.52), startRadius: 0,
                               endCenter: CGPoint(x: s / 2, y: s * 0.52), endRadius: s * 0.5, options: [])
    case .dark:
        let gradient = CGGradient(colorsSpace: space, colors: [color(0x16222F), color(0x05080C)] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: s * 0.4, y: s), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    case .tinted:
        ctx.setFillColor(color(0x000000))
        ctx.fill(full)
    }

    // The mustache.
    let width = s * 0.78
    let rect = CGRect(x: (s - width) / 2, y: s * 0.43, width: width, height: width * 0.36)
    let fill: CGColor = switch variant {
    case .light: color(0xFFFFFF)
    case .dark: color(0x6CB8EE)
    case .tinted: color(0xFFFFFF)
    }
    if variant == .light {
        ctx.setShadow(offset: CGSize(width: 0, height: s * 0.012), blur: s * 0.03, color: color(0x062A47, 0.45))
    }
    // Fill the halves separately (mirrored paths wind in opposite directions)
    // inside one transparency layer so the shadow is cast once.
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    ctx.setFillColor(fill)
    ctx.addPath(MustacheGeometry.leftHalf(in: rect))
    ctx.fillPath()
    ctx.addPath(MustacheGeometry.rightHalf(in: rect))
    ctx.fillPath()
    ctx.endTransparencyLayer()
    ctx.setShadow(offset: .zero, blur: 0)

    // The "%" from the 2017 icon, tucked above as a little coin.
    let coinRadius = s * 0.085
    let coinCenter = CGPoint(x: s / 2, y: s * 0.27)
    let coinColor: CGColor = switch variant {
    case .light: color(0xFFC94A)
    case .dark: color(0xFFC94A)
    case .tinted: color(0xBBBBBB)
    }
    ctx.setFillColor(coinColor)
    ctx.fillEllipse(in: CGRect(x: coinCenter.x - coinRadius, y: coinCenter.y - coinRadius, width: coinRadius * 2, height: coinRadius * 2))

    // Draw "%" with AppKit text, unflipped locally.
    let ns = NSGraphicsContext(cgContext: ctx, flipped: true)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ns
    let font = NSFont.systemFont(ofSize: coinRadius * 1.25, weight: .heavy)
    let rounded = font.fontDescriptor.withDesign(.rounded).flatMap { NSFont(descriptor: $0, size: font.pointSize) } ?? font
    let textColor: NSColor = variant == .tinted ? .black : NSColor(cgColor: color(0x0F4A7A))!
    let attributed = NSAttributedString(string: "%", attributes: [.font: rounded, .foregroundColor: textColor])
    let textSize = attributed.size()
    attributed.draw(at: CGPoint(x: coinCenter.x - textSize.width / 2, y: coinCenter.y - textSize.height / 2))
    NSGraphicsContext.restoreGraphicsState()

    return ctx.makeImage()!
}

@main
struct MakeIcon {
    static func main() throws {
        let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
        for variant in Variant.allCases {
            let image = render(variant)
            let rep = NSBitmapImageRep(cgImage: image)
            let url = URL(fileURLWithPath: outDir).appendingPathComponent("AppIcon-\(variant.rawValue).png")
            try rep.representation(using: .png, properties: [:])!.write(to: url)
            print("wrote \(url.path)")
        }
    }
}
