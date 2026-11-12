// 產生 App Icon(Light / Dark / Tinted)與 Launch Screen 圖片。
// 用法:swift Scripts/generate_assets.swift <專案根目錄>
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1
    ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("MLAtlas/Resources/Assets.xcassets")
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [
        CGFloat((hex >> 16) & 0xFF) / 255, CGFloat((hex >> 8) & 0xFF) / 255, CGFloat(hex & 0xFF) / 255, alpha,
    ])!
}

func makeContext(_ size: Int, alpha: Bool) -> CGContext {
    let info: CGImageAlphaInfo = alpha ? .premultipliedLast : .noneSkipLast
    return CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                     space: space, bitmapInfo: info.rawValue)!
}

func save(_ ctx: CGContext, to url: URL) {
    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    CGImageDestinationFinalize(dest)
    print("已產生 \(url.lastPathComponent)")
}

func fillGradient(_ ctx: CGContext, _ rect: CGRect, _ colors: [CGColor]) {
    let gradient = CGGradient(colorsSpace: space, colors: colors as CFArray, locations: nil)!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: rect.minX, y: rect.maxY),
                           end: CGPoint(x: rect.maxX, y: rect.minY), options: [])
}

/// 畫一個 2-3-2 的小型神經網路圖示
func drawGlyph(_ ctx: CGContext, in rect: CGRect, line: CGColor, nodes: [CGColor]) {
    let layers = [2, 3, 2]
    var points: [[CGPoint]] = []
    for (i, count) in layers.enumerated() {
        let x = rect.minX + rect.width * (0.14 + 0.36 * CGFloat(i))
        let span = rect.height * (count == 3 ? 0.66 : 0.36)
        points.append((0..<count).map { j in
            CGPoint(x: x, y: rect.midY + (CGFloat(j) / CGFloat(count - 1) - 0.5) * span)
        })
    }
    ctx.setLineCap(.round)
    ctx.setLineWidth(rect.width * 0.03)
    ctx.setStrokeColor(line)
    for l in 0..<(points.count - 1) {
        for a in points[l] {
            for b in points[l + 1] {
                ctx.move(to: a)
                ctx.addLine(to: b)
                ctx.strokePath()
            }
        }
    }
    let r = rect.width * 0.09
    for (i, layer) in points.enumerated() {
        ctx.setFillColor(nodes[i])
        for p in layer {
            ctx.fillEllipse(in: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r))
        }
    }
}

// MARK: App Icon(需求 15)
let iconDir = assets.appendingPathComponent("AppIcon.appiconset")
let full = CGRect(x: 0, y: 0, width: 1024, height: 1024)
let glyphRect = full.insetBy(dx: 215, dy: 215)

do { // Light
    let ctx = makeContext(1024, alpha: false)
    fillGradient(ctx, full, [rgb(0x2E1A52), rgb(0x6B4BA6)])
    drawGlyph(ctx, in: glyphRect, line: rgb(0xFFFFFF, 0.55), nodes: [rgb(0xFFFFFF), rgb(0xE2C692), rgb(0xFFFFFF)])
    save(ctx, to: iconDir.appendingPathComponent("AppIcon.png"))
}
do { // Dark
    let ctx = makeContext(1024, alpha: false)
    fillGradient(ctx, full, [rgb(0x120D1C), rgb(0x2A1B47)])
    drawGlyph(ctx, in: glyphRect, line: rgb(0x9C7BD6, 0.6), nodes: [rgb(0xC4AEEA), rgb(0xD4B483), rgb(0xC4AEEA)])
    save(ctx, to: iconDir.appendingPathComponent("AppIcon-Dark.png"))
}
do { // Tinted(灰階,由系統上色)
    let ctx = makeContext(1024, alpha: false)
    ctx.setFillColor(rgb(0x000000))
    ctx.fill(full)
    drawGlyph(ctx, in: glyphRect, line: rgb(0x8A8A8A), nodes: [rgb(0xFFFFFF), rgb(0xDDDDDD), rgb(0xFFFFFF)])
    save(ctx, to: iconDir.appendingPathComponent("AppIcon-Tinted.png"))
}

// MARK: Launch Screen 圖片(需求 16)
let logoDir = assets.appendingPathComponent("LaunchLogo.imageset")
for scale in 1...3 {
    let size = 200 * scale
    let ctx = makeContext(size, alpha: true)
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let badge = CGPath(roundedRect: rect, cornerWidth: CGFloat(size) * 0.225, cornerHeight: CGFloat(size) * 0.225, transform: nil)
    ctx.addPath(badge)
    ctx.clip()
    fillGradient(ctx, rect, [rgb(0x2E1A52), rgb(0x6B4BA6)])
    drawGlyph(ctx, in: rect.insetBy(dx: CGFloat(size) * 0.21, dy: CGFloat(size) * 0.21),
              line: rgb(0xFFFFFF, 0.55), nodes: [rgb(0xFFFFFF), rgb(0xE2C692), rgb(0xFFFFFF)])
    save(ctx, to: logoDir.appendingPathComponent(scale == 1 ? "LaunchLogo.png" : "LaunchLogo@\(scale)x.png"))
}
