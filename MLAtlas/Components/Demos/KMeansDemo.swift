import SwiftUI

// 需求 6:K-Means —— 資料點被分到最近的中心點,中心點再移動到群內平均
struct KMeansDemo: View {
    private static let aspect: CGFloat = 1.5
    private static let clusterColors: [Color] = [.pink, .indigo, .teal]

    private static let points: [CGPoint] = {
        var rng = SeededGenerator(seed: 7)
        let centers = [CGPoint(x: 0.25, y: 0.3), CGPoint(x: 0.74, y: 0.28), CGPoint(x: 0.5, y: 0.76)]
        var result: [CGPoint] = []
        for center in centers {
            for _ in 0..<14 {
                result.append(CGPoint(x: center.x + CGFloat.random(in: -0.13...0.13, using: &rng),
                                      y: center.y + CGFloat.random(in: -0.16...0.16, using: &rng)))
            }
        }
        return result
    }()

    private static let initialCentroids = [CGPoint(x: 0.15, y: 0.62), CGPoint(x: 0.6, y: 0.1), CGPoint(x: 0.86, y: 0.62)]

    @State private var centroids = initialCentroids
    @State private var assignments: [Int?] = Array(repeating: nil, count: points.count)
    @State private var iteration = 0
    @State private var status = "準備開始"
    @State private var runID = 0

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { geometry in
                let size = geometry.size
                ZStack {
                    ForEach(Self.points.indices, id: \.self) { index in
                        Circle()
                            .fill(color(for: assignments[index]))
                            .frame(width: 9, height: 9)
                            .position(x: Self.points[index].x * size.width, y: Self.points[index].y * size.height)
                    }
                    ForEach(centroids.indices, id: \.self) { index in
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Self.clusterColors[index])
                            .shadow(radius: 3)
                            .position(x: centroids[index].x * size.width, y: centroids[index].y * size.height)
                    }
                }
            }
            .aspectRatio(Self.aspect, contentMode: .fit)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("第 \(iteration) 輪")
                        .font(.caption.monospacedDigit().weight(.semibold))
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("重播", systemImage: "arrow.clockwise") {
                    runID += 1
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }
        }
        .task(id: runID) {
            await run()
        }
    }

    private func color(for cluster: Int?) -> Color {
        cluster.map { Self.clusterColors[$0] } ?? Color.secondary
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot((a.x - b.x) * Self.aspect, a.y - b.y)
    }

    private func run() async {
        centroids = Self.initialCentroids
        assignments = Array(repeating: nil, count: Self.points.count)
        iteration = 0
        status = "準備開始"

        for round in 1...8 {
            try? await Task.sleep(for: .seconds(0.9))
            if Task.isCancelled { return }

            // 步驟 1:指派 —— 每個點分給最近的中心
            let newAssignments: [Int?] = Self.points.map { point in
                centroids.indices.min { distance(point, centroids[$0]) < distance(point, centroids[$1]) }
            }
            if newAssignments == assignments {
                status = "指派不再改變,已收斂 ✓"
                return
            }
            iteration = round
            status = "步驟 1:把每個點指派給最近的中心"
            withAnimation(.easeInOut(duration: 0.5)) {
                assignments = newAssignments
            }

            try? await Task.sleep(for: .seconds(0.9))
            if Task.isCancelled { return }

            // 步驟 2:更新 —— 中心移到群內所有點的平均位置
            var updated = centroids
            for cluster in centroids.indices {
                let members = Self.points.indices.filter { newAssignments[$0] == cluster }.map { Self.points[$0] }
                guard !members.isEmpty else { continue }
                updated[cluster] = CGPoint(x: members.map(\.x).reduce(0, +) / CGFloat(members.count),
                                           y: members.map(\.y).reduce(0, +) / CGFloat(members.count))
            }
            status = "步驟 2:中心移到群內的平均位置"
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                centroids = updated
            }
        }
    }
}

#Preview {
    KMeansDemo()
        .padding()
}
