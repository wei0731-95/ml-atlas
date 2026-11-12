import SwiftUI

/// 需求 12:卡片牆中的一張模型卡片
struct ModelCard: View {
    let model: MLModel
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            artwork

            Text(model.name)
                .font(.system(.subheadline, design: .serif).weight(.bold))
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)
            Text(model.zhName)
                .font(.caption)
                .foregroundStyle(.secondary)
            DifficultyStars(level: model.difficulty)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(cornerRadius: 16, padding: 10)
        .accessibilityElement(children: .combine)
    }

    /// 以 SwiftUI 繪製的卡片圖像,套用 blur / blendMode / saturation 等效果(加分 3)
    private var artwork: some View {
        ZStack {
            Rectangle().fill(model.category.fill.gradient)

            Circle()
                .fill(.white.opacity(0.5))
                .frame(width: 90, height: 90)
                .blur(radius: 18)
                .blendMode(.overlay)
                .offset(x: -40, y: -26)
            Circle()
                .fill(Color.gold)
                .frame(width: 80, height: 80)
                .blur(radius: 22)
                .blendMode(.plusLighter)
                .offset(x: 50, y: 34)

            Image(systemName: model.symbol)
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
        .frame(height: 92)
        .saturation(1.15)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(alignment: .topTrailing) {
            if favorites.contains(model) {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(.pink)
                    .padding(6)
                    .background(.thinMaterial, in: Circle())
                    .padding(6)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    ModelCard(model: MLModel.samples[10])
        .frame(width: 170)
        .padding()
        .environment(FavoritesStore())
}
