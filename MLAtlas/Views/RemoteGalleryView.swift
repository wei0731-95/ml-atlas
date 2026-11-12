import SwiftUI

private struct RemoteImage: Identifiable {
    let id: Int
    let title: String
    let url: URL?
}

// 加分 6:AsyncImage —— 處理 placeholder、失敗畫面與 transition
struct RemoteGalleryView: View {
    private let images: [RemoteImage] = [
        RemoteImage(id: 0, title: "Neural Network",
                    url: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/4/46/Colored_neural_network.svg/500px-Colored_neural_network.svg.png")),
        RemoteImage(id: 1, title: "Linear Regression",
                    url: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Linear_regression.svg/500px-Linear_regression.svg.png")),
        RemoteImage(id: 2, title: "SVM Margin",
                    url: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/7/72/SVM_margin.png/500px-SVM_margin.png")),
        RemoteImage(id: 3, title: "Decision Tree (CART)",
                    url: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f3/CART_tree_titanic_survivors.png/500px-CART_tree_titanic_survivors.png")),
        // 刻意放一個不存在的網址,用來展示載入失敗的畫面
        RemoteImage(id: 4, title: "失敗畫面示範",
                    url: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/ml-atlas-not-found.png/500px-ml-atlas-not-found.png")),
    ]

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 12) {
                ForEach(images) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        AsyncImage(url: item.url, transaction: Transaction(animation: .easeInOut(duration: 0.5))) { phase in
                            switch phase {
                            case .empty:
                                // placeholder
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .padding(8)
                                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                            case .failure:
                                // 失敗畫面
                                VStack(spacing: 6) {
                                    Image(systemName: "photo.badge.exclamationmark")
                                        .font(.title)
                                    Text("圖片載入失敗")
                                        .font(.caption)
                                }
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .transition(.opacity)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 220, height: 150)
                        // 網路圖片多半是白底,固定用白色襯底,Dark mode 也看得清楚
                        .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color(.separator))
                        }

                        Text(item.title)
                            .font(.caption.weight(.semibold))
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(item.title)
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    RemoteGalleryView()
}
