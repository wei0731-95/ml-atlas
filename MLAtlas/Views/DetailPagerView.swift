import SwiftUI

// 需求 5B:水平滑動分頁 —— ScrollView(.horizontal) + scrollTargetBehavior(.paging) + scrollTargetLayout()
struct DetailPagerView: View {
    let model: MLModel

    enum Page: Int, CaseIterable, Identifiable {
        case concept, mechanism, applications

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .concept: "概念"
            case .mechanism: "原理"
            case .applications: "應用"
            }
        }

        var symbol: String {
            switch self {
            case .concept: "lightbulb.fill"
            case .mechanism: "gearshape.2.fill"
            case .applications: "briefcase.fill"
            }
        }
    }

    @State private var current: Page? = .concept
    @Namespace private var tabNamespace

    var body: some View {
        VStack(spacing: 12) {
            // 分頁標籤:選取底色用 matchedGeometryEffect 在標籤之間滑動(需求 6)
            HStack(spacing: 0) {
                ForEach(Page.allCases) { page in
                    Button {
                        withAnimation(.snappy) { current = page }
                    } label: {
                        Label(page.title, systemImage: page.symbol)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(current == page ? Color.white : Color.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background {
                                if current == page {
                                    Capsule()
                                        .fill(model.category.fill.gradient)
                                        .matchedGeometryEffect(id: "selectedTab", in: tabNamespace)
                                }
                            }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(current == page ? .isSelected : [])
                }
            }
            .padding(4)
            .background(Color(.tertiarySystemFill), in: Capsule())
            .animation(.snappy, value: current)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Page.allCases) { page in
                        pageContent(page)
                            .padding(.horizontal, 12)   // 留空間給卡片陰影,避免被捲動區裁切
                            .padding(.top, 6)
                            .padding(.bottom, 16)
                            .containerRelativeFrame(.horizontal)
                            .id(page)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $current)
            .scrollIndicators(.hidden)
            .padding(.horizontal, -12)
        }
    }

    @ViewBuilder
    private func pageContent(_ page: Page) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(page.title, systemImage: page.symbol)
                .font(.headline)
                .foregroundStyle(model.category.color)

            switch page {
            case .concept:
                Text(model.concept)
            case .mechanism:
                Text(model.mechanism)
            case .applications:
                ForEach(model.applications, id: \.self) { item in
                    Label(item, systemImage: "arrow.right.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                }
            }

            Text("← 左右滑動切換 →")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

#Preview {
    DetailPagerView(model: MLModel.samples[0])
        .padding()
}
