import SwiftUI

/// 固定種子的亂數產生器(SplitMix64),讓示意資料每次都一樣
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// 需求 6:TimelineView + Canvas —— 依時間持續重繪的畫布
struct TimelineCanvas: View {
    let draw: (GraphicsContext, CGSize, Double) -> Void

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                draw(context, size, timeline.date.timeIntervalSinceReferenceDate)
            }
        }
    }
}

/// Canvas 繪圖的小工具
@MainActor
enum Draw {
    static func dot(_ ctx: GraphicsContext, _ p: CGPoint, _ r: CGFloat, _ color: Color) {
        ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)), with: .color(color))
    }

    static func ring(_ ctx: GraphicsContext, _ p: CGPoint, _ r: CGFloat, _ color: Color,
                     width: CGFloat = 1.5, dash: [CGFloat] = []) {
        ctx.stroke(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                   with: .color(color), style: StrokeStyle(lineWidth: width, dash: dash))
    }

    static func line(_ ctx: GraphicsContext, _ a: CGPoint, _ b: CGPoint, _ color: Color,
                     width: CGFloat = 1.5, dash: [CGFloat] = []) {
        var path = Path()
        path.move(to: a)
        path.addLine(to: b)
        ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, dash: dash))
    }

    static func text(_ ctx: GraphicsContext, _ string: String, at p: CGPoint, font: Font = .caption2,
                     color: Color = .secondary, anchor: UnitPoint = .center) {
        ctx.draw(Text(string).font(font).foregroundStyle(color), at: p, anchor: anchor)
    }

    static func symbol(_ ctx: GraphicsContext, _ name: String, at p: CGPoint, font: Font = .body, color: Color) {
        ctx.draw(Text(Image(systemName: name)).font(font).foregroundStyle(color), at: p)
    }

    static func lerp(_ a: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }

    /// 0...1 的平滑曲線(smoothstep)
    static func smooth(_ x: Double) -> Double {
        let c = min(max(x, 0), 1)
        return c * c * (3 - 2 * c)
    }

    /// 以 period 秒為一個循環,回傳 0..<1 的進度
    static func cycle(_ t: Double, _ period: Double) -> Double {
        t.truncatingRemainder(dividingBy: period) / period
    }
}
