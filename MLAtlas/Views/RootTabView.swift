import SwiftUI

enum AppTab: Hashable {
    case atlas, explore, lab, about
}

// 需求 4:TabView + Tab(iOS 18+ 語法)
struct RootTabView: View {
    @State private var selection: AppTab = .atlas

    var body: some View {
        TabView(selection: $selection) {
            Tab("模型圖鑑", systemImage: "books.vertical.fill", value: AppTab.atlas) {
                ModelListView()
            }
            Tab("探索", systemImage: "safari.fill", value: AppTab.explore) {
                ExploreView()
            }
            Tab("互動實驗室", systemImage: "flask.fill", value: AppTab.lab) {
                LabView()
            }
            Tab("關於", systemImage: "info.circle.fill", value: AppTab.about) {
                AboutView()
            }
        }
        // iPhone:tab bar 在下方;iPad:tab bar 在上方,可展開成側邊欄
        .tabViewStyle(.sidebarAdaptable)
        .tint(Color("AccentColor"))
    }
}

#Preview {
    RootTabView()
        .environment(FavoritesStore())
}
