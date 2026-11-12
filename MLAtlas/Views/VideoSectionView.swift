import AVKit
import SwiftUI

// 需求 14:VideoPlayer —— 預設播放 Bundle 內由程式產生的 intro.mp4,也可切換成網路影片
struct VideoSectionView: View {
    enum Source: String, CaseIterable, Identifiable {
        case bundle = "內建影片"
        case network = "網路影片"

        var id: String { rawValue }
    }

    /// 想換成自己的網路影片,改這個網址即可(需為 mp4 或 HLS)
    static let networkURL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8")!

    @State private var source: Source = .bundle
    @State private var player: AVPlayer?
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("影片來源", selection: $source) {
                ForEach(Source.allCases) { source in
                    Text(source.rawValue).tag(source)
                }
            }
            .pickerStyle(.segmented)

            ZStack {
                Color.black

                if let errorMessage {
                    // 錯誤處理:影片不存在或網路失敗時顯示說明
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.yellow)
                        Text("影片無法播放")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .transition(.opacity)
                } else if let player {
                    VideoPlayer(player: player)
                }

                if isLoading {
                    Image(systemName: "rays")
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                        .symbolEffect(.variableColor.iterative, isActive: isLoading)
                        .accessibilityLabel("影片載入中")
                }
            }
            .aspectRatio(16 / 9, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(source == .bundle
                 ? "intro.mp4 由 Scripts/generate_video.swift 以 AVFoundation 產生並放入 Bundle。"
                 : "透過 AVPlayer(url:) 串流 Apple 提供的公開 HLS 測試影片,需要網路連線。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .task(id: source) {
            await load(source)
        }
        .onDisappear {
            player?.pause()
        }
    }

    private func load(_ source: Source) async {
        player?.pause()
        errorMessage = nil

        let url: URL
        switch source {
        case .bundle:
            guard let bundled = Bundle.main.url(forResource: "intro", withExtension: "mp4") else {
                player = nil
                errorMessage = "在 App Bundle 中找不到 intro.mp4,請執行 Scripts/generate_video.swift 重新產生。"
                return
            }
            url = bundled
        case .network:
            url = Self.networkURL
        }

        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        isLoading = true
        defer { isLoading = false }

        // 等待影片就緒;若載入失敗則顯示錯誤訊息
        while !Task.isCancelled {
            switch item.status {
            case .readyToPlay:
                return
            case .failed:
                withAnimation {
                    errorMessage = item.error?.localizedDescription ?? "請檢查網路連線後再試一次。"
                }
                return
            default:
                try? await Task.sleep(for: .milliseconds(250))
            }
        }
    }
}

#Preview {
    VideoSectionView()
        .padding()
}
