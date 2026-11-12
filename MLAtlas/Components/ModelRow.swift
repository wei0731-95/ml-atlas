import SwiftUI

/// 列表中的一列:SF Symbol + 中英文名 + 簡介(需求 3、11)
struct ModelRow: View {
    let model: MLModel
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: model.symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(model.category.fill.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(model.name)
                        .font(.headline)
                    if favorites.contains(model) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(.pink)
                            .transition(.scale.combined(with: .opacity))   // 需求 7
                            .accessibilityLabel("已收藏")
                    }
                }
                Text(model.zhName)
                    .font(.subheadline)
                    .foregroundStyle(model.category.color)
                Text(model.tagline)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: favorites.contains(model))
        .accessibilityElement(children: .combine)
    }
}

/// 難度星等
struct DifficultyStars: View {
    let level: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= level ? "star.fill" : "star")
            }
        }
        .font(.caption)
        .foregroundStyle(Color.gold)
        .accessibilityElement()
        .accessibilityLabel("難度 \(level) 顆星,滿分 5 顆")
    }
}

#Preview {
    List(MLModel.samples.prefix(4)) { model in
        ModelRow(model: model)
    }
    .environment(FavoritesStore())
}
