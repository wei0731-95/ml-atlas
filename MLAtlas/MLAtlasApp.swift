import SwiftUI

@main
struct MLAtlasApp: App {
    // 收藏狀態(@Observable)由根節點建立,透過 environment 往下傳
    @State private var favorites = FavoritesStore()
    // 需求 10:外觀設定存在 @AppStorage
    @AppStorage("appearanceMode") private var appearance: AppearanceMode = .system

    init() {
        // 大標題改用系統襯線字體(New York),呼應模板典雅的標題風格
        let base = UIFont.preferredFont(forTextStyle: .largeTitle)
        if let descriptor = base.fontDescriptor.withDesign(.serif)?.withSymbolicTraits(.traitBold) {
            UINavigationBar.appearance().largeTitleTextAttributes = [.font: UIFont(descriptor: descriptor, size: 0)]
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(favorites)
                .preferredColorScheme(appearance.colorScheme)
        }
    }
}
