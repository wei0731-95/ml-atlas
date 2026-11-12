import SwiftUI

// 需求 6:Decision Tree —— 節點逐層分裂展開
struct DecisionTreeDemo: View {
    let tint: Color

    private struct Node: Identifiable {
        let id: Int
        let level: Int
        let x: CGFloat          // 0...1
        let label: String
        let parent: Int?
        var isLeaf = false
        var isPositive = false
    }

    // 經典的「要不要出門打球」例子
    private static let nodes: [Node] = [
        Node(id: 0, level: 0, x: 0.5, label: "天氣晴朗?", parent: nil),
        Node(id: 1, level: 1, x: 0.27, label: "風很大?", parent: 0),
        Node(id: 2, level: 1, x: 0.73, label: "濕度高?", parent: 0),
        Node(id: 3, level: 2, x: 0.13, label: "不出門", parent: 1, isLeaf: true),
        Node(id: 4, level: 2, x: 0.38, label: "出門", parent: 1, isLeaf: true, isPositive: true),
        Node(id: 5, level: 2, x: 0.62, label: "不出門", parent: 2, isLeaf: true),
        Node(id: 6, level: 2, x: 0.87, label: "出門", parent: 2, isLeaf: true, isPositive: true),
    ]

    @State private var visibleLevel = -1
    @State private var runID = 0

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { geometry in
                let size = geometry.size
                ZStack {
                    // 連線:用 trim 做出「長出來」的效果
                    ForEach(Self.nodes.filter { $0.parent != nil }) { node in
                        Path { path in
                            path.move(to: point(Self.nodes[node.parent!], in: size))
                            path.addLine(to: point(node, in: size))
                        }
                        .trim(from: 0, to: node.level <= visibleLevel ? 1 : 0)
                        .stroke(Color.secondary.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    }

                    ForEach(Self.nodes) { node in
                        Text(node.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(color(for: node), in: Capsule())
                            .scaleEffect(node.level <= visibleLevel ? 1 : 0.01)
                            .opacity(node.level <= visibleLevel ? 1 : 0)
                            .position(point(node, in: size))
                    }
                }
            }
            .frame(height: 220)

            HStack {
                Text(visibleLevel < 2 ? "分裂中:第 \(max(visibleLevel, 0) + 1) 層" : "分裂完成:葉節點給出預測")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("重播", systemImage: "arrow.clockwise") {
                    runID += 1
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }
        }
        .task(id: runID) {
            visibleLevel = -1
            for level in 0...2 {
                try? await Task.sleep(for: .seconds(0.7))
                if Task.isCancelled { return }
                withAnimation(.spring(response: 0.55, dampingFraction: 0.6)) {
                    visibleLevel = level
                }
            }
        }
    }

    private func point(_ node: Node, in size: CGSize) -> CGPoint {
        CGPoint(x: node.x * size.width, y: (0.12 + 0.38 * CGFloat(node.level)) * size.height)
    }

    private func color(for node: Node) -> Color {
        guard node.isLeaf else { return tint }
        return node.isPositive ? .green : .gray
    }
}

#Preview {
    DecisionTreeDemo(tint: .blue)
        .padding()
}
