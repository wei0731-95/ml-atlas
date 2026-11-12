import SwiftUI

// 需求 5A:水平滑動分頁 —— TabView + .tabViewStyle(.page)
struct IntroCarouselView: View {
    @State private var page = 0

    var body: some View {
        TabView(selection: $page) {
            ForEach(IntroSlide.samples) { slide in
                IntroSlideCard(slide: slide, isActive: page == slide.id)
                    .tag(slide.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 230)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityLabel("機器學習簡介輪播")
    }
}

private struct IntroSlideCard: View {
    let slide: IntroSlide
    let isActive: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(slide.color.gradient)

            // 裝飾用的大圖示,使用 blur 與 blendMode(加分 3)
            Image(systemName: slide.symbol)
                .font(.system(size: 150))
                .foregroundStyle(.white.opacity(0.35))
                .blur(radius: 3)
                .blendMode(.overlay)
                .rotationEffect(.degrees(-12))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .offset(x: 24, y: 20)
                .accessibilityHidden(true)

            // 右上角的數字標號與金色斜線
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("/")
                    .font(.system(size: 30, weight: .ultraLight, design: .serif))
                Text(String(format: "%02d", slide.id + 1))
                    .font(.system(size: 30, weight: .light, design: .serif))
            }
            .foregroundStyle(Color(red: 0.89, green: 0.78, blue: 0.57))
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(18)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: slide.symbol)
                    .font(.title2)
                    .symbolEffect(.bounce, value: isActive)   // 需求 8
                Text(slide.title.uppercased())
                    .font(.system(.title2, design: .serif).weight(.semibold))
                    .tracking(2)
                Text(slide.subtitle)
                    .font(.headline)
                    .opacity(0.9)
                Text(slide.text)
                    .font(.subheadline)
                    .opacity(0.95)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.white)
            .padding(20)
            .padding(.bottom, 28)
        }
    }
}

#Preview {
    IntroCarouselView()
        .padding()
}
