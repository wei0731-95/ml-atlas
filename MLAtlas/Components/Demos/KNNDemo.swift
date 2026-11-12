import SwiftUI

// 需求 6:KNN —— 點選一點後高亮最近的 k 個鄰居
struct KNNDemo: View {
    private struct Sample {
        let point: CGPoint
        let label: Int
    }

    private static let aspect: CGFloat = 1.5
    private static let classColors: [Color] = [.blue, .orange]
    private static let classNames = ["藍色", "橘色"]

    private static let samples: [Sample] = {
        var rng = SeededGenerator(seed: 11)
        let centers = [CGPoint(x: 0.32, y: 0.4), CGPoint(x: 0.68, y: 0.6)]
        var result: [Sample] = []
        for (label, center) in centers.enumerated() {
            for _ in 0..<13 {
                let point = CGPoint(x: center.x + CGFloat.random(in: -0.25...0.25, using: &rng),
                                    y: center.y + CGFloat.random(in: -0.3...0.3, using: &rng))
                result.append(Sample(point: point, label: label))
            }
        }
        return result
    }()

    @State private var query = CGPoint(x: 0.5, y: 0.5)
    @State private var k = 3

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot((a.x - b.x) * Self.aspect, a.y - b.y)
    }

    /// 距離查詢點最近的 k 個樣本
    private var neighbors: [Int] {
        Array(Self.samples.indices
            .sorted { distance(Self.samples[$0].point, query) < distance(Self.samples[$1].point, query) }
            .prefix(k))
    }

    private var votes: [Int] {
        var counts = [0, 0]
        for index in neighbors {
            counts[Self.samples[index].label] += 1
        }
        return counts
    }

    private var predicted: Int { votes[0] >= votes[1] ? 0 : 1 }

    var body: some View {
        let neighbors = neighbors
        let radius = neighbors.last.map { distance(Self.samples[$0].point, query) } ?? 0

        VStack(spacing: 10) {
            GeometryReader { geometry in
                let size = geometry.size
                let center = CGPoint(x: query.x * size.width, y: query.y * size.height)
                ZStack {
                    // 涵蓋第 k 個鄰居的範圍
                    Circle()
                        .strokeBorder(Color.secondary, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .frame(width: radius * size.height * 2 + 12, height: radius * size.height * 2 + 12)
                        .position(center)

                    ForEach(neighbors, id: \.self) { index in
                        Path { path in
                            path.move(to: center)
                            path.addLine(to: CGPoint(x: Self.samples[index].point.x * size.width,
                                                     y: Self.samples[index].point.y * size.height))
                        }
                        .stroke(Self.classColors[Self.samples[index].label].opacity(0.7), lineWidth: 1.5)
                        .transition(.opacity)
                    }

                    ForEach(Self.samples.indices, id: \.self) { index in
                        let isNeighbor = neighbors.contains(index)
                        Circle()
                            .fill(Self.classColors[Self.samples[index].label])
                            .frame(width: 10, height: 10)
                            .overlay {
                                Circle()
                                    .stroke(Color.primary, lineWidth: isNeighbor ? 1.5 : 0)
                                    .padding(-3)
                            }
                            .scaleEffect(isNeighbor ? 1.45 : 1)
                            .opacity(isNeighbor ? 1 : 0.55)
                            .position(x: Self.samples[index].point.x * size.width,
                                      y: Self.samples[index].point.y * size.height)
                    }

                    Image(systemName: "diamond.fill")
                        .font(.title2)
                        .foregroundStyle(Self.classColors[predicted])
                        .overlay {
                            Image(systemName: "diamond")
                                .font(.title2)
                                .foregroundStyle(Color.primary)
                        }
                        .position(center)
                }
                .contentShape(Rectangle())
                .gesture(
                    SpatialTapGesture().onEnded { value in
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                            query = CGPoint(x: min(max(value.location.x / size.width, 0.03), 0.97),
                                            y: min(max(value.location.y / size.height, 0.05), 0.95))
                        }
                    }
                )
            }
            .aspectRatio(Self.aspect, contentMode: .fit)
            .clipped()
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel("KNN 互動區,點一下放置查詢點")

            Picker("k", selection: $k) {
                ForEach([1, 3, 5, 7], id: \.self) { value in
                    Text("k = \(value)").tag(value)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 6) {
                Image(systemName: "hand.tap.fill")
                    .symbolEffect(.pulse)
                Text("預測:")
                Text(Self.classNames[predicted])
                    .fontWeight(.bold)
                    .foregroundStyle(Self.classColors[predicted])
                Text("(藍 \(votes[0]) 票:橘 \(votes[1]) 票)")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .font(.caption)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: k)
    }
}

#Preview {
    KNNDemo()
        .padding()
}
