import SwiftUI

// 關於頁:外觀切換(需求 10)、VideoPlayer(需求 14)、AsyncImage(加分 6)、收藏清單
struct AboutView: View {
    @AppStorage("appearanceMode") private var appearance: AppearanceMode = .system
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        NavigationStack {
            List {
                Section {
                    header
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }

                Section {
                    Picker("外觀", selection: $appearance) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Label("外觀 Appearance", systemImage: appearance.symbol)
                } footer: {
                    Text("選擇「系統」會跟隨裝置的淺色 / 深色設定。")
                }

                Section {
                    VideoSectionView()
                } header: {
                    Label("示範影片 Video", systemImage: "play.rectangle.fill")
                }

                Section {
                    RemoteGalleryView()
                        .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                } header: {
                    Label("延伸圖庫 Gallery", systemImage: "photo.on.rectangle.angled")
                } footer: {
                    Text("圖片來自 Wikimedia Commons,以 AsyncImage 從網路載入。")
                }

                Section {
                    if favorites.models.isEmpty {
                        Label("還沒有收藏任何模型", systemImage: "heart.slash")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(favorites.models) { model in
                            NavigationLink(value: model) {
                                ModelRow(model: model)
                            }
                        }
                    }
                } header: {
                    Label("我的收藏 Favorites(\(favorites.models.count))", systemImage: "heart.fill")
                }

                Section {
                    LabeledContent("版本", value: "1.0")
                    LabeledContent("收錄模型", value: "\(MLModel.samples.count) 個")
                    LabeledContent("課程作業", value: "#88 SwiftUI 電子書 App")
                    Link(destination: URL(string: "https://en.wikipedia.org/wiki/Machine_learning")!) {
                        Label("Wikipedia:Machine learning", systemImage: "globe")
                    }
                    Link(destination: URL(string: "https://scikit-learn.org/stable/user_guide.html")!) {
                        Label("scikit-learn User Guide", systemImage: "book.fill")
                    }
                } header: {
                    Label("資訊 Info", systemImage: "info.circle")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.pageBackground)
            .navigationTitle("關於 About")
            .navigationDestination(for: MLModel.self) { model in
                ModelDetailView(model: model)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image("LaunchLogo")
                .resizable()
                .frame(width: 92, height: 92)
                .softShadow()
                .accessibilityHidden(true)

            // 加分 4:組合不同粗細、顏色、底線的文字
            Text("\(Text("ML").fontWeight(.bold).foregroundStyle(Color.accentColor)) \(Text("/").fontWeight(.ultraLight).foregroundStyle(Color.gold)) \(Text("ATLAS").fontWeight(.regular).foregroundStyle(Color.gold))")
                .font(.system(.largeTitle, design: .serif))
                .tracking(3)

            Text("""
            一本可以\(Text("動手玩").bold().foregroundStyle(.orange))的\
            \(Text("機器學習模型圖鑑").fontWeight(.semibold).underline())\
            ,用\(Text("動畫").italic().foregroundStyle(.purple))理解每個模型。
            """)
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    AboutView()
        .environment(FavoritesStore())
}
