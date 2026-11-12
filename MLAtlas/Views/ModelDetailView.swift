import SwiftUI

/// 「延伸閱讀」要開啟的網頁
struct WebLink: Identifiable {
    let id = UUID()
    let title: String
    let url: URL
}

// 需求 2:模型詳情頁(由 NavigationLink 傳入 model)
struct ModelDetailView: View {
    let model: MLModel

    @Environment(FavoritesStore.self) private var favorites
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var appeared = false
    @State private var showPros = true
    @State private var showCons = false
    @State private var webLink: WebLink?

    private var tint: Color { model.category.color }
    private var isFavorite: Bool { favorites.contains(model) }

    var body: some View {
        ScrollView {
            // 加分 2:LazyVStack + pinned footer(底部操作列固定在畫面下方)
            LazyVStack(spacing: 20, pinnedViews: [.sectionFooters]) {
                Section {
                    header
                    SectionHeading(index: "01", title: "動畫示意", english: "Demo")
                    ModelDemoView(model: model)          // 需求 6:專屬動畫
                    SectionHeading(index: "02", title: "重點與說明", english: "Overview")
                    highlight
                    DetailPagerView(model: model)        // 需求 5B:水平分頁
                    SectionHeading(index: "03", title: "優點與缺點", english: "Pros & Cons")
                    prosAndCons
                    SectionHeading(index: "04", title: "代表演算法", english: "Algorithms")
                    algorithms
                } footer: {
                    actionBar
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(Color.pageBackground)
        .navigationTitle(model.name)
        .navigationBarTitleDisplayMode(.inline)
        // iPhone 上進入詳情頁時收起 tab bar,把空間留給底部操作列
        .toolbarVisibility(horizontalSizeClass == .compact ? .hidden : .automatic, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    favorites.toggle(model)
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .symbolEffect(.bounce, value: isFavorite)   // 需求 8
                        .foregroundStyle(.pink)
                }
                .accessibilityLabel(isFavorite ? "取消收藏" : "加入收藏")
            }
        }
        // 需求 9:以 sheet 顯示 WebView
        .sheet(item: $webLink) { link in
            WebReaderView(title: link.title, url: link.url)
        }
        .onAppear {
            // 需求 6:withAnimation + spring
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55)) {
                appeared = true
            }
        }
    }

    // MARK: 標題區

    private var header: some View {
        VStack(spacing: 10) {
            Text("\(model.category.index) / \(model.category.enName.uppercased())")
                .font(.caption.weight(.semibold))
                .tracking(3)
                .foregroundStyle(Color.gold)

            Image(systemName: model.symbol)
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: 92, height: 92)
                .background(model.category.fill.gradient, in: Circle())
                .softShadow()
                // 外圈金色點狀圓環
                .overlay {
                    Circle()
                        .strokeBorder(Color.gold.opacity(0.8), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [0.1, 6]))
                        .padding(-9)
                }
                .padding(.vertical, 10)
                .scaleEffect(appeared ? 1 : 0.3)
                .opacity(appeared ? 1 : 0)
                .symbolEffect(.bounce, value: appeared)
                .accessibilityHidden(true)

            Text(model.name)
                .font(.system(.title, design: .serif).weight(.semibold))
                .multilineTextAlignment(.center)
            Rectangle()
                .fill(Color.gold)
                .frame(width: 40, height: 1)
            Text(model.zhName)
                .font(.system(.title3, design: .serif))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Label(model.category.zhName, systemImage: model.category.symbol)
                    .chip(color: tint)
                DifficultyStars(level: model.difficulty)
            }

            Text(model.tagline)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    // MARK: 重點摘要(加分 4:多種文字樣式組合)

    private var highlight: some View {
        // iOS 26 起 Text + Text 已被標為 deprecated,改用官方建議的 Text 字串插值來組合樣式
        Text("""
        \(Text(model.name).bold().foregroundStyle(tint)) 屬於\
        \(Text(model.category.zhName).fontWeight(.semibold).underline())\
        ,典型用途是\(Text(model.typicalUse).bold().italic().foregroundStyle(Color.gold))\
        ;可解釋性\(Text(model.interpretability.label).fontWeight(.heavy))\
        、訓練成本\(Text(model.trainingCost.label).fontWeight(.heavy))\
        ,標註資料:\(Text(model.labelNeed.label).underline(color: tint))。
        """)
        .font(.callout)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: 優缺點(需求 7:transition)

    private var prosAndCons: some View {
        VStack(spacing: 14) {
            infoCard(title: "優點 Pros", symbol: "hand.thumbsup.fill", color: .green,
                     items: model.pros, isOpen: $showPros)
            infoCard(title: "缺點 Cons", symbol: "exclamationmark.triangle.fill", color: .orange,
                     items: model.cons, isOpen: $showCons)
        }
    }

    private func infoCard(title: String, symbol: String, color: Color,
                          items: [String], isOpen: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isOpen.wrappedValue.toggle()
                }
            } label: {
                HStack {
                    Label(title, systemImage: symbol)
                        .font(.headline)
                        .foregroundStyle(color)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isOpen.wrappedValue ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(isOpen.wrappedValue ? "點一下收合" : "點一下展開")

            if isOpen.wrappedValue {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        Label {
                            Text(item).font(.subheadline)
                        } icon: {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(color)
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .scale(scale: 0.9, anchor: .top).combined(with: .opacity)
                ))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
        .cardStyle()
    }

    // MARK: 代表演算法

    private var algorithms: some View {
        VStack(alignment: .leading, spacing: 10) {
            FlowLayout(spacing: 8) {
                ForEach(model.algorithms, id: \.self) { name in
                    Text(name).chip(color: tint)
                }
            }
        }
        .cardStyle()
        .padding(.bottom, 8)
    }

    // MARK: 底部操作列(pinned footer)

    private var actionBar: some View {
        HStack(spacing: 0) {
            Button {
                favorites.toggle(model)
            } label: {
                actionLabel(isFavorite ? "已收藏" : "收藏", symbol: isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(isFavorite ? .pink : .primary)
                    .symbolEffect(.bounce, value: isFavorite)
            }

            ShareLink(item: model.wikiURL, subject: Text(model.name), message: Text(model.tagline)) {
                actionLabel("分享", symbol: "square.and.arrow.up")
            }

            Menu {
                Button("Wikipedia", systemImage: "globe") {
                    webLink = WebLink(title: "Wikipedia", url: model.wikiURL)
                }
                if let docURL = model.docURL {
                    Button("scikit-learn 文件", systemImage: "doc.text") {
                        webLink = WebLink(title: "scikit-learn", url: docURL)
                    }
                }
            } label: {
                actionLabel("延伸閱讀", symbol: "safari")
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .softShadow()
        .padding(.vertical, 8)
    }

    private func actionLabel(_ title: String, symbol: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: symbol).font(.title3)
            Text(title).font(.caption2)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        ModelDetailView(model: MLModel.samples[6])
    }
    .environment(FavoritesStore())
}
