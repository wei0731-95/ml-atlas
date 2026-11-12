import SwiftUI

/// 回歸線:斜率與截距可動畫(座標為 0...1,y 向上)
private struct RegressionLine: Shape {
    var slope: Double
    var intercept: Double

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(slope, intercept) }
        set {
            slope = newValue.first
            intercept = newValue.second
        }
    }

    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY - intercept * rect.height))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - (intercept + slope) * rect.height))
        return path
    }
}

/// 每個點到回歸線的殘差(垂直線段)
private struct ResidualLines: Shape {
    var slope: Double
    var intercept: Double
    let points: [CGPoint]

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(slope, intercept) }
        set {
            slope = newValue.first
            intercept = newValue.second
        }
    }

    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        for point in points {
            let x = rect.minX + point.x * rect.width
            path.move(to: CGPoint(x: x, y: rect.maxY - point.y * rect.height))
            path.addLine(to: CGPoint(x: x, y: rect.maxY - (intercept + slope * point.x) * rect.height))
        }
        return path
    }
}

// 需求 6:Linear Regression —— 回歸線逐步擬合散點
struct LinearRegressionDemo: View {
    let tint: Color

    private static let points: [CGPoint] = {
        var rng = SeededGenerator(seed: 42)
        return (0..<18).map { index in
            let x = 0.06 + 0.88 * Double(index) / 17
            let y = 0.18 + 0.62 * x + Double.random(in: -0.09...0.09, using: &rng)
            return CGPoint(x: x, y: y)
        }
    }()

    @State private var slope = -0.25
    @State private var intercept = 0.75
    @State private var step = 0
    @State private var runID = 0

    private var mse: Double {
        let total = Self.points.reduce(0.0) { sum, point in
            let error = intercept + slope * point.x - point.y
            return sum + error * error
        }
        return total / Double(Self.points.count)
    }

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { geometry in
                let size = geometry.size
                ZStack {
                    ResidualLines(slope: slope, intercept: intercept, points: Self.points)
                        .stroke(Color.red.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    RegressionLine(slope: slope, intercept: intercept)
                        .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    ForEach(Self.points.indices, id: \.self) { index in
                        Circle()
                            .fill(Color.primary.opacity(0.75))
                            .frame(width: 8, height: 8)
                            .position(x: Self.points[index].x * size.width,
                                      y: (1 - Self.points[index].y) * size.height)
                    }
                }
            }
            .aspectRatio(1.6, contentMode: .fit)
            .clipped()
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("步驟 \(step) / 60")
                    Text("MSE \(mse, format: .number.precision(.fractionLength(4)))")
                        .foregroundStyle(tint)
                }
                .font(.caption.monospacedDigit())
                .contentTransition(.numericText())

                Spacer()

                Button("重新擬合", systemImage: "arrow.clockwise") {
                    runID += 1
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }
        }
        .task(id: runID) {
            await fit()
        }
    }

    /// 用梯度下降逐步更新斜率與截距
    private func fit() async {
        // 每次從不同的起始線開始
        slope = runID.isMultiple(of: 2) ? -0.25 : 1.3
        intercept = runID.isMultiple(of: 2) ? 0.75 : -0.1
        step = 0
        let learningRate = 0.5
        let count = Double(Self.points.count)

        for index in 1...60 {
            try? await Task.sleep(for: .milliseconds(70))
            if Task.isCancelled { return }
            var slopeGradient = 0.0, interceptGradient = 0.0
            for point in Self.points {
                let error = intercept + slope * point.x - point.y
                slopeGradient += 2 * error * point.x / count
                interceptGradient += 2 * error / count
            }
            withAnimation(.spring(duration: 0.25)) {
                slope -= learningRate * slopeGradient
                intercept -= learningRate * interceptGradient
                step = index
            }
        }
    }
}

#Preview {
    LinearRegressionDemo(tint: .blue)
        .padding()
}
