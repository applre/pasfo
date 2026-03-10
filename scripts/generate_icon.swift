#!/usr/bin/env swift

import Cocoa

// Generate Pasfo app icon matching the Pencil design exactly.
// All coordinates are specified in 1024px space (matching Pencil node xYj8f),
// then scaled proportionally for each output size.
//
// Pencil design reference (node xYj8f, 1024x1024):
//   Background: gradient #4A90D9→#6B7BE0→#7B68EE, rotation 135, cornerRadius 228
//   Clipboard Body: x:292 y:192 w:440 h:560 cornerRadius:40 fill:#FFFFFFE6 opacity:0.95
//   Clip Tab: x:392 y:136 w:240 h:96 cornerRadius:[24,24,0,0]
//   Clip Hole: x:432 y:160 w:160 h:48 cornerRadius:24 fill:#5A85D8
//   Text Line 1: x:352 y:330 w:220 h:24 cornerRadius:10
//   Text Line 2: x:352 y:384 w:290 h:24 cornerRadius:10
//   Text Line 3: x:352 y:438 w:250 h:24 cornerRadius:10
//   Convert Arrow: lucide refresh-cw, x:608 y:628 w:224 h:224 fill:#FFFFFF

// Lucide refresh-cw SVG (viewBox 0 0 24 24, stroke-based):
//   path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"
//   polyline points="23 4 23 10 17 10"  (top-right arrowhead)
//   polyline points="1 20 1 14 7 14"    (bottom-left arrowhead)

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let s = size
    let scale = s / 1024.0  // Everything in 1024-space

    // Helper: convert Pencil Y (top-down) to macOS Y (bottom-up)
    func py(_ pencilY: CGFloat, height: CGFloat) -> CGFloat {
        return s - pencilY * scale - height * scale
    }

    // ========== BACKGROUND ==========
    let bgCornerRadius = 228 * scale
    let bgRect = NSRect(x: 0, y: 0, width: s, height: s)
    let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: bgCornerRadius, yRadius: bgCornerRadius)

    let gradientColors = [
        NSColor(red: 0x7B/255.0, green: 0x68/255.0, blue: 0xEE/255.0, alpha: 1.0).cgColor,
        NSColor(red: 0x6B/255.0, green: 0x7B/255.0, blue: 0xE0/255.0, alpha: 1.0).cgColor,
        NSColor(red: 0x4A/255.0, green: 0x90/255.0, blue: 0xD9/255.0, alpha: 1.0).cgColor,
    ] as CFArray
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let locations: [CGFloat] = [0.0, 0.5, 1.0]

    context.saveGState()
    bgPath.addClip()
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: locations) {
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: s, y: s),
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
    }
    context.restoreGState()

    // ========== CLIPBOARD BODY ==========
    // Pencil: x:292 y:192 w:440 h:560 cornerRadius:40 fill:#FFFFFFE6 opacity:0.95
    let clipW: CGFloat = 440; let clipH: CGFloat = 560
    let clipX: CGFloat = 292; let clipPencilY: CGFloat = 192
    let clipRadius: CGFloat = 40

    let clipRect = NSRect(
        x: clipX * scale,
        y: py(clipPencilY, height: clipH),
        width: clipW * scale,
        height: clipH * scale
    )
    let clipPath = NSBezierPath(roundedRect: clipRect, xRadius: clipRadius * scale, yRadius: clipRadius * scale)

    // Shadow: blur:40, y-offset:8, color:#00000033
    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -8 * scale),
        blur: 40 * scale,
        color: NSColor(white: 0, alpha: 0.2).cgColor
    )
    NSColor(red: 1, green: 1, blue: 1, alpha: 0.9).setFill()
    clipPath.fill()
    context.restoreGState()

    // Redraw without shadow
    NSColor(red: 1, green: 1, blue: 1, alpha: 0.9).setFill()
    clipPath.fill()

    // ========== CLIP TAB ==========
    // Pencil: x:392 y:136 w:240 h:96 cornerRadius:[24,24,0,0]
    let tabW: CGFloat = 240; let tabH: CGFloat = 96
    let tabX: CGFloat = 392; let tabPencilY: CGFloat = 136
    let tabR: CGFloat = 24

    let tabRect = NSRect(
        x: tabX * scale,
        y: py(tabPencilY, height: tabH),
        width: tabW * scale,
        height: tabH * scale
    )
    // In macOS coords, "top" of Pencil = maxY in macOS. Pencil cornerRadius [24,24,0,0] = top-left, top-right rounded.
    // In macOS bottom-up coords, this means maxY corners are rounded.
    let tabPath = NSBezierPath()
    let tR = tabR * scale
    // Bottom-left (no radius in pencil = bottom corners in pencil = minY in macOS)
    tabPath.move(to: NSPoint(x: tabRect.minX, y: tabRect.minY))
    // Bottom-right (no radius)
    tabPath.line(to: NSPoint(x: tabRect.maxX, y: tabRect.minY))
    // Right side up to top-right corner (rounded in pencil top = maxY in macOS)
    tabPath.line(to: NSPoint(x: tabRect.maxX, y: tabRect.maxY - tR))
    tabPath.appendArc(
        withCenter: NSPoint(x: tabRect.maxX - tR, y: tabRect.maxY - tR),
        radius: tR, startAngle: 0, endAngle: 90
    )
    // Top side to top-left corner
    tabPath.line(to: NSPoint(x: tabRect.minX + tR, y: tabRect.maxY))
    tabPath.appendArc(
        withCenter: NSPoint(x: tabRect.minX + tR, y: tabRect.maxY - tR),
        radius: tR, startAngle: 90, endAngle: 180
    )
    tabPath.close()

    NSColor(red: 1, green: 1, blue: 1, alpha: 0.9).setFill()
    tabPath.fill()

    // ========== CLIP INNER HOLE ==========
    // Pencil: x:432 y:160 w:160 h:48 cornerRadius:24 fill:#5A85D8
    let holeW: CGFloat = 160; let holeH: CGFloat = 48
    let holeX: CGFloat = 432; let holePencilY: CGFloat = 160
    let holeR: CGFloat = 24

    let holeRect = NSRect(
        x: holeX * scale,
        y: py(holePencilY, height: holeH),
        width: holeW * scale,
        height: holeH * scale
    )
    let holePath = NSBezierPath(roundedRect: holeRect, xRadius: holeR * scale, yRadius: holeR * scale)
    NSColor(red: 0x5A/255.0, green: 0x85/255.0, blue: 0xD8/255.0, alpha: 1.0).setFill()
    holePath.fill()

    // ========== TEXT LINES ==========
    // Pencil: fill:#D4DDEF cornerRadius:10
    let lineColor = NSColor(red: 0xD4/255.0, green: 0xDD/255.0, blue: 0xEF/255.0, alpha: 1.0)
    lineColor.setFill()

    struct LineInfo { let x: CGFloat; let y: CGFloat; let w: CGFloat; let h: CGFloat }
    let lines = [
        LineInfo(x: 352, y: 330, w: 220, h: 24),
        LineInfo(x: 352, y: 384, w: 290, h: 24),
        LineInfo(x: 352, y: 438, w: 250, h: 24),
    ]
    let lineR: CGFloat = 10
    for line in lines {
        let lRect = NSRect(
            x: line.x * scale,
            y: py(line.y, height: line.h),
            width: line.w * scale,
            height: line.h * scale
        )
        NSBezierPath(roundedRect: lRect, xRadius: lineR * scale, yRadius: lineR * scale).fill()
    }

    // ========== CONVERT ARROW (lucide refresh-cw) ==========
    // Pencil: x:608 y:628 w:224 h:224 fill:#FFFFFF
    // shadow: blur:16 y-offset:4 color:#00000044
    let arrowX: CGFloat = 608
    let arrowPencilY: CGFloat = 628
    let arrowW: CGFloat = 224
    let arrowH: CGFloat = 224

    // Transform: lucide uses viewBox 0..24, we need to map to arrowW x arrowH in 1024-space, then scale
    let iconScale = arrowW / 24.0 * scale  // scale factor from lucide 24x24 to final pixels
    let iconOffsetX = arrowX * scale
    let iconOffsetY = py(arrowPencilY, height: arrowH)

    // Helper to convert lucide coords (top-down, 0-24) to macOS coords
    func lp(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
        return NSPoint(
            x: iconOffsetX + x * iconScale,
            y: iconOffsetY + (24.0 - y) * iconScale  // flip Y for macOS
        )
    }

    context.saveGState()
    // Shadow
    if size >= 64 {
        context.setShadow(
            offset: CGSize(width: 0, height: -4 * scale),
            blur: 16 * scale,
            color: NSColor(white: 0, alpha: 0.27).cgColor
        )
    }

    let strokeW = max(2.0 * iconScale, 1.0)
    NSColor.white.setStroke()

    // --- Draw the two arcs ---
    // Lucide refresh-cw path: M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15
    // This is two arcs with connecting lines. Let me draw it precisely.

    // Arc 1: from (3.51, 9) sweeping clockwise via arc to (18.36, 5.64), then line to (23, 10)
    // The arc center is at (12, 12) with radius 9, from ~(3.51, 9) to ~(18.36, 5.64)
    // Start angle: atan2(9-12, 3.51-12) = atan2(-3, -8.49) ≈ 199.5° (in standard math)
    // End angle: atan2(5.64-12, 18.36-12) = atan2(-6.36, 6.36) ≈ -45° = 315°
    // But lucide uses "sweep-flag=1" which is clockwise in SVG (counterclockwise in math)

    let arcCenterX: CGFloat = 12.0
    let arcCenterY: CGFloat = 12.0
    let arcRadius: CGFloat = 9.0

    // Arc 1: from angle ~199.5° to ~315° (going clockwise in SVG = counterclockwise in math standard)
    // In macOS NSBezierPath, angles are counterclockwise from east, and clockwise=true means CW visually
    // SVG start: (3.51, 9) -> angle from center (12,12): atan2(12-9, 3.51-12) in macOS flipped...

    // Let me use a more direct approach: parse the SVG path into CGPath
    // For the lucide refresh-cw, the visual is:
    // - Top arc going from upper-left to lower-right with arrowhead at lower-right
    // - Bottom arc going from lower-right to upper-left with arrowhead at upper-left

    // Lucide coords (24x24, Y-down):
    // Path part 1: M3.51,9 then arc(rx:9 ry:9 x-rotation:0 large-arc:0 sweep:1) to implicit end, then L23,10
    //   The arc from (3.51,9) with r=9, large-arc=0, sweep=1 ends at (18.36, 5.64) [computed from 14.85,-3.36 offset]
    //   Actually: M3.51 9 a9 9 0 0 1 14.85 -3.36 means relative arc, end = (3.51+14.85, 9+(-3.36)) = (18.36, 5.64)
    //   Then L23 10 (line to 23,10)
    // Path part 2: M1,14 l4.64,4.36 means line to (5.64, 18.36)
    //   Then A9 9 0 0 0 20.49 15 means arc from (5.64,18.36) to (20.49,15), r=9, large-arc=0, sweep=0

    // Polyline 1: 23,4 -> 23,10 -> 17,10 (top-right arrowhead, V shape)
    // Polyline 2: 1,20 -> 1,14 -> 7,14 (bottom-left arrowhead, V shape)

    // Draw polyline 1 (top-right arrowhead)
    let poly1 = NSBezierPath()
    poly1.lineWidth = strokeW
    poly1.lineCapStyle = .round
    poly1.lineJoinStyle = .round
    poly1.move(to: lp(23, 4))
    poly1.line(to: lp(23, 10))
    poly1.line(to: lp(17, 10))
    poly1.stroke()

    // Draw polyline 2 (bottom-left arrowhead)
    let poly2 = NSBezierPath()
    poly2.lineWidth = strokeW
    poly2.lineCapStyle = .round
    poly2.lineJoinStyle = .round
    poly2.move(to: lp(1, 20))
    poly2.line(to: lp(1, 14))
    poly2.line(to: lp(7, 14))
    poly2.stroke()

    // Draw arc 1: from (3.51, 9) arc to (18.36, 5.64), then line to (23, 10)
    // Arc center in lucide space: (12, 12), radius 9
    // Start angle from center to (3.51, 9): in macOS flipped Y
    // macOS Y-flipped: (3.51, 24-9)=(3.51,15), center=(12, 24-12)=(12,12)
    // angle = atan2(15-12, 3.51-12) = atan2(3, -8.49) ≈ 160.5°
    // End point (18.36, 5.64) -> macOS (18.36, 24-5.64)=(18.36, 18.36)
    // angle = atan2(18.36-12, 18.36-12) = atan2(6.36, 6.36) = 45°
    // SVG sweep=1 (CW in SVG Y-down) = CW in macOS Y-up visually... but NSBezierPath clockwise param
    // In SVG Y-down, sweep=1 is clockwise. In macOS Y-up, same visual direction is counterclockwise.
    // So we need clockwise: false in NSBezierPath

    let startAngle1: CGFloat = 160.5
    let endAngle1: CGFloat = 45.0
    let macArcCX = iconOffsetX + arcCenterX * iconScale
    let macArcCY = iconOffsetY + (24.0 - arcCenterY) * iconScale
    let macArcR = arcRadius * iconScale

    let arc1path = NSBezierPath()
    arc1path.lineWidth = strokeW
    arc1path.lineCapStyle = .round
    arc1path.appendArc(
        withCenter: NSPoint(x: macArcCX, y: macArcCY),
        radius: macArcR,
        startAngle: startAngle1,
        endAngle: endAngle1,
        clockwise: true
    )
    // Line from arc end to (23, 10)
    arc1path.line(to: lp(23, 10))
    arc1path.stroke()

    // Draw arc 2: from (5.64, 18.36) arc to (20.49, 15)
    // macOS coords: (5.64, 24-18.36)=(5.64, 5.64), end: (20.49, 24-15)=(20.49, 9)
    // Start angle from center (12,12): atan2(5.64-12, 5.64-12) = atan2(-6.36, -6.36) = 225°
    // End angle: atan2(9-12, 20.49-12) = atan2(-3, 8.49) ≈ -19.5° = 340.5°
    // SVG sweep=0 (CCW in SVG Y-down) = CCW visually in macOS Y-up... = clockwise: true in NSBezierPath? No.
    // SVG sweep=0 is counterclockwise in SVG Y-down = clockwise in macOS Y-up = clockwise: true

    let startAngle2: CGFloat = 225.0
    let endAngle2: CGFloat = 340.5

    // First draw line from (1,14) to (5.64, 18.36)
    let line2path = NSBezierPath()
    line2path.lineWidth = strokeW
    line2path.lineCapStyle = .round
    line2path.move(to: lp(1, 14))
    line2path.line(to: lp(5.64, 18.36))
    line2path.stroke()

    let arc2path = NSBezierPath()
    arc2path.lineWidth = strokeW
    arc2path.lineCapStyle = .round
    arc2path.appendArc(
        withCenter: NSPoint(x: macArcCX, y: macArcCY),
        radius: macArcR,
        startAngle: startAngle2,
        endAngle: endAngle2,
        clockwise: false
    )
    arc2path.stroke()

    context.restoreGState()

    image.unlockFocus()
    return image
}

func savePNG(image: NSImage, path: String, pixelSize: Int) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    rep.size = NSSize(width: pixelSize, height: pixelSize)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    image.draw(in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize),
               from: .zero, operation: .copy, fraction: 1.0)

    NSGraphicsContext.restoreGraphicsState()

    let pngData = rep.representation(using: .png, properties: [:])!
    try! pngData.write(to: URL(fileURLWithPath: path))
    print("  Saved: \(path) (\(pixelSize)x\(pixelSize))")
}

// --- Main ---
let iconsetDir = "/Users/wangjida/repos/pasfo/Resources/AppIcon.iconset"

let sizes: [(name: String, pixels: Int)] = [
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

print("Generating Pasfo app icons...")

for entry in sizes {
    let image = drawIcon(size: CGFloat(entry.pixels))
    let path = "\(iconsetDir)/\(entry.name)"
    savePNG(image: image, path: path, pixelSize: entry.pixels)
}

print("\nAll icons generated in \(iconsetDir)")
print("Run: iconutil -c icns \(iconsetDir) -o /Users/wangjida/repos/pasfo/Resources/AppIcon.icns")
