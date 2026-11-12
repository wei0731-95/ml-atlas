import SwiftUI

/// 動畫總覽:把 16 個模型的示意動畫排成格子牆,一次看完(需求 6、12)
struct DemoGalleryView: View {
    private let columns = [GridItem(.adaptive(minimum: 320), spacing: 16, alignment: .top)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(MLModel.samples) { model in
                    VStack(alignment: .leading, spacing: 8) {
                        Label("\(model.name) \(model.zhName)", systemImage: model.symbol)
                            .font(.system(.subheadline, design: .serif).weight(.bold))
                            .foregroundStyle(model.category.color)
                            .padding(.horizontal, 6)
                        ModelDemoView(model: model)
                    }
                }
            }
            .padding()
        }
        .background(Color.pageBackground)
        .navigationTitle("動畫總覽")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        DemoGalleryView()
    }
}
