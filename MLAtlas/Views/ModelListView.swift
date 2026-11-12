import SwiftUI

// 需求 2、3:NavigationStack + List(依類別分 Section)
struct ModelListView: View {
    @Environment(FavoritesStore.self) private var favorites
    @State private var searchText = ""
    @State private var favoritesOnly = false

    private func models(in category: MLCategory) -> [MLModel] {
        MLModel.models(in: category).filter { model in
            let matchesSearch = searchText.isEmpty
                || model.name.localizedCaseInsensitiveContains(searchText)
                || model.zhName.localizedCaseInsensitiveContains(searchText)
            let matchesFavorite = !favoritesOnly || favorites.contains(model)
            return matchesSearch && matchesFavorite
        }
    }

    private var isEmpty: Bool {
        MLCategory.allCases.allSatisfy { models(in: $0).isEmpty }
    }

    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty && !favoritesOnly {
                    Section {
                        // 需求 5A:TabView page 分頁輪播
                        IntroCarouselView()
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                }

                ForEach(MLCategory.allCases) { category in
                    let items = models(in: category)
                    if !items.isEmpty {
                        Section {
                            ForEach(items) { model in
                                // 需求 2:NavigationLink 把 model 傳到下一頁
                                NavigationLink(value: model) {
                                    ModelRow(model: model)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button {
                                        favorites.toggle(model)
                                    } label: {
                                        Label(favorites.contains(model) ? "取消收藏" : "收藏",
                                              systemImage: favorites.contains(model) ? "heart.slash.fill" : "heart.fill")
                                    }
                                    .tint(.pink)
                                }
                            }
                        } header: {
                            // 數字標號 + 中英對照的分類標題
                            HStack(spacing: 8) {
                                Text(category.index)
                                    .font(.system(.title3, design: .serif).weight(.light))
                                    .foregroundStyle(Color.gold)
                                Rectangle().fill(Color.gold).frame(width: 16, height: 1)
                                Text(category.zhName)
                                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                                    .foregroundStyle(category.color)
                                Text(category.enName.uppercased())
                                    .font(.caption2.weight(.semibold))
                                    .tracking(1.5)
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(category.zhName) \(category.enName)")
                        } footer: {
                            Text(category.summary)
                        }
                        .listRowBackground(Color.cardBackground)
                    }
                }

                if isEmpty {
                    ContentUnavailableView(
                        favoritesOnly ? "還沒有收藏" : "找不到模型",
                        systemImage: favoritesOnly ? "heart.slash" : "magnifyingglass",
                        description: Text(favoritesOnly ? "在模型上向左滑或進入詳情頁按愛心即可收藏。" : "試試其他關鍵字。")
                    )
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.pageBackground)
            .animation(.default, value: favoritesOnly)
            .navigationTitle("ML Atlas")
            .navigationDestination(for: MLModel.self) { model in
                ModelDetailView(model: model)
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜尋模型 Search")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        favoritesOnly.toggle()
                    } label: {
                        // 需求 8:SF Symbol 動畫
                        Image(systemName: favoritesOnly ? "heart.fill" : "heart")
                            .symbolEffect(.bounce, value: favoritesOnly)
                            .foregroundStyle(.pink)
                    }
                    .accessibilityLabel(favoritesOnly ? "顯示全部模型" : "只顯示收藏")
                }
            }
        }
    }
}

#Preview {
    ModelListView()
        .environment(FavoritesStore())
}
