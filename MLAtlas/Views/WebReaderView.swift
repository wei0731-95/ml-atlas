import SwiftUI
import WebKit

// 需求 9:iOS 26 原生 WebView + WebPage,並處理載入狀態
struct WebReaderView: View {
    let title: String
    let url: URL

    @Environment(\.dismiss) private var dismiss
    @State private var page = WebPage()
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            WebView(page)
                .overlay {
                    if let loadError {
                        ContentUnavailableView {
                            Label("無法載入網頁", systemImage: "wifi.exclamationmark")
                        } description: {
                            Text(loadError)
                        } actions: {
                            Button("重試") { Task { await load() } }
                                .buttonStyle(.borderedProminent)
                        }
                        .background(Color(.systemBackground))
                        .transition(.opacity)
                    } else if page.isLoading && page.estimatedProgress < 0.3 {
                        VStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.system(size: 44))
                                .symbolEffect(.variableColor.iterative, isActive: page.isLoading)   // 需求 8
                                .foregroundStyle(LinearGradient.brand)
                            Text("載入中…")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground))
                        .transition(.opacity)
                    }
                }
                .overlay(alignment: .top) {
                    if page.isLoading {
                        ProgressView(value: page.estimatedProgress)
                            .progressViewStyle(.linear)
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut, value: page.isLoading)
                .navigationTitle(page.title.isEmpty ? title : page.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("關閉", systemImage: "xmark") { dismiss() }
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button("重新整理", systemImage: "arrow.clockwise") {
                            Task { await load() }
                        }
                        Link(destination: page.url ?? url) {
                            Label("用 Safari 開啟", systemImage: "safari")
                        }
                    }
                }
                .task { await load() }
        }
    }

    private func load() async {
        loadError = nil
        do {
            // load 會回傳導覽事件的 AsyncSequence;失敗時會丟出錯誤
            for try await _ in page.load(URLRequest(url: url)) {}
        } catch {
            loadError = error.localizedDescription
        }
    }
}

#Preview {
    WebReaderView(title: "Wikipedia", url: MLModel.samples[0].wikiURL)
}
