import SwiftUI

/// 需求 6:以 Canvas 繪製的示意動畫(t 為時間,單位秒)
@MainActor
enum CanvasDemos {}

// MARK: - Logistic Regression

extension CanvasDemos {
    static func logistic(_ ctx: GraphicsContext, _ size: CGSize, _ t: Double, _ tint: Color) {
        let rect = CGRect(origin: .zero, size: size).insetBy(dx: 18, dy: 26)
        func point(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: rect.minX + (x + 6) / 12 * rect.width, y: rect.maxY - y * rect.height)
        }
        func sigmoid(_ x: Double) -> Double { 1 / (1 + exp(-x)) }

        // 座標軸與 0.5 門檻
        Draw.line(ctx, point(-6, 0), point(6, 0), .secondary.opacity(0.5), width: 1)
        Draw.line(ctx, point(-6, 1), point(6, 1), .secondary.opacity(0.3), width: 1, dash: [3, 3])
        Draw.line(ctx, point(-6, 0.5), point(6, 0.5), .orange.opacity(0.7), width: 1, dash: [5, 4])
        Draw.text(ctx, "門檻 0.5", at: point(-6, 0.5), color: .orange, anchor: .bottomLeading)
        Draw.text(ctx, "1", at: point(-6, 1), anchor: .bottomLeading)
        Draw.text(ctx, "0", at: point(-6, 0), anchor: .topLeading)

        // 兩類樣本
        for x in [-5.2, -4.1, -3.3, -2.4, -1.5, -0.6, 0.7] { Draw.dot(ctx, point(x, 0), 4, .gray) }
        for x in [-0.9, 0.5, 1.4, 2.2, 3.1, 4.0, 5.1] { Draw.dot(ctx, point(x, 1), 4, tint) }

        // sigmoid 曲線
        var curve = Path()
        for index in 0...80 {
            let x = -6 + 12 * Double(index) / 80
            let p = point(x, sigmoid(x))
            if index == 0 { curve.move(to: p) } else { curve.addLine(to: p) }
        }
        ctx.stroke(curve, with: .color(tint), style: StrokeStyle(lineWidth: 3, lineCap: .round))

        // 沿著曲線來回移動的點
        let progress = Draw.cycle(t, 6)
        let triangle = progress < 0.5 ? progress * 2 : (1 - progress) * 2
        let x = -6 + 12 * Draw.smooth(triangle)
        let y = sigmoid(x)
        let marker = point(x, y)
        let isPositive = y >= 0.5
        Draw.line(ctx, point(x, 0), marker, .secondary.opacity(0.6), width: 1, dash: [3, 3])
        Draw.dot(ctx, marker, 8, isPositive ? tint : .gray)
        Draw.ring(ctx, marker, 8, .primary, width: 1.5)
        Draw.text(ctx, String(format: "P = %.2f", y), at: CGPoint(x: marker.x, y: marker.y - 18),
                  font: .caption.weight(.bold), color: .primary)
        Draw.text(ctx, isPositive ? "預測:正類 ✓" : "預測:負類 ✗",
                  at: CGPoint(x: size.width / 2, y: size.height - 10),
                  font: .caption.weight(.semibold), color: isPositive ? tint : .secondary)
    }
}

// MARK: - Random Forest

extension CanvasDemos {
    private static let forestPaths = [[0, 1], [1, 0], [0, 0]]   // 每棵樹走的分支(左 0 / 右 1)
    private static let forestVotes = [0, 1, 0]                  // 每棵樹的預測類別

    static func randomForest(_ ctx: GraphicsContext, _ size: CGSize, _ t: Double, _ tint: Color) {
        let stage = Int(Draw.cycle(t, 6) * 6)                   // 0...2 逐棵點亮,3...5 顯示投票結果
        let classColors: [Color] = [tint, .orange]
        let classNames = ["A", "B"]
        let columnWidth = size.width / 3
        let top: CGFloat = 20
        let levelHeight = (size.height - 96) / 2

        for tree in 0..<3 {
            let isActive = stage >= tree
            let centerX = columnWidth * (CGFloat(tree) + 0.5)
            let root = CGPoint(x: centerX, y: top)
            let path = forestPaths[tree]
            let idle = Color.secondary.opacity(0.35)

            for branch in 0..<2 {
                let child = CGPoint(x: centerX + (branch == 0 ? -1 : 1) * columnWidth * 0.23, y: top + levelHeight)
                let onPath = isActive && path[0] == branch
                Draw.line(ctx, root, child, onPath ? tint : idle, width: onPath ? 3 : 1.5)

                for leafIndex in 0..<2 {
                    let leaf = CGPoint(x: child.x + (leafIndex == 0 ? -1 : 1) * columnWidth * 0.11,
                                       y: top + levelHeight * 2)
                    let isChosen = onPath && path[1] == leafIndex
                    Draw.line(ctx, child, leaf, isChosen ? tint : idle, width: isChosen ? 3 : 1.5)
                    Draw.dot(ctx, leaf, isChosen ? 8 : 5, isChosen ? classColors[forestVotes[tree]] : idle)
                }
                Draw.dot(ctx, child, 6, onPath ? tint : idle)
            }
            Draw.dot(ctx, root, 7, isActive ? tint : idle)

            let labelY = top + levelHeight * 2 + 22
            Draw.text(ctx, "Tree \(tree + 1)", at: CGPoint(x: centerX, y: labelY))
            if isActive {
                Draw.text(ctx, "投給 \(classNames[forestVotes[tree]])", at: CGPoint(x: centerX, y: labelY + 16),
                          font: .caption.weight(.bold), color: classColors[forestVotes[tree]])
            }
        }

        let bottom = CGPoint(x: size.width / 2, y: size.height - 10)
        if stage >= 3 {
            Draw.text(ctx, "多數決:A 2 票、B 1 票 → 預測類別 A", at: bottom, font: .caption.weight(.bold), color: tint)
        } else {
            Draw.text(ctx, "每棵樹各自做出預測…", at: bottom, font: .caption)
        }
    }
}

// MARK: - Support Vector Machine

extension CanvasDemos {
    /// 以 (離分隔線的距離, 沿分隔線的位置) 表示的樣本;距離 0.14 的就是支援向量
    private static let svmPoints: [CGPoint] = {
        var rng = SeededGenerator(seed: 5)
        var result = [CGPoint(x: 0.14, y: -0.12), CGPoint(x: 0.14, y: 0.2), CGPoint(x: -0.14, y: 0.04)]
        for side in [1.0, -1.0] {
            for _ in 0..<9 {
                result.append(CGPoint(x: side * Double.random(in: 0.19...0.36, using: &rng),
                                      y: Double.random(in: -0.3...0.3, using: &rng)))
            }
        }
        return result
    }()

    static func svm(_ ctx: GraphicsContext, _ size: CGSize, _ t: Double, _ tint: Color) {
        let unit = min(size.width, size.height - 20)
        let center = CGPoint(x: size.width / 2, y: (size.height - 20) / 2)
        let angle = 20.0 * .pi / 180
        let normal = CGPoint(x: cos(angle), y: sin(angle))
        let tangent = CGPoint(x: -sin(angle), y: cos(angle))
        func position(_ distance: Double, _ along: Double) -> CGPoint {
            CGPoint(x: center.x + (normal.x * distance + tangent.x * along) * unit,
                    y: center.y + (normal.y * distance + tangent.y * along) * unit)
        }

        let progress = Draw.cycle(t, 5)
        let margin = 0.14 * Draw.smooth(progress / 0.6)
        let touched = margin > 0.135

        // 間隔區域與邊界
        var band = Path()
        band.move(to: position(margin, -0.6))
        band.addLine(to: position(margin, 0.6))
        band.addLine(to: position(-margin, 0.6))
        band.addLine(to: position(-margin, -0.6))
        band.closeSubpath()
        ctx.fill(band, with: .color(tint.opacity(0.12)))
        Draw.line(ctx, position(margin, -0.6), position(margin, 0.6), tint.opacity(0.7), width: 1.5, dash: [5, 4])
        Draw.line(ctx, position(-margin, -0.6), position(-margin, 0.6), tint.opacity(0.7), width: 1.5, dash: [5, 4])
        Draw.line(ctx, position(0, -0.6), position(0, 0.6), tint, width: 3)

        for (index, sample) in svmPoints.enumerated() {
            let p = position(sample.x, sample.y)
            Draw.dot(ctx, p, 5, sample.x > 0 ? .orange : .teal)
            if index < 3, touched {
                Draw.ring(ctx, p, 10, .primary, width: 2)   // 支援向量
            }
        }

        Draw.text(ctx, touched ? "間隔最大化完成:圈起來的是支援向量" : "放大間隔 margin 中…",
                  at: CGPoint(x: size.width / 2, y: size.height - 10),
                  font: .caption.weight(.semibold), color: touched ? tint : .secondary)
    }
}

// MARK: - DBSCAN

extension CanvasDemos {
    private static let dbscanClusters: [[CGPoint]] = {
        var rng = SeededGenerator(seed: 21)
        var first: [CGPoint] = [], second: [CGPoint] = []
        for index in 0..<16 {
            let u = Double(index) / 15
            first.append(CGPoint(x: 0.1 + 0.38 * u + Double.random(in: -0.015...0.015, using: &rng),
                                 y: 0.5 - 0.26 * sin(u * .pi) + Double.random(in: -0.03...0.03, using: &rng)))
            // 第二群與第一群之間留下大於 ε 的間隔,才會被視為不同群集
            second.append(CGPoint(x: 0.6 + 0.34 * u + Double.random(in: -0.015...0.015, using: &rng),
                                  y: 0.62 + 0.2 * sin(u * .pi) + Double.random(in: -0.03...0.03, using: &rng)))
        }
        return [first, second]
    }()

    private static let dbscanNoise = [CGPoint(x: 0.92, y: 0.16), CGPoint(x: 0.06, y: 0.88), CGPoint(x: 0.6, y: 0.1),
                                      CGPoint(x: 0.3, y: 0.86), CGPoint(x: 0.76, y: 0.34)]

    static func dbscan(_ ctx: GraphicsContext, _ size: CGSize, _ t: Double, _ tint: Color) {
        let area = CGSize(width: size.width, height: size.height - 22)
        func position(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * area.width, y: p.y * area.height) }

        let progress = Draw.cycle(t, 8)
        let all = dbscanClusters[0] + dbscanClusters[1]
        let revealed = min(progress / 0.78, 1) * Double(all.count)
        let colors: [Color] = [tint, .indigo]
        let epsilon = area.width * 0.085

        for (index, point) in all.enumerated() {
            let p = position(point)
            let isRevealed = Double(index) < revealed
            Draw.dot(ctx, p, 5, isRevealed ? colors[index < 16 ? 0 : 1] : .secondary.opacity(0.5))
            // 目前正在擴張的點:畫出半徑 ε
            if index == Int(revealed), revealed < Double(all.count) {
                Draw.ring(ctx, p, epsilon, colors[index < 16 ? 0 : 1], width: 1.5, dash: [4, 3])
                Draw.text(ctx, "ε", at: CGPoint(x: p.x + epsilon + 8, y: p.y), font: .caption.weight(.bold), color: .primary)
            }
        }

        let done = progress > 0.8
        for point in dbscanNoise {
            let p = position(point)
            if done {
                Draw.symbol(ctx, "xmark", at: p, font: .caption.weight(.bold), color: .red)
            } else {
                Draw.dot(ctx, p, 5, .secondary.opacity(0.5))
            }
        }

        Draw.text(ctx, done ? "完成:2 個群集,✗ 為雜訊點" : "沿著密度相連的鄰居擴張群集…",
                  at: CGPoint(x: size.width / 2, y: size.height - 10),
                  font: .caption.weight(.semibold), color: done ? tint : .secondary)
    }
}

// MARK: - PCA

extension CanvasDemos {
    /// 以 (沿主軸的位置, 垂直主軸的偏移) 表示的資料點
    private static let pcaPoints: [CGPoint] = {
        var rng = SeededGenerator(seed: 3)
        return (0..<30).map { _ in
            CGPoint(x: Double.random(in: -0.4...0.4, using: &rng), y: Double.random(in: -0.09...0.09, using: &rng))
        }
    }()

    static func pca(_ ctx: GraphicsContext, _ size: CGSize, _ t: Double, _ tint: Color) {
        let unit = min(size.width, (size.height - 22) * 1.3)
        let center = CGPoint(x: size.width / 2, y: (size.height - 22) / 2)
        let target = -24.0 * .pi / 180                      // 資料實際的主要方向
        let direction = CGPoint(x: cos(target), y: sin(target))
        let perpendicular = CGPoint(x: -sin(target), y: cos(target))

        let progress = Draw.cycle(t, 8)
        let rotation = Draw.smooth(progress / 0.35)          // 軸旋轉到主成分方向
        let projection = Draw.smooth((progress - 0.42) / 0.28) // 點投影到軸上

        // 目前的軸
        let axisAngle = target + (1 - rotation) * 1.4
        let axis = CGPoint(x: cos(axisAngle), y: sin(axisAngle))
        let from = CGPoint(x: center.x - axis.x * unit * 0.48, y: center.y - axis.y * unit * 0.48)
        let to = CGPoint(x: center.x + axis.x * unit * 0.48, y: center.y + axis.y * unit * 0.48)
        Draw.line(ctx, from, to, tint, width: 3)
        Draw.dot(ctx, to, 5, tint)
        Draw.text(ctx, "PC1", at: CGPoint(x: to.x - 4, y: to.y - 14), font: .caption.weight(.bold), color: tint)

        if rotation >= 1 {
            let length = unit * 0.14 * (1 - projection)
            Draw.line(ctx, CGPoint(x: center.x - perpendicular.x * length, y: center.y - perpendicular.y * length),
                      CGPoint(x: center.x + perpendicular.x * length, y: center.y + perpendicular.y * length),
                      .orange.opacity(0.8), width: 2)
        }

        for sample in pcaPoints {
            let offset = sample.y * (1 - projection)
            let p = CGPoint(x: center.x + (direction.x * sample.x + perpendicular.x * offset) * unit,
                            y: center.y + (direction.y * sample.x + perpendicular.y * offset) * unit)
            Draw.dot(ctx, p, 4.5, Color.primary.opacity(0.7))
        }

        let message = progress < 0.38 ? "尋找變異最大的方向…"
            : progress < 0.72 ? "把資料投影到第一主成分 PC1" : "降維完成:2 維 → 1 維"
        Draw.text(ctx, message, at: CGPoint(x: size.width / 2, y: size.height - 10),
                  font: .caption.weight(.semibold), color: progress < 0.72 ? .secondary : tint)
    }
}

// MARK: - Q-Learning

extension CanvasDemos {
    /// 代理人走的路徑(欄, 列),左下角出發、右上角是終點
    private static let qPath: [(Int, Int)] = [(0, 3), (1, 3), (2, 3), (2, 2), (2, 1), (3, 1), (3, 0)]

    static func qLearning(_ ctx: GraphicsContext, _ size: CGSize, _ t: Double, _ tint: Color) {
        let period = 4.2
        let episode = Int(t / period) % 4
        let progress = Draw.cycle(t, period)

        let cell = min((size.height - 30) / 4, size.width / 4)
        let origin = CGPoint(x: (size.width - cell * 4) / 2, y: 2)
        func rect(_ column: Int, _ row: Int) -> CGRect {
            CGRect(x: origin.x + CGFloat(column) * cell, y: origin.y + CGFloat(row) * cell, width: cell, height: cell)
                .insetBy(dx: 2, dy: 2)
        }
        func centerOf(_ index: Int) -> CGPoint {
            let r = rect(qPath[index].0, qPath[index].1)
            return CGPoint(x: r.midX, y: r.midY)
        }

        // 格子:路徑上的格子依 Q 值上色(越接近終點、訓練越多回合,顏色越深)
        for row in 0..<4 {
            for column in 0..<4 {
                let shape = Path(roundedRect: rect(column, row), cornerRadius: 6)
                if let index = qPath.firstIndex(where: { $0 == (column, row) }) {
                    let value = pow(0.8, Double(qPath.count - 1 - index)) * Double(episode + 1) / 4
                    ctx.fill(shape, with: .color(tint.opacity(0.1 + 0.75 * value)))
                } else if (column, row) == (1, 1) {
                    ctx.fill(shape, with: .color(.red.opacity(0.25)))
                } else {
                    ctx.fill(shape, with: .color(.secondary.opacity(0.12)))
                }
            }
        }
        let pit = rect(1, 1)
        Draw.symbol(ctx, "xmark.octagon.fill", at: CGPoint(x: pit.midX, y: pit.midY), color: .red)
        Draw.symbol(ctx, "flag.checkered", at: centerOf(qPath.count - 1), font: .title3, color: .primary)

        // 代理人沿路徑移動
        let position = progress * Double(qPath.count)
        let index = min(Int(position), qPath.count - 1)
        let next = min(index + 1, qPath.count - 1)
        let agent = Draw.lerp(centerOf(index), centerOf(next), Draw.smooth(position - Double(index)))
        Draw.dot(ctx, agent, cell * 0.24, .white)
        Draw.dot(ctx, agent, cell * 0.18, .primary)

        Draw.text(ctx, "Episode \(episode + 1) / 4:Q 值由終點往回傳遞",
                  at: CGPoint(x: size.width / 2, y: size.height - 10), font: .caption.weight(.semibold), color: tint)
    }
}
