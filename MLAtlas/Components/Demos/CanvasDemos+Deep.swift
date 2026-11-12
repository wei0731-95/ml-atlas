import SwiftUI

// MARK: - Neural Network(MLP / DQN 共用)

extension CanvasDemos {
    /// 需求 6:神經元連線訊號傳遞
    static func network(_ ctx: GraphicsContext, _ size: CGSize, _ t: Double, _ tint: Color,
                        layers: [Int], labels: [String]) {
        let area = CGRect(x: 34, y: 14, width: size.width - 68, height: size.height - 48)
        let positions: [[CGPoint]] = layers.enumerated().map { layerIndex, count in
            let x = area.minX + area.width * CGFloat(layerIndex) / CGFloat(layers.count - 1)
            let spacing = min(area.height / CGFloat(max(count - 1, 1)), 44)
            return (0..<count).map { index in
                CGPoint(x: x, y: area.midY + (CGFloat(index) - CGFloat(count - 1) / 2) * spacing)
            }
        }

        let progress = Draw.cycle(t, 2.8) * Double(layers.count - 1)
        let stage = Int(progress)
        let fraction = progress - Double(stage)

        // 連線
        for layer in 0..<(positions.count - 1) {
            let isActive = layer == stage
            for a in positions[layer] {
                for b in positions[layer + 1] {
                    Draw.line(ctx, a, b, isActive ? tint.opacity(0.45) : .secondary.opacity(0.22), width: isActive ? 1.5 : 1)
                }
            }
        }
        // 沿連線前進的訊號
        if stage < positions.count - 1 {
            for a in positions[stage] {
                for b in positions[stage + 1] {
                    Draw.dot(ctx, Draw.lerp(a, b, fraction), 3, tint)
                }
            }
        }
        // 神經元:訊號抵達時發亮
        for (layerIndex, layer) in positions.enumerated() {
            let glow = max(0, 1 - abs(progress - Double(layerIndex)) * 2.5)
            for p in layer {
                Draw.dot(ctx, p, 15 + 5 * glow, tint.opacity(0.25 * glow))
                Draw.dot(ctx, p, 10 + 2 * glow, tint.opacity(0.45 + 0.55 * glow))
                Draw.ring(ctx, p, 10 + 2 * glow, .white.opacity(0.8), width: 1.5)
            }
            Draw.text(ctx, labels[layerIndex], at: CGPoint(x: layer[0].x, y: size.height - 10),
                      font: .caption2.weight(.semibold))
        }
    }
}

// MARK: - CNN

extension CanvasDemos {
    /// 7×7 的輸入影像:中間一塊亮的方形
    private static let cnnInput: [[Double]] = (0..<7).map { row in
        (0..<7).map { column in (2...4).contains(row) && (2...4).contains(column) ? 1.0 : 0.12 }
    }

    /// 用垂直邊緣偵測的 3×3 卷積核算出的 5×5 特徵圖(已正規化到 -1...1)
    private static let cnnFeature: [[Double]] = (0..<5).map { row in
        (0..<5).map { column in
            var sum = 0.0
            for i in 0..<3 {
                sum += cnnInput[row + i][column + 2] - cnnInput[row + i][column]
            }
            return sum / 3
        }
    }

    static func cnn(_ ctx: GraphicsContext, _ size: CGSize, _ t: Double, _ tint: Color) {
        let cell = min((size.width - 16) / 14.5, (size.height - 40) / 7)
        let totalWidth = cell * 14.5
        let inputOrigin = CGPoint(x: (size.width - totalWidth) / 2, y: 18)
        let featureOrigin = CGPoint(x: inputOrigin.x + cell * 9.5, y: 18 + cell)

        let step = Int(Draw.cycle(t, 25 * 0.24) * 25)
        let kernelRow = step / 5, kernelColumn = step % 5

        func inputRect(_ row: Int, _ column: Int) -> CGRect {
            CGRect(x: inputOrigin.x + CGFloat(column) * cell, y: inputOrigin.y + CGFloat(row) * cell, width: cell, height: cell)
        }
        func featureRect(_ row: Int, _ column: Int) -> CGRect {
            CGRect(x: featureOrigin.x + CGFloat(column) * cell, y: featureOrigin.y + CGFloat(row) * cell, width: cell, height: cell)
        }

        for row in 0..<7 {
            for column in 0..<7 {
                let shape = Path(roundedRect: inputRect(row, column).insetBy(dx: 1, dy: 1), cornerRadius: 3)
                ctx.fill(shape, with: .color(Color.primary.opacity(0.08 + 0.62 * cnnInput[row][column])))
            }
        }

        // 滑動中的 3×3 卷積核
        let window = inputRect(kernelRow, kernelColumn).union(inputRect(kernelRow + 2, kernelColumn + 2))
        ctx.fill(Path(roundedRect: window, cornerRadius: 5), with: .color(tint.opacity(0.22)))
        ctx.stroke(Path(roundedRect: window, cornerRadius: 5), with: .color(tint), lineWidth: 2.5)

        // 特徵圖:已經算過的格子才上色(正值用主色,負值用橘色)
        for row in 0..<5 {
            for column in 0..<5 {
                let shape = Path(roundedRect: featureRect(row, column).insetBy(dx: 1, dy: 1), cornerRadius: 3)
                if row * 5 + column <= step {
                    let value = cnnFeature[row][column]
                    ctx.fill(shape, with: .color((value >= 0 ? tint : Color.orange).opacity(0.12 + 0.88 * abs(value))))
                } else {
                    ctx.stroke(shape, with: .color(.secondary.opacity(0.35)), lineWidth: 1)
                }
            }
        }
        let current = featureRect(kernelRow, kernelColumn)
        ctx.stroke(Path(roundedRect: current, cornerRadius: 4), with: .color(.primary), lineWidth: 2)
        Draw.line(ctx, CGPoint(x: window.maxX, y: window.midY), CGPoint(x: current.minX, y: current.midY),
                  tint.opacity(0.7), width: 1.5, dash: [4, 3])

        Draw.text(ctx, "Input 7×7", at: CGPoint(x: inputOrigin.x + cell * 3.5, y: 8), font: .caption2.weight(.semibold))
        Draw.text(ctx, "Feature map 5×5", at: CGPoint(x: featureOrigin.x + cell * 2.5, y: 8), font: .caption2.weight(.semibold))
        Draw.text(ctx, "3×3 kernel 偵測垂直邊緣(步驟 \(step + 1) / 25)",
                  at: CGPoint(x: size.width / 2, y: size.height - 10), font: .caption.weight(.semibold), color: tint)
    }
}

// MARK: - RNN / LSTM

extension CanvasDemos {
    private static let tokens = ["The", "cat", "sat", "on", "mat"]

    static func rnn(_ ctx: GraphicsContext, _ size: CGSize, _ t: Double, _ tint: Color) {
        let count = tokens.count
        let progress = Draw.cycle(t, 6) * Double(count + 1)   // 多留一拍停在結尾
        let active = min(Int(progress), count - 1)
        let fraction = progress - Double(Int(progress))

        let cellY = size.height * 0.46
        let inputY = size.height * 0.8
        let outputY = size.height * 0.12
        let cellSize = CGSize(width: min(46, size.width / CGFloat(count) - 14), height: 34)
        func x(_ index: Int) -> CGFloat { size.width * (CGFloat(index) + 0.5) / CGFloat(count) }

        for index in 0..<count {
            let seen = index <= active
            let center = CGPoint(x: x(index), y: cellY)
            let color = seen ? tint.opacity(index == active ? 1 : 0.5) : Color.secondary.opacity(0.25)

            // 輸入 → 細胞 → 輸出
            Draw.text(ctx, tokens[index], at: CGPoint(x: center.x, y: inputY),
                      font: .caption.weight(.semibold), color: seen ? .primary : .secondary)
            Draw.line(ctx, CGPoint(x: center.x, y: inputY - 12), CGPoint(x: center.x, y: cellY + cellSize.height / 2 + 3),
                      color, width: 1.5)
            if seen {
                Draw.line(ctx, CGPoint(x: center.x, y: cellY - cellSize.height / 2 - 3), CGPoint(x: center.x, y: outputY + 10),
                          color, width: 1.5)
                Draw.text(ctx, "y\(index + 1)", at: CGPoint(x: center.x, y: outputY), font: .caption2.weight(.semibold))
            }

            let box = CGRect(x: center.x - cellSize.width / 2, y: cellY - cellSize.height / 2,
                             width: cellSize.width, height: cellSize.height)
            ctx.fill(Path(roundedRect: box, cornerRadius: 8), with: .color(color))
            Draw.text(ctx, "h\(index + 1)", at: center, font: .caption.weight(.bold), color: seen ? .white : .secondary)

            // 隱藏狀態傳給下一個時間步
            if index < count - 1 {
                let from = CGPoint(x: box.maxX + 2, y: cellY)
                let to = CGPoint(x: x(index + 1) - cellSize.width / 2 - 2, y: cellY)
                Draw.line(ctx, from, to, index < active ? tint.opacity(0.6) : .secondary.opacity(0.3), width: 2)
                if index == active, Int(progress) < count {
                    Draw.dot(ctx, Draw.lerp(from, to, Draw.smooth(fraction)), 5, tint)
                }
            }
        }

        Draw.text(ctx, "時間步 t = \(active + 1):隱藏狀態 h 攜帶先前的資訊往後傳",
                  at: CGPoint(x: size.width / 2, y: size.height - 10), font: .caption.weight(.semibold), color: tint)
    }
}

// MARK: - Transformer

extension CanvasDemos {
    /// 示意用的注意力權重(每一列總和為 1)
    private static let attention: [[Double]] = [
        [0.50, 0.30, 0.10, 0.05, 0.05],
        [0.25, 0.40, 0.25, 0.05, 0.05],
        [0.05, 0.40, 0.30, 0.10, 0.15],
        [0.05, 0.10, 0.30, 0.30, 0.25],
        [0.15, 0.10, 0.25, 0.20, 0.30],
    ]

    static func transformer(_ ctx: GraphicsContext, _ size: CGSize, _ t: Double, _ tint: Color) {
        let count = tokens.count
        let progress = Draw.cycle(t, Double(count) * 1.5) * Double(count)
        let focus = min(Int(progress), count - 1)
        let appear = Draw.smooth((progress - Double(focus)) * 3)

        let topY = size.height * 0.16
        let bottomY = size.height * 0.72
        let chip = CGSize(width: min(50, size.width / CGFloat(count) - 10), height: 26)
        func x(_ index: Int) -> CGFloat { size.width * (CGFloat(index) + 0.5) / CGFloat(count) }
        func chipRect(_ index: Int, _ y: CGFloat) -> CGRect {
            CGRect(x: x(index) - chip.width / 2, y: y - chip.height / 2, width: chip.width, height: chip.height)
        }

        // 注意力連線:越粗、越不透明代表權重越高
        for target in 0..<count {
            let weight = attention[focus][target]
            Draw.line(ctx, CGPoint(x: x(focus), y: bottomY - chip.height / 2),
                      CGPoint(x: x(target), y: topY + chip.height / 2),
                      tint.opacity((0.15 + 0.85 * weight) * appear), width: 1 + 9 * weight)
        }

        for index in 0..<count {
            let weight = attention[focus][index]
            // 上排:被參考的字
            ctx.fill(Path(roundedRect: chipRect(index, topY), cornerRadius: 8),
                     with: .color(tint.opacity(0.12 + 0.8 * weight * appear)))
            Draw.text(ctx, tokens[index], at: CGPoint(x: x(index), y: topY), font: .caption.weight(.semibold), color: .primary)
            Draw.text(ctx, String(format: "%.0f%%", weight * 100), at: CGPoint(x: x(index), y: topY + chip.height / 2 + 9),
                      font: .caption2, color: .secondary.opacity(appear))
            // 下排:目前正在處理的字
            let isFocus = index == focus
            ctx.fill(Path(roundedRect: chipRect(index, bottomY), cornerRadius: 8),
                     with: .color(isFocus ? tint : .secondary.opacity(0.18)))
            Draw.text(ctx, tokens[index], at: CGPoint(x: x(index), y: bottomY),
                      font: .caption.weight(.semibold), color: isFocus ? .white : .primary)
        }

        Draw.text(ctx, "Self-Attention:「\(tokens[focus])」對每個字的注意力權重",
                  at: CGPoint(x: size.width / 2, y: size.height - 10), font: .caption.weight(.semibold), color: tint)
    }
}

// MARK: - GAN

extension CanvasDemos {
    static func gan(_ ctx: GraphicsContext, _ size: CGSize, _ t: Double, _ tint: Color) {
        let rect = CGRect(x: 14, y: 30, width: size.width - 28, height: size.height - 78)
        let progress = Draw.cycle(t, 7)
        let training = Draw.smooth(progress / 0.75)

        let realMean = 0.66, realSigma = 0.085
        let fakeMean = 0.24 + (realMean - 0.24) * training
        let fakeSigma = 0.17 - (0.17 - realSigma) * training

        func curve(mean: Double, sigma: Double, closed: Bool) -> Path {
            var path = Path()
            if closed { path.move(to: CGPoint(x: rect.minX, y: rect.maxY)) }
            for index in 0...90 {
                let x = Double(index) / 90
                let y = exp(-pow(x - mean, 2) / (2 * sigma * sigma)) * (realSigma / sigma)
                let p = CGPoint(x: rect.minX + x * rect.width, y: rect.maxY - y * rect.height)
                if index == 0, !closed { path.move(to: p) } else { path.addLine(to: p) }
            }
            if closed {
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                path.closeSubpath()
            }
            return path
        }

        Draw.line(ctx, CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.maxX, y: rect.maxY), .secondary.opacity(0.5), width: 1)

        // 真實資料分布
        ctx.fill(curve(mean: realMean, sigma: realSigma, closed: true), with: .color(tint.opacity(0.22)))
        ctx.stroke(curve(mean: realMean, sigma: realSigma, closed: false), with: .color(tint), lineWidth: 2.5)
        // 生成器產生的分布
        ctx.fill(curve(mean: fakeMean, sigma: fakeSigma, closed: true), with: .color(.orange.opacity(0.18)))
        ctx.stroke(curve(mean: fakeMean, sigma: fakeSigma, closed: false), with: .color(.orange),
                   style: StrokeStyle(lineWidth: 2.5, dash: [6, 4]))

        // 圖例
        Draw.dot(ctx, CGPoint(x: 20, y: 12), 5, tint)
        Draw.text(ctx, "真實資料 Real", at: CGPoint(x: 30, y: 12), font: .caption2.weight(.semibold), anchor: .leading)
        Draw.dot(ctx, CGPoint(x: size.width / 2 + 6, y: 12), 5, .orange)
        Draw.text(ctx, "生成器 Generator", at: CGPoint(x: size.width / 2 + 16, y: 12), font: .caption2.weight(.semibold), anchor: .leading)

        let accuracy = Int((0.95 - 0.45 * training) * 100)
        Draw.text(ctx, "訓練進度 \(Int(training * 100))%", at: CGPoint(x: size.width / 2, y: size.height - 30), font: .caption2)
        Draw.text(ctx, "判別器準確率 Discriminator accuracy:\(accuracy)%",
                  at: CGPoint(x: size.width / 2, y: size.height - 10), font: .caption.weight(.semibold),
                  color: training >= 1 ? tint : .secondary)
    }
}
