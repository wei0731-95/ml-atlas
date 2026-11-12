import SwiftUI

// 加分 5:自訂 ViewModifier —— 把重複出現的樣式整理起來
// 視覺風格:深紫主色、米白底、金色細線點綴、襯線標題與 01 / 02 數字標號

/// 柔和陰影
struct SoftShadow: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(color: .black.opacity(0.06), radius: 12, y: 5)
    }
}

/// 卡片外觀:內距 + 圓角背景 + 細框線 + 陰影
struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.cardBackground,
                        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.gold.opacity(0.22), lineWidth: 0.5)
            }
            .modifier(SoftShadow())
    }
}

/// 區塊標題文字(襯線字體)
struct SectionTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.title3, design: .serif).weight(.semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

/// 小標籤(膠囊)
struct ChipStyle: ViewModifier {
    var color: Color

    func body(content: Content) -> some View {
        content
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(color)
            .background(color.opacity(0.14), in: Capsule())
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 16, padding: CGFloat = 16) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius, padding: padding))
    }

    func softShadow() -> some View {
        modifier(SoftShadow())
    }

    func sectionTitle() -> some View {
        modifier(SectionTitleStyle())
    }

    func chip(color: Color) -> some View {
        modifier(ChipStyle(color: color))
    }
}

/// 帶數字標號的區塊標題:「01 ── CONCEPT / 概念」
struct SectionHeading: View {
    let index: String
    let title: String
    let english: String

    var body: some View {
        HStack(spacing: 10) {
            Text(index)
                .font(.system(.title2, design: .serif).weight(.light))
                .foregroundStyle(Color.gold)
            Rectangle()
                .fill(Color.gold)
                .frame(width: 22, height: 1)
            VStack(alignment: .leading, spacing: 1) {
                Text(english.uppercased())
                    .font(.caption2.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.system(.headline, design: .serif))
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isHeader)
    }
}

extension Color {
    // Asset Catalog 的 Color Set(需求 10),Light / Dark 各有一組顏色
    static var brandStart: Color { Color("BrandStart") }
    static var brandEnd: Color { Color("BrandEnd") }
    /// 金色點綴:數字標號、細線、星等
    static var gold: Color { Color("Gold") }
    /// 頁面底色:淺色為淡米色,深色為深紫黑
    static var pageBackground: Color { Color("PageBackground") }
    static var cardBackground: Color { Color("CardBackground") }
}

extension LinearGradient {
    /// App 主色調:深紫漸層
    static var brand: LinearGradient {
        LinearGradient(colors: [.brandStart, .brandEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

#Preview {
    VStack(spacing: 20) {
        SectionHeading(index: "01", title: "概念", english: "Concept")
        Text("卡片樣式").cardStyle()
    }
    .padding()
    .background(Color.pageBackground)
}
