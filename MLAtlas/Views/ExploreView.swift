import SwiftUI

// 需求 12、13 + 加分 2:探索頁
// 上下捲動的頁面,最上方是水平捲動的「熱門模型」,下方是模型卡片牆。
struct ExploreView: View {
    @State private var filter: MLCategory?
    @Namespace private var chipNamespace

    private static let hotIDs = ["transformer", "cnn", "random-forest", "k-means",
                                 "linear-regression", "q-learning", "gan", "svm"]
    private var hotModels: [MLModel] {
        Self.hotIDs.compactMap { id in MLModel.samples.first { $0.id == id } }
    }

    private var visibleCategories: [MLCategory] {
        filter.map { [$0] } ?? MLCategory.allCases
    }

    // 需求 12:自適應欄位的格子牆
    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 260), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                // 加分 2:LazyVStack + pinned section header(分類標題釘在上方)
                LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                    hotSection
                    filterChips
                    comparisonLink

                    ForEach(visibleCategories) { category in
                        Section {
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(MLModel.models(in: category)) { model in
                                    NavigationLink(value: model) {
                                        ModelCard(model: model)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.92).combined(with: .opacity),
                                removal: .opacity
                            ))
                        } header: {
                            categoryHeader(category)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Color.pageBackground)
            .navigationTitle("探索 Explore")
            .navigationDestination(for: MLModel.self) { model in
                ModelDetailView(model: model)
            }
        }
    }

    // MARK: 需求 13:水平捲動的熱門模型(仿 IG 限時動態)

    private var hotSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeading(index: "00", title: "熱門模型", english: "Trending")
                .padding(.horizontal)

            ScrollView(.horizontal) {
                // 加分 2:LazyHStack
                LazyHStack(alignment: .top, spacing: 14) {
                    ForEach(hotModels) { model in
                        NavigationLink(value: model) {
                            StoryCircle(model: model)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.top, 8)
    }

    // MARK: 類別篩選(matchedGeometryEffect)

    private var filterChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                chip(title: "全部 All", symbol: "square.grid.2x2.fill", category: nil)
                ForEach(MLCategory.allCases) { category in
                    chip(title: category.zhName, symbol: category.symbol, category: category)
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
    }

    private func chip(title: String, symbol: String, category: MLCategory?) -> some View {
        let isSelected = filter == category
        return Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                filter = category
            }
        } label: {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(LinearGradient.brand)
                            .matchedGeometryEffect(id: "selectedChip", in: chipNamespace)
                    } else {
                        Capsule().fill(Color(.tertiarySystemFill))
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var comparisonLink: some View {
        NavigationLink {
            ComparisonTableView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "tablecells.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("模型比較表 Comparison")
                        .font(.headline)
                    Text("一次比較 \(MLModel.samples.count) 個模型的類型、成本與用途")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    private func categoryHeader(_ category: MLCategory) -> some View {
        HStack(spacing: 8) {
            Text(category.index)
                .font(.system(.title3, design: .serif).weight(.light))
                .foregroundStyle(Color.gold)
            Rectangle().fill(Color.gold).frame(width: 16, height: 1)
            Text(category.zhName)
                .font(.system(.headline, design: .serif))
                .foregroundStyle(category.color)
            Text(category.enName.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(1.5)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(MLModel.models(in: category).count)")
                .chip(color: category.color)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// 圓形的熱門模型圖示
private struct StoryCircle: View {
    let model: MLModel

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: model.symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .background(model.category.fill.gradient, in: Circle())
                .padding(4)
                .overlay {
                    Circle().strokeBorder(
                        AngularGradient(colors: [.gold, .brandEnd, .gold.opacity(0.4), .gold], center: .center),
                        lineWidth: 2
                    )
                }
            Text(model.zhName)
                .font(.caption2)
                .lineLimit(1)
                .frame(width: 78)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(model.name),\(model.zhName)")
    }
}

#Preview {
    ExploreView()
        .environment(FavoritesStore())
}
