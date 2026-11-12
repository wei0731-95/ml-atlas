// 需求 14:用 AVFoundation 產生一段 8 秒的示範動畫 mp4,放入 App Bundle。
// 用法:swift Scripts/generate_video.swift MLAtlas/Resources/intro.mp4
import AVFoundation
import CoreGraphics
import CoreText
import Foundation

guard CommandLine.arguments.count > 1 else {
    print("用法:swift generate_video.swift <輸出.mp4>")
    exit(1)
}
let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.removeItem(at: outputURL)

let width = 1280, height = 720
let fps: Int32 = 30
let totalFrames = 8 * Int(fps)
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [
        CGFloat((hex >> 16) & 0xFF) / 255, CGFloat((hex >> 8) & 0xFF) / 255, CGFloat(hex & 0xFF) / 255, alpha,
    ])!
}

func drawText(_ ctx: CGContext, _ string: String, fontName: String, size: CGFloat, color: CGColor, center: CGPoint) {
    let font = CTFontCreateWithName(fontName as CFString, size, nil)
    let attributed = NSAttributedString(string: string, attributes: [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): color,
    ])
    let line = CTLineCreateWithAttributedString(attributed)
    let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
    ctx.textPosition = CGPoint(x: center.x - bounds.width / 2 - bounds.minX, y: center.y - bounds.height / 2 - bounds.minY)
    CTLineDraw(line, ctx)
}

func smooth(_ x: CGFloat) -> CGFloat {
    let c = min(max(x, 0), 1)
    return c * c * (3 - 2 * c)
}

let layers = [3, 5, 5, 2]
let layerColors: [UInt32] = [0xC4AEEA, 0x9C7BD6, 0x9C7BD6, 0xD4B483]

func drawFrame(_ ctx: CGContext, time t: CGFloat) {
    let rect = CGRect(x: 0, y: 0, width: width, height: height)
    // 背景漸層
    let gradient = CGGradient(colorsSpace: space, colors: [rgb(0x120D1C), rgb(0x3A1F63)] as CFArray, locations: nil)!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: rect.maxY), end: CGPoint(x: rect.maxX, y: 0), options: [])

    // 神經網路節點位置
    let area = CGRect(x: 240, y: 110, width: 800, height: 380)
    var points: [[CGPoint]] = []
    for (i, count) in layers.enumerated() {
        let x = area.minX + area.width * CGFloat(i) / CGFloat(layers.count - 1)
        points.append((0..<count).map { j in
            CGPoint(x: x, y: area.midY + (CGFloat(j) - CGFloat(count - 1) / 2) * 78)
        })
    }
    let appear = smooth(t / 1.2)                      // 開場淡入
    let progress = (t.truncatingRemainder(dividingBy: 2.4) / 2.4) * CGFloat(layers.count - 1)

    // 連線
    ctx.setLineWidth(2)
    for l in 0..<(points.count - 1) {
        for a in points[l] {
            for b in points[l + 1] {
                ctx.setStrokeColor(rgb(0xFFFFFF, 0.14 * appear))
                ctx.move(to: a)
                ctx.addLine(to: b)
                ctx.strokePath()
            }
        }
    }
    // 沿著連線移動的訊號
    let stage = Int(progress)
    let fraction = progress - CGFloat(stage)
    if stage < points.count - 1, t > 1.0 {
        ctx.setFillColor(rgb(0xFFFFFF, 0.9))
        for a in points[stage] {
            for b in points[stage + 1] {
                let p = CGPoint(x: a.x + (b.x - a.x) * fraction, y: a.y + (b.y - a.y) * fraction)
                ctx.fillEllipse(in: CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8))
            }
        }
    }
    // 節點
    for (i, layer) in points.enumerated() {
        let glow = max(0, 1 - abs(progress - CGFloat(i)) * 2.2)
        let radius = (20 + 8 * glow) * appear
        for p in layer {
            ctx.setFillColor(rgb(layerColors[i], 0.25 * glow))
            ctx.fillEllipse(in: CGRect(x: p.x - radius * 1.7, y: p.y - radius * 1.7, width: radius * 3.4, height: radius * 3.4))
            ctx.setFillColor(rgb(layerColors[i], appear))
            ctx.fillEllipse(in: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2))
        }
    }
    // 標題文字
    let titleAlpha = smooth((t - 0.6) / 1.2)
    drawText(ctx, "ML  ATLAS", fontName: "TimesNewRomanPS-BoldMT", size: 84, color: rgb(0xFFFFFF, titleAlpha),
             center: CGPoint(x: rect.midX, y: 622))
    let subAlpha = smooth((t - 1.4) / 1.2)
    drawText(ctx, "機器學習模型圖鑑 · Input → Hidden → Output", fontName: "PingFangTC-Regular", size: 30,
             color: rgb(0xD4B483, subAlpha), center: CGPoint(x: rect.midX, y: 548))
    // 結尾淡出,讓影片可以順暢循環
    let fade = smooth((t - 7.3) / 0.7)
    if fade > 0 {
        ctx.setFillColor(rgb(0x120D1C, fade))
        ctx.fill(rect)
    }
}

let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: width,
    AVVideoHeightKey: height,
])
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
    kCVPixelBufferWidthKey as String: width,
    kCVPixelBufferHeightKey as String: height,
])
writer.add(input)
guard writer.startWriting() else {
    print("無法開始寫入:\(String(describing: writer.error))")
    exit(1)
}
writer.startSession(atSourceTime: .zero)

for frame in 0..<totalFrames {
    while !input.isReadyForMoreMediaData { usleep(2000) }
    var buffer: CVPixelBuffer?
    CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &buffer)
    guard let buffer else { continue }
    CVPixelBufferLockBaseAddress(buffer, [])
    let ctx = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height,
                        bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                        space: space, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
    drawFrame(ctx, time: CGFloat(frame) / CGFloat(fps))
    CVPixelBufferUnlockBaseAddress(buffer, [])
    adaptor.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(frame), timescale: fps))
}

input.markAsFinished()
let done = DispatchSemaphore(value: 0)
writer.finishWriting { done.signal() }
done.wait()
print(writer.status == .completed ? "已產生 \(outputURL.path)" : "失敗:\(String(describing: writer.error))")
