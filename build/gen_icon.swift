import Cocoa

// Generate app icon programmatically using Core Graphics
func createIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let pad = s * 0.1
    let rect = CGRect(x: pad, y: pad, width: s - pad * 2, height: s - pad * 2)
    let radius = s * 0.18

    // Background rounded rect with gradient
    let bgPath = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        CGColor(red: 0.165, green: 0.137, blue: 0.125, alpha: 1.0),
        CGColor(red: 0.102, green: 0.09, blue: 0.078, alpha: 1.0)
    ]
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: bgColors as CFArray, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(gradient, start: CGPoint(x: pad, y: s - pad), end: CGPoint(x: s - pad, y: pad), options: [])
    }
    ctx.restoreGState()

    // Subtle inner shadow / border
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.setStrokeColor(CGColor(red: 0.25, green: 0.22, blue: 0.19, alpha: 0.5))
    ctx.setLineWidth(s * 0.008)
    ctx.strokePath()
    ctx.restoreGState()

    // Scale factor for drawing elements
    let scale = s / 1024.0

    // Faint text lines (background detail)
    ctx.saveGState()
    ctx.setStrokeColor(CGColor(red: 0.83, green: 0.80, blue: 0.77, alpha: 0.1))
    ctx.setLineCap(.round)
    ctx.setLineWidth(18 * scale)

    let lines: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
        (280, 680, 520, 680),
        (280, 600, 470, 600),
        (280, 520, 420, 520),
        (280, 440, 380, 440),
    ]
    for (x1, y1, x2, y2) in lines {
        ctx.move(to: CGPoint(x: x1 * scale + pad, y: y1 * scale + pad))
        ctx.addLine(to: CGPoint(x: x2 * scale + pad, y: y2 * scale + pad))
    }
    ctx.strokePath()
    ctx.restoreGState()

    // Pen nib - the main icon element
    let penColor = CGColor(red: 0.91, green: 0.66, blue: 0.33, alpha: 1.0)
    let penColorDark = CGColor(red: 0.77, green: 0.53, blue: 0.29, alpha: 1.0)

    // Pen body (rotated rectangle shape)
    ctx.saveGState()

    let cx = s * 0.58
    let cy = s * 0.42
    let angle = -CGFloat.pi / 4.0

    ctx.translateBy(x: cx, y: cy)
    ctx.rotate(by: angle)

    let penWidth = s * 0.09
    let penHeight = s * 0.42

    // Pen shaft
    let penRect = CGRect(x: -penWidth/2, y: -penHeight * 0.3, width: penWidth, height: penHeight)
    let penPath = CGPath(roundedRect: penRect, cornerWidth: penWidth * 0.15, cornerHeight: penWidth * 0.15, transform: nil)

    // Gradient on pen
    ctx.addPath(penPath)
    ctx.clip()
    let penColors = [penColor, penColorDark]
    if let penGrad = CGGradient(colorsSpace: colorSpace, colors: penColors as CFArray, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(penGrad, start: CGPoint(x: -penWidth/2, y: 0), end: CGPoint(x: penWidth/2, y: 0), options: [])
    }
    ctx.restoreGState()

    // Pen tip (triangle)
    ctx.saveGState()
    ctx.translateBy(x: cx, y: cy)
    ctx.rotate(by: angle)
    ctx.setFillColor(penColorDark)

    let tipPath = CGMutablePath()
    let tipY = -penHeight * 0.3
    tipPath.move(to: CGPoint(x: -penWidth/2, y: tipY))
    tipPath.addLine(to: CGPoint(x: penWidth/2, y: tipY))
    tipPath.addLine(to: CGPoint(x: 0, y: tipY - penHeight * 0.15))
    tipPath.closeSubpath()
    ctx.addPath(tipPath)
    ctx.fillPath()

    // Nib point
    ctx.setFillColor(CGColor(red: 0.95, green: 0.75, blue: 0.4, alpha: 1.0))
    let nibSize = penWidth * 0.25
    let nibRect = CGRect(x: -nibSize/2, y: tipY - penHeight * 0.15 - nibSize * 0.5, width: nibSize, height: nibSize)
    ctx.fillEllipse(in: nibRect)

    ctx.restoreGState()

    // Small ink dot at writing point
    ctx.saveGState()
    let dotX = cx - cos(CGFloat.pi/4) * (penHeight * 0.3 + penHeight * 0.15) * 1.05
    let dotY = cy - sin(CGFloat.pi/4) * (penHeight * 0.3 + penHeight * 0.15) * 1.05
    let dotR = s * 0.018
    ctx.setFillColor(CGColor(red: 0.91, green: 0.66, blue: 0.33, alpha: 0.6))
    ctx.fillEllipse(in: CGRect(x: dotX - dotR, y: dotY - dotR, width: dotR * 2, height: dotR * 2))
    ctx.restoreGState()

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to path: String, size: Int) {
    let s = CGFloat(size)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: s, height: s))
    NSGraphicsContext.restoreGraphicsState()

    if let data = rep.representation(using: .png, properties: [:]) {
        try? data.write(to: URL(fileURLWithPath: path))
    }
}

// Generate iconset
let iconsetPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset"
let fm = FileManager.default
try? fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for (name, size) in sizes {
    let icon = createIcon(size: size)
    let path = (iconsetPath as NSString).appendingPathComponent(name)
    savePNG(icon, to: path, size: size)
}

print("Icon PNGs generated at \(iconsetPath)")
