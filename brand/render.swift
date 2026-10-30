// Renders one s-family icon from its brand SVG layers: the background given
// as the first argument, the shared s.svg from the same folder, the accent
// given as the second, in that order, to a PNG at the third argument.
// By default the layers sit inside the classic macOS tile (an 824 rounded
// square with a soft shadow), as sview/scripts/make-icon.swift draws them;
// --full-bleed fills the whole square instead, for the GitHub org avatar;
// --size renders at another pixel size, for checking the small sizes.
// The SVGs are the only source; the family rules are in 04-branding.md.
//
//   swift render.swift <background.svg> <accent.svg> <out.png> [--full-bleed] [--size N]
import AppKit

var arguments = Array(CommandLine.arguments.dropFirst())
let fullBleed = arguments.contains("--full-bleed")
arguments.removeAll { $0 == "--full-bleed" }
var size = 1024
if let flag = arguments.firstIndex(of: "--size"), flag + 1 < arguments.count, let value = Int(arguments[flag + 1]) {
    size = value
    arguments.removeSubrange(flag...flag + 1)
}
guard arguments.count == 3 else {
    print("usage: swift render.swift <background.svg> <accent.svg> <out.png> [--full-bleed] [--size N]")
    exit(2)
}
let background = URL(fileURLWithPath: arguments[0])
let glyph = background.deletingLastPathComponent().appendingPathComponent("s.svg")
let accent = URL(fileURLWithPath: arguments[1])
let out = URL(fileURLWithPath: arguments[2])
let layers = [background, glyph, accent].map { url -> NSImage in
    guard let image = NSImage(contentsOf: url) else {
        fatalError("cannot read \(url.path)")
    }
    return image
}

func render(_ size: Int) -> CGImage {
    let space = CGColorSpace(name: CGColorSpace.displayP3)!
    let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: space,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    var tile = CGRect(x: 0, y: 0, width: 1024, height: 1024)
    if !fullBleed {
        tile = CGRect(x: 100, y: 100, width: 824, height: 824)
        let shape = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: CGColor(gray: 0, alpha: 0.35))
        context.addPath(shape)
        context.setFillColor(CGColor(gray: 0.2, alpha: 1))
        context.fillPath()
        context.restoreGState()
        context.addPath(shape)
        context.clip()
    }
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    for layer in layers {
        layer.draw(in: tile, from: .zero, operation: .sourceOver, fraction: 1)
    }
    NSGraphicsContext.current = nil
    return context.makeImage()!
}

let rep = NSBitmapImageRep(cgImage: render(size))
try! rep.representation(using: .png, properties: [:])!.write(to: out)
print("wrote \(out.path)")
