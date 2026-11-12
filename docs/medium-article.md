# #04 電子書 App — 用動畫讀懂機器學習:ML Atlas 模型圖鑑

> 副標:用 SwiftUI 做一本能動手玩的電子書,16 個模型、16 段專屬動畫,從 TabView 到 iOS 26 原生 WebView

機器學習的教科書常常是一頁頁公式與靜態圖。「梯度下降一步步逼近」「K-Means 的中心點一直在動」這類過程,用文字很難說清楚,但只要看一次動畫就懂了。所以這次的電子書作業,我沒有選旅遊或食譜,而是做了一本 **機器學習模型圖鑑**:**ML Atlas**。

這個 App 收錄 16 個經典模型(線性迴歸、決策樹、SVM、K-Means、CNN、Transformer、Q-Learning…),每個模型有中英對照說明,以及一段專屬的互動動畫。這篇文章記錄我用到的 SwiftUI 技術、動畫的做法,以及實際踩到的坑。

操作展示影片:`【貼上你的影片連結】`
GitHub 原始碼:`【貼上你的 GitHub 連結】`

---

## 一、先看成品

- 圖鑑頁:簡介輪播 + 依類別分組的模型列表(可搜尋、左滑收藏)
- 探索頁:水平捲動的熱門模型、類別篩選、卡片牆、比較表
- 詳情頁:專屬動畫、概念 / 原理 / 應用三頁橫滑、優缺點、底部操作列
- 互動實驗室:圖片效果、轉場、SF Symbol 動畫的互動展示
- 關於頁:外觀切換、影片、網路圖庫、收藏清單

支援 iPhone 與 iPad、淺色與深色模式,最低 iOS 26。

---

## 二、資料驅動設計

跟大多數電子書 App 一樣,內容與畫面要分開。每個模型是一個 `struct`,遵從 `Identifiable`,放進一個靜態陣列:

```swift
struct MLModel: Identifiable, Hashable, Sendable {
    let id: String              // 固定代號,用來儲存收藏
    let name: String            // 英文名
    let zhName: String          // 中文名
    let category: MLCategory    // enum:監督式 / 非監督式 / 深度 / 強化
    let symbol: String          // SF Symbol
    let concept: String         // 概念
    let mechanism: String       // 原理
    let pros: [String]
    let cons: [String]
    let demo: DemoKind          // 決定詳情頁顯示哪一段動畫
    // …
    static let samples: [MLModel] = [ /* 16 筆 */ ]
}
```

幾個我覺得值得的設計:

- **`id` 用固定字串而不是 `UUID()`**:收藏要存進 `UserDefaults`,重開 App 後得認得出是哪個模型,每次啟動都產生新 UUID 就對不起來了。
- **`DemoKind` 是 enum**:詳情頁用 `switch` 決定要顯示哪一段動畫,新增模型時編譯器會提醒你漏掉哪個 case。
- **收藏用 `@Observable`**:`FavoritesStore` 在 App 根節點建立,透過 `environment` 往下傳,所有頁面都能即時反映收藏狀態。

---

## 三、多頁面與 TabView

每個畫面一個檔案(`ModelListView`、`ExploreView`、`LabView`、`AboutView`…),根節點用 iOS 18 之後的 `Tab` 語法:

```swift
TabView(selection: $selection) {
    Tab("模型圖鑑", systemImage: "books.vertical.fill", value: AppTab.atlas) { ModelListView() }
    Tab("探索", systemImage: "safari.fill", value: AppTab.explore) { ExploreView() }
    Tab("互動實驗室", systemImage: "flask.fill", value: AppTab.lab) { LabView() }
    Tab("關於", systemImage: "info.circle.fill", value: AppTab.about) { AboutView() }
}
.tabViewStyle(.sidebarAdaptable)
```

只加一行 `.sidebarAdaptable`,iPhone 的 tab bar 就在下方,到了 iPad 則會移到上方,並出現可以展開成側邊欄的按鈕。同一份程式碼兩種平台各有原生的樣子,這是我很喜歡 SwiftUI 的地方。

進入詳情頁時,我在 iPhone 上把 tab bar 收起來,把空間讓給底部操作列:

```swift
.toolbarVisibility(horizontalSizeClass == .compact ? .hidden : .automatic, for: .tabBar)
```

---

## 四、NavigationStack 與 List

列表用 `NavigationLink(value:)` 搭配 `navigationDestination(for:)`,把整個 `MLModel` 傳到下一頁,`navigationTitle` 顯示標題。`List` 依類別分 Section,每一列有 SF Symbol、中英文名與一句話簡介。

另外加了兩個小功能:`searchable` 搜尋,以及 `swipeActions` 左滑收藏。

---

## 五、兩種水平滑動分頁

作業要求兩種做法,我各用在不同地方。

**版本 A:`TabView` + `.page`**,用在圖鑑頁最上方的「機器學習簡介」輪播,最簡單,一行就有分頁小圓點。

**版本 B:`ScrollView` + `.paging`**,用在詳情頁的「概念 → 原理 → 應用」。這個版本自由度高很多,可以跟上方的自訂標籤同步:

```swift
ScrollView(.horizontal) {
    HStack(alignment: .top, spacing: 0) {
        ForEach(Page.allCases) { page in
            pageContent(page)
                .containerRelativeFrame(.horizontal)
                .id(page)
        }
    }
    .scrollTargetLayout()
}
.scrollTargetBehavior(.paging)
.scrollPosition(id: $current)
```

上方的三個標籤用 `matchedGeometryEffect` 讓選取的底色在標籤之間滑動,點標籤時 `withAnimation` 改變 `current`,下方內容就會跟著捲過去;反過來手動滑動時標籤也會跟著變。

---

## 六、16 段專屬動畫(這次的重頭戲)

動畫分成兩類。

### 1. 互動式動畫:用 `withAnimation` 驅動狀態

**線性迴歸**:資料點固定,每 70ms 做一次梯度下降,更新斜率與截距。重點是自訂 `Shape` 並實作 `animatableData`,這樣直線才會平順地轉動,而不是一格一格跳:

```swift
private struct RegressionLine: Shape {
    var slope: Double
    var intercept: Double

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(slope, intercept) }
        set { slope = newValue.first; intercept = newValue.second }
    }
    // path(in:) 依 slope、intercept 畫出直線
}
```

**K-Means**:兩個步驟輪流進行。先把每個點「指派」給最近的中心(點的顏色漸變),再把中心「移動」到群內平均位置(用 spring 彈過去),直到指派不再改變就顯示「已收斂」。

**決策樹**:節點逐層用 spring 彈出,連線用 `trim(from:to:)` 做出「長出來」的效果。

**KNN**:`SpatialTapGesture` 取得點擊位置當作查詢點,即時算出最近的 k 個鄰居並高亮、投票。這個是唯一可以讓使用者直接動手的動畫,也是我最喜歡的一個。

### 2. 時間驅動動畫:`TimelineView` + `Canvas`

其餘 12 個模型(神經網路、CNN、RNN、Transformer、GAN、SVM、DBSCAN、PCA、Q-Learning…)用 `Canvas` 直接畫。核心是同一個小元件:

```swift
struct TimelineCanvas: View {
    let draw: (GraphicsContext, CGSize, Double) -> Void

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                draw(context, size, timeline.date.timeIntervalSinceReferenceDate)
            }
        }
    }
}
```

每一幀都把「現在的時間」傳進去,動畫就是時間的函數。例如神經網路的訊號傳遞,只要算出 `progress = 循環進度 × 層數`,目前在哪一層、訊號在連線上走到幾成就都知道了。MLP 與 DQN 共用同一個 `network` 函式,只是層數與標籤不同。

用時間函數寫動畫有個好處:**不用管狀態**,不需要 `@State`、不用處理動畫何時開始或重來,畫面離開再回來也永遠是對的。缺點是每個動畫都要自己算座標,比 `withAnimation` 費工。

### 一次看完

我另外在互動實驗室做了「動畫總覽」頁,用 `LazyVGrid` 把 16 段動畫排在一起,方便錄 demo 與檢查。

> 提醒:這些動畫用的是固定種子的示範資料(GAN 的判別器準確率、Transformer 的注意力權重都是示意數值),目的是說明概念,不是真的訓練結果。我也在 App 與 README 裡註明了。

---

## 七、iOS 26 的新 API

### 原生 WebView

參考文章當年要用 `UIViewRepresentable` 包 `WKWebView`。到了 iOS 26,SwiftUI 直接有 `WebView` 與 `WebPage`:

```swift
@State private var page = WebPage()

WebView(page)
    .task {
        do {
            for try await _ in page.load(URLRequest(url: url)) {}
        } catch {
            loadError = error.localizedDescription
        }
    }
```

`page.isLoading`、`page.estimatedProgress`、`page.title` 都是可觀察的屬性,載入進度條與標題幾乎不用額外程式碼。我在詳情頁按「延伸閱讀」用 sheet 顯示 Wikipedia 或 scikit-learn 文件,並處理了載入中與失敗重試的畫面。

### `Text + Text` 被標為 deprecated

作業要求組合不同粗細、顏色、底線的文字。以前會寫 `Text("A").bold() + Text("B").underline()`,但在 iOS 26 SDK 裡這個運算子已被標為 deprecated,建議改用字串插值:

```swift
Text("\(Text(model.name).bold().foregroundStyle(tint)) 屬於\(Text(model.category.zhName).underline())")
```

效果相同,而且零警告。

### 其他

- `symbolEffect`:收藏愛心 `bounce`、載入中 `variableColor`,實驗室展示 pulse、rotate、wiggle、breathe
- `Grid`:模型比較表
- `LazyVStack(pinnedViews:)`:探索頁的類別標題釘在上方,詳情頁底部操作列用 `.sectionFooters` 釘在下方

---

## 八、換風格:借用設計語彙,保留 iOS 質感

完成功能後,我參考了一個大學研究所官網的設計案例,把 App 與 landing page 的視覺換成:**深紫主色、淡米色背景、金色細線、01 / 02 數字標號、襯線大寫標題**。

重點是「借語彙、不照抄」。我只採用配色與排版概念,沒有使用對方的 Logo、圖片與內容,並且保留 iOS 的原生特色:

- 導覽列、tab bar、sheet 維持系統原生樣式
- 標題用系統襯線字體 New York(`.system(.title, design: .serif)`),不用自訂字型
- 顏色全部放進 Asset Catalog 的 Color Set,淺色與深色各一組
- 圓角卡片 + 細細的金色邊框,取代原本的強陰影

數字標號我寫成一個可重複使用的元件 `SectionHeading`,詳情頁的每個區塊都用它:`01 ── DEMO / 動畫示意`。

---

## 九、踩到的坑

1. **Launch Screen**:新版 Xcode 要在 `Info.plist` 設定 `UILaunchScreen`(背景色用 Color Set、圖片用 Image Set)。第一次執行時我以為沒顯示,其實是啟動太快;截圖時剛好拍到才確認有效。
2. **分頁卡片的陰影被切掉**:橫向 `ScrollView` 會裁切內容,卡片的陰影在邊緣被剪掉。解法是給每頁左右各 12pt 的 padding,再用 `.padding(.horizontal, -12)` 抵銷。
3. **深色模式的對比**:一開始用同一個類別色當文字色與圖示底色,在深色模式下白字疊在淺紫上看不清楚。後來拆成兩種色:`color`(文字與線條,淺深各一組)與 `fill`(白色圖示的底,固定用較深的色調)。
4. **DBSCAN 動畫變成一群**:示範資料的兩個半月形靠太近,距離小於 ε,演算法就把它們連成同一群了。把第二群往外移才得到「兩群 + 雜訊」。這個 bug 反而提醒我動畫要忠實呈現演算法。
5. **詳情頁底部操作列被 tab bar 擋住**:所以才有前面「進入詳情頁收起 tab bar」的做法。
6. **iPad 的差異**:`.sidebarAdaptable` 讓 tab bar 到上方,`LazyVGrid` 搭配 `GridItem(.adaptive)` 讓卡片牆自動變成四欄,不用另外寫 iPad 版面。

---

## 十、這次的心得

- **先把資料模型定好**,後面的列表、卡片牆、比較表、動畫選擇都只是同一份資料的不同呈現。
- **動畫的兩條路各有用途**:需要使用者操作、有明確狀態的用 `withAnimation`;單純展示過程的用 `TimelineView` + `Canvas`,程式碼反而更不容易出狀態錯誤。
- **新 API 值得追**:原生 `WebView` 省掉一整層 UIKit 橋接;SDK 的 deprecated 警告也是很好的學習線索。
- **換風格比想像中容易**,前提是顏色與字體一開始就集中管理,而不是散落在每個畫面裡。

目前還沒做到的部分:動畫沒有依「減少動態效果」的輔助使用設定調整、沒有在實機測試,也沒有收錄 Gradient Boosting、Diffusion、PPO 等模型。這些會是下一步。

---

## 結語

從一個「想讓機器學習更好懂」的念頭,到一個有 16 段動畫的電子書 App,最大的收穫是理解 SwiftUI 的宣告式動畫:你描述「狀態是什麼」,系統負責「怎麼過渡」。如果你也想做電子書作業,我的建議是:**挑一個你真的想看的主題**,做起來才不會膩。

操作展示影片:`【貼上你的影片連結】`
GitHub 專案原始碼:`【貼上你的 GitHub 連結】`

---

*文章中的程式碼為精簡版,完整內容請見原始碼。內容參考 Wikipedia 與 scikit-learn 文件。*
