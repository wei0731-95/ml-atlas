import SwiftUI

// 需求 12:用 Grid 製作「模型比較表」
struct ComparisonTableView: View {
    var body: some View {
        ScrollView(.vertical) {
            ScrollView(.horizontal) {
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                    GridRow {
                        Text("模型")
                        Text("類型")
                        Text("需標註資料")
                        Text("可解釋性")
                        Text("訓練成本")
                        Text("典型用途")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                    Divider().gridCellUnsizedAxes(.horizontal)

                    ForEach(MLModel.samples) { model in
                        GridRow {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(model.name).font(.subheadline.weight(.semibold))
                                Text(model.zhName).font(.caption).foregroundStyle(.secondary)
                            }
                            Text(model.category.zhName)
                                .chip(color: model.category.color)
                            Label(model.labelNeed.label, systemImage: model.labelNeed.symbol)
                                .font(.caption)
                            LevelBars(level: model.interpretability, highIsGood: true)
                            LevelBars(level: model.trainingCost, highIsGood: false)
                            Text(model.typicalUse)
                                .font(.caption)
                        }
                        .accessibilityElement(children: .combine)

                        Divider().gridCellUnsizedAxes(.horizontal)
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding()
        }
        .background(Color.pageBackground)
        .navigationTitle("模型比較表")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 三格的等級指示
private struct LevelBars: View {
    let level: Level
    let highIsGood: Bool

    private var color: Color {
        switch (level, highIsGood) {
        case (.medium, _): .orange
        case (.high, true), (.low, false): .green
        default: .red
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 2) {
                ForEach(1...3, id: \.self) { index in
                    Capsule()
                        .fill(index <= level.rawValue ? color : Color(.tertiarySystemFill))
                        .frame(width: 10, height: 6)
                }
            }
            Text(level.label).font(.caption)
        }
        .accessibilityElement()
        .accessibilityLabel(level.label)
    }
}

#Preview {
    NavigationStack {
        ComparisonTableView()
    }
}
