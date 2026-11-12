# ML Atlas|機器學習模型圖鑑

課程作業「#88 使用 SwiftUI 製作結合酷炫動畫效果的電子書 App」。
用電子書的形式介紹 16 個機器學習模型:中英雙語說明、每個模型一段專屬動畫、可互動的實驗室,支援 iPhone / iPad 與 Light / Dark mode。

| iPhone 圖鑑頁 | iPhone 詳情頁(深色) | iPad(tab bar 在上方) |
| --- | --- | --- |
| <img src="docs/screenshots/iphone-list.png" width="220"> | <img src="docs/screenshots/iphone-detail-dark.png" width="220"> | <img src="docs/screenshots/ipad-explore.png" width="330"> |

## 視覺風格

參考清華科管所網站案例的設計語言:深紫主色、淡米色底、金色細線與 01 / 02 數字標號、襯線大寫標題、中英對照;只借用風格,未使用該網站的 Logo、圖片與內容。iOS 特色保留:原生導覽與 tab bar、圓角卡片、SF Symbols、系統襯線字體 New York、Dynamic Type。色票集中在 `Assets.xcassets` 與 `Modifiers/CardStyle.swift`。

## 環境需求

- Xcode 26 以上(本專案以 **Xcode 27.2 / iOS 27 模擬器**編譯與實測),Swift 6 語言模式
- 最低支援 **iOS 26**,Universal(iPhone + iPad)
- 沒有任何第三方套件;圖像全部用 SF Symbols 與 SwiftUI(Shape、Canvas)繪製

## 如何執行

1. 用 Xcode 開啟 `MLAtlas.xcodeproj`。
2. 選擇 `MLAtlas` scheme 與任一 iPhone 或 iPad 模擬器,按 ⌘R。
3. 要在實機執行時,到 Target → Signing & Capabilities 選擇自己的 Team,並把 Bundle Identifier(預設 `com.example.MLAtlas`)改成自己的。

命令列編譯(兩個平台皆已通過,0 error / 0 warning):

```bash
xcodebuild -project MLAtlas.xcodeproj -scheme MLAtlas -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

```bash
xcodebuild -project MLAtlas.xcodeproj -scheme MLAtlas -destination 'platform=iOS Simulator,name=iPad Air 11-inch (M4)' build
```

專案檔由 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 依 `project.yml` 產生。新增或搬移檔案後執行 `xcodegen generate` 即可更新;沒有安裝 XcodeGen 也能直接使用現有的 `.xcodeproj`。

## 專案結構

```
MLAtlas.xcodeproj          Xcode 專案
project.yml                XcodeGen 設定(含 Info.plist 內容)
MLAtlas/
  MLAtlasApp.swift         App 進入點
  Info.plist               Display Name、UILaunchScreen
  Models/                  MLModel、16 筆資料、收藏、外觀設定
  Views/                   每個畫面一個檔案
  Components/              列、卡片、FlowLayout
  Components/Demos/        16 個模型的示意動畫
  Modifiers/               自訂 ViewModifier
  Resources/               Assets.xcassets、intro.mp4
Scripts/
  generate_assets.swift    產生 App Icon 與 Launch 圖
  generate_video.swift     用 AVFoundation 產生 intro.mp4
landing-page/index.html    App 的 landing page(單一檔案)
docs/screenshots/          模擬器截圖
```

## 需求對照表

### 必做功能

| # | 需求 | 對應檔案 | 行為 |
| --- | --- | --- | --- |
| 資料 | `struct` + `Identifiable`、enum 類別、array | `Models/MLModel.swift`、`Models/MLModel+Samples.swift` | `MLModel`、`MLCategory`,`static let samples` 共 16 個模型 |
| 1 | 多頁面,每個畫面一個檔案 | `Views/*.swift` | 圖鑑、詳情、探索、比較表、實驗室、動畫總覽、關於、網頁閱讀 |
| 2 | NavigationStack + NavigationLink | `Views/ModelListView.swift`、`Views/ModelDetailView.swift` | `NavigationLink(value:)` 把 `MLModel` 傳到詳情頁,`navigationTitle` 顯示標題 |
| 3 | List + Identifiable | `Views/ModelListView.swift`、`Components/ModelRow.swift` | 依類別分 Section,每列有 SF Symbol、中英文名、簡介;可搜尋、左滑收藏 |
| 4 | TabView + Tab | `Views/RootTabView.swift` | 4 個 `Tab`;`.tabViewStyle(.sidebarAdaptable)`,iPhone 在下方、iPad 在上方並可展開側邊欄 |
| 5A | 水平分頁:TabView page | `Views/IntroCarouselView.swift` | 圖鑑頁最上方的「ML 簡介」輪播 |
| 5B | 水平分頁:ScrollView paging | `Views/DetailPagerView.swift` | 詳情頁「概念 → 原理 → 應用」,`scrollTargetBehavior(.paging)` + `scrollTargetLayout()` |
| 6 | SwiftUI 動畫 | `Components/Demos/*` | 見下方「動畫清單」;另有 `matchedGeometryEffect`(`DetailPagerView`、`ExploreView` 的選取底色) |
| 7 | transition | `Views/ModelDetailView.swift`、`Views/LabView.swift`、`Views/ExploreView.swift` | 優缺點展開用 `asymmetric`(move + opacity / scale + opacity);實驗室可切換 5 種 transition |
| 8 | SF Symbol 動畫 | `Views/LabView.swift`、`Views/ModelDetailView.swift`、`Views/WebReaderView.swift` | 收藏愛心 `bounce`、載入中 `variableColor`、實驗室展示 bounce / wiggle / pulse / variableColor / rotate / breathe |
| 9 | WebView | `Views/WebReaderView.swift` | iOS 26 原生 `WebView` + `WebPage`,以 sheet 顯示 Wikipedia / scikit-learn;有進度條、載入中畫面與錯誤重試 |
| 10 | Dark / Light mode | `Models/AppearanceMode.swift`、`Views/AboutView.swift`、`Resources/Assets.xcassets` | 全面使用語意顏色與 Color Set;關於頁可切換 系統 / 淺色 / 深色(`@AppStorage`) |
| 11 | SF Symbol | 全專案 | 列表、tab、按鈕、卡片皆使用 |
| 12 | 格子牆 + 比較表 | `Views/ExploreView.swift`、`Components/ModelCard.swift`、`Views/ComparisonTableView.swift` | `LazyVGrid` + `GridItem(.adaptive)` 卡片牆;`Grid` 比較表(類型、需標註資料、可解釋性、訓練成本、典型用途) |
| 13 | 垂直捲動中有水平捲動 | `Views/ExploreView.swift` | 最上方水平捲動的「熱門模型」圓形圖示,下方垂直內容 |
| 14 | VideoPlayer | `Views/VideoSectionView.swift`、`Scripts/generate_video.swift` | 預設播放 Bundle 內的 `intro.mp4`,可切換成網路 HLS 影片;兩者都有錯誤處理 |
| 15 | App Icon 與名稱 | `Resources/Assets.xcassets/AppIcon.appiconset`、`Info.plist` | Display Name「ML Atlas」;1024×1024 圖示含 Light / Dark / Tinted |
| 16 | Launch Screen | `Info.plist`(`UILaunchScreen`) | `UIColorName = LaunchBackground`(Color Set)+ `UIImageName = LaunchLogo` |

### 加分功能

| # | 需求 | 對應檔案 | 行為 |
| --- | --- | --- | --- |
| 1 | Landing page | `landing-page/index.html` | 單檔、無外部資源;hero、功能亮點、CSS 手機 mock-up、下載按鈕(placeholder)、深色模式、RWD |
| 2 | LazyVStack / LazyHStack + pinned | `Views/ExploreView.swift`、`Views/ModelDetailView.swift` | 探索頁分類標題 `pinnedViews: [.sectionHeaders]`;詳情頁底部操作列 `[.sectionFooters]`;熱門列用 `LazyHStack` |
| 3 | 圖片效果 modifier | `Views/LabView.swift`、`Components/ModelCard.swift` | 實驗室用 Slider / Toggle 調整 blur、brightness、contrast、saturation、grayscale、hueRotation、colorInvert、colorMultiply、mask、blendMode |
| 4 | 多種文字樣式組合 | `Views/ModelDetailView.swift`(`highlight`)、`Views/AboutView.swift` | 不同粗細、顏色、斜體、底線組成一段文字(見「已知限制」第 2 點) |
| 5 | 自訂 ViewModifier | `Modifiers/CardStyle.swift` | `CardStyle`、`SoftShadow`、`SectionTitleStyle`、`ChipStyle` 與對應的 `View` extension |
| 6 | AsyncImage | `Views/RemoteGalleryView.swift` | Wikimedia Commons 圖片;處理 placeholder、失敗畫面(最後一張刻意放不存在的網址)與 transition |

### 動畫清單(需求 6)

| 模型 | 動畫 | 技術 |
| --- | --- | --- |
| Linear Regression | 梯度下降 60 步,回歸線與殘差逐步擬合 | 自訂 `Shape` + `animatableData`、`withAnimation(.spring)` |
| K-Means | 點被指派到最近中心、中心移到平均位置,直到收斂 | `withAnimation`、spring |
| Decision Tree | 節點逐層分裂,連線長出來 | `trim`、`scaleEffect`、spring |
| KNN | 點一下放置查詢點,高亮最近 k 個鄰居並投票 | `SpatialTapGesture`、`.transition`、`.animation` |
| MLP / DQN | 訊號沿連線逐層傳遞,神經元發亮 | `TimelineView` + `Canvas` |
| Logistic Regression、Random Forest、SVM、DBSCAN、PCA、CNN、RNN/LSTM、Transformer、GAN、Q-Learning | 各自的概念示意 | `TimelineView` + `Canvas` |

在「互動實驗室 → 動畫總覽」可以一次看完 16 個動畫。

## 如何驗證 iPhone 與 iPad 的 TabView

- **iPhone**:執行後 tab bar 浮在畫面下方(見上方第一張截圖)。進入模型詳情頁時會收起 tab bar,把空間留給底部操作列。
- **iPad**:改選 iPad 模擬器執行,tab bar 顯示在畫面上方(見第三張截圖);點左邊的側邊欄圖示可展開成側邊欄。旋轉裝置(⌘←/→)可確認橫直向。

## 重新產生素材

```bash
swift Scripts/generate_assets.swift .
```

```bash
swift Scripts/generate_video.swift MLAtlas/Resources/intro.mp4
```

想換成自己的影片:用同名的 `intro.mp4` 取代 `MLAtlas/Resources/intro.mp4`;網路影片則修改 `VideoSectionView.networkURL`(需為 mp4 或 HLS)。

## 已知限制

1. 開發機安裝的是 Xcode 27.2,因此是以 iOS 27 SDK 編譯、部署目標設為 iOS 26;沒有在 Xcode 26 上實際編譯過。
2. `Text + Text` 在 iOS 26 SDK 已被標為 deprecated(訊息建議改用字串插值)。為了維持零警告,文字樣式組合改用 `Text("\(Text(...).bold())…")` 的插值寫法,效果相同。
3. WebView、AsyncImage 與「網路影片」需要網路連線;離線時會顯示對應的錯誤畫面。
4. 模型數量依需求確認時的決定精選為 16 個(Gradient Boosting、Hierarchical Clustering、Autoencoder、Diffusion、PPO 未收錄)。
5. 實測在 iPhone 17 Pro 與 iPad Air 11 吋模擬器上進行;iPad 只實際檢查了探索頁的版面與上方 tab bar,其餘頁面與橫向版面未逐頁截圖確認。實機未測試。
6. 示意動畫是概念說明,資料為固定種子產生的示範資料(Transformer 的注意力權重、GAN 的判別器準確率為示意數值,不是實際訓練結果)。
7. 動畫目前沒有依「減少動態效果」的輔助使用設定調整。

## 操作影片錄製腳本

建議用 iPhone 模擬器錄主要流程(約 2–3 分鐘),最後補一段 iPad。模擬器錄影:File → Record Screen,或 `xcrun simctl io booted recordVideo demo.mov`。

1. **啟動**:從主畫面點 App Icon(展示圖示與名稱「ML Atlas」),停一下讓 Launch Screen 出現。
2. **圖鑑頁**:左右滑動最上方的簡介輪播(TabView page);上下捲動列表看四個分類;在搜尋列輸入「tree」;在某一列向左滑收藏。
3. **進入詳情頁**(點 K-Means):看標題圖示彈跳進場 → K-Means 動畫跑到收斂,按「重播」。
4. **詳情頁下半部**:左右滑動「概念 / 原理 / 應用」(ScrollView paging),再點上方標籤看底色滑動;展開、收合「優點 / 缺點」(transition);注意底部操作列固定不動(pinned footer)。
5. **收藏與網頁**:點底部「收藏」看愛心彈跳;點「延伸閱讀 → Wikipedia」開啟 WebView sheet,等載入完成後關閉。
6. **互動動畫**:返回後進入 KNN,在畫面上點幾個不同位置、切換 k 值;再進 Linear Regression 按「重新擬合」;進 Decision Tree 看分裂。
7. **探索頁**:左右滑動「熱門模型」(垂直頁面中的水平捲動);點類別篩選看選取底色移動;往下捲看分類標題釘在上方(pinned header)與卡片牆;點「模型比較表」左右捲動 Grid。
8. **互動實驗室**:進「動畫總覽」快速捲過 16 個動畫;回來拉動 blur、hueRotation、saturation 等 Slider,打開 colorInvert、mask,切換 blendMode;在 Transition 區切換種類並按按鈕;在 SF Symbol 區按「觸發 bounce / wiggle」。
9. **關於頁**:切換外觀 系統 → 深色 → 淺色;播放內建影片,再切到「網路影片」;左右滑動 AsyncImage 圖庫(最後一張是失敗畫面);看「我的收藏」。
10. **重開 App**:關掉再打開,確認收藏與外觀設定仍保留。
11. **iPad**:改用 iPad 模擬器,展示 tab bar 在上方、點側邊欄圖示展開、旋轉成橫向、探索頁卡片牆欄數變多。
12. **Landing page**:用瀏覽器開啟 `landing-page/index.html`,捲動頁面、按右上角切換深色模式、縮小視窗看 RWD。
