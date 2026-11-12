import SwiftUI

// 互動實驗室:圖片效果(加分 3)、transition(需求 7)、SF Symbol 動畫(需求 8)
struct LabView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    NavigationLink {
                        DemoGalleryView()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "play.square.stack.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("動畫總覽 Demo Gallery").font(.headline)
                                Text("一次看完 \(MLModel.samples.count) 個模型的示意動畫")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                        }
                        .cardStyle()
                    }
                    .buttonStyle(.plain)

                    ImageEffectLab()
                    TransitionLab()
                    SymbolEffectLab()
                }
                .padding()
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(Color.pageBackground)
            .navigationTitle("互動實驗室 Lab")
        }
    }
}

// MARK: - 圖片效果

private enum BlendOption: String, CaseIterable, Identifiable {
    case none = "無", multiply = "multiply", screen = "screen", overlay = "overlay", difference = "difference"

    var id: String { rawValue }

    var mode: BlendMode {
        switch self {
        case .none: .normal
        case .multiply: .multiply
        case .screen: .screen
        case .overlay: .overlay
        case .difference: .difference
        }
    }
}

/// 依開關決定是否反轉顏色
private struct InvertIfNeeded: ViewModifier {
    let isOn: Bool

    func body(content: Content) -> some View {
        if isOn {
            content.colorInvert()
        } else {
            content
        }
    }
}

private struct ImageEffectLab: View {
    @State private var blur = 0.0
    @State private var brightness = 0.0
    @State private var contrast = 1.0
    @State private var saturation = 1.0
    @State private var grayscale = 0.0
    @State private var hue = 0.0
    @State private var invert = false
    @State private var multiply = false
    @State private var useMask = false
    @State private var blend: BlendOption = .none

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(index: "01", title: "圖片效果", english: "Image Effects")

            // 加分 3:blur、blendMode、brightness、colorInvert、colorMultiply、contrast、
            // grayscale、hueRotation、mask、saturation
            LabArtwork()
                .overlay {
                    if blend != .none {
                        LinearGradient(colors: [.orange, .cyan], startPoint: .top, endPoint: .bottom)
                            .blendMode(blend.mode)
                    }
                }
                .blur(radius: blur)
                .brightness(brightness)
                .contrast(contrast)
                .saturation(saturation)
                .grayscale(grayscale)
                .hueRotation(.degrees(hue))
                .colorMultiply(multiply ? .yellow : .white)
                .modifier(InvertIfNeeded(isOn: invert))
                .mask {
                    if useMask {
                        Image(systemName: "brain.head.profile")
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                    } else {
                        Rectangle()
                    }
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .animation(.easeInOut(duration: 0.3), value: useMask)
                .animation(.easeInOut(duration: 0.3), value: blend)
                .accessibilityLabel("效果預覽圖")

            sliderRow("模糊 blur", value: $blur, range: 0...12, text: String(format: "%.0f", blur))
            sliderRow("亮度 brightness", value: $brightness, range: -0.5...0.5, text: String(format: "%+.2f", brightness))
            sliderRow("對比 contrast", value: $contrast, range: 0.5...2, text: String(format: "%.2f", contrast))
            sliderRow("飽和度 saturation", value: $saturation, range: 0...2, text: String(format: "%.2f", saturation))
            sliderRow("灰階 grayscale", value: $grayscale, range: 0...1, text: String(format: "%.2f", grayscale))
            sliderRow("色相 hueRotation", value: $hue, range: 0...360, text: String(format: "%.0f°", hue))

            Toggle("反轉顏色 colorInvert", systemImage: "circle.righthalf.filled", isOn: $invert)
            Toggle("顏色相乘 colorMultiply(黃)", systemImage: "paintpalette.fill", isOn: $multiply)
            Toggle("遮罩 mask(用 SF Symbol 當形狀)", systemImage: "theatermask.and.paintbrush.fill", isOn: $useMask)

            VStack(alignment: .leading, spacing: 6) {
                Label("混合模式 blendMode", systemImage: "square.2.layers.3d.fill")
                Picker("混合模式", selection: $blend) {
                    ForEach(BlendOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            Button("重設所有效果", systemImage: "arrow.counterclockwise") {
                withAnimation(.spring) {
                    blur = 0; brightness = 0; contrast = 1; saturation = 1; grayscale = 0; hue = 0
                    invert = false; multiply = false; useMask = false; blend = .none
                }
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
        .font(.subheadline)
        .cardStyle()
    }

    private func sliderRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                Spacer()
                Text(text)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
                .accessibilityLabel(title)
        }
    }
}

/// 用 SwiftUI 畫的示範圖,不需要外部圖片檔
private struct LabArtwork: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(.yellow).frame(width: 110).offset(x: -90, y: -40)
            Circle().fill(.green).frame(width: 80).offset(x: 100, y: 50)
            RoundedRectangle(cornerRadius: 14).fill(.orange).frame(width: 70, height: 70)
                .rotationEffect(.degrees(20)).offset(x: 80, y: -50)
            Image(systemName: "brain.head.profile")
                .font(.system(size: 90))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Transition

private enum TransitionOption: String, CaseIterable, Identifiable {
    case slide = "slide"
    case scale = "scale + opacity"
    case move = "move(bottom)"
    case asymmetric = "asymmetric"
    case blur = "blurReplace"

    var id: String { rawValue }

    @MainActor var transition: AnyTransition {
        switch self {
        case .slide:
            .slide
        case .scale:
            .scale(scale: 0.3).combined(with: .opacity)
        case .move:
            .move(edge: .bottom).combined(with: .opacity)
        case .asymmetric:
            .asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity))
        case .blur:
            AnyTransition(.blurReplace)
        }
    }
}

private struct TransitionLab: View {
    @State private var option: TransitionOption = .scale
    @State private var isShown = true

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(index: "02", title: "轉場", english: "Transition")

            Picker("轉場種類", selection: $option) {
                ForEach(TransitionOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
                if isShown {
                    // 需求 7:元件出現與消失時的 transition
                    Label("Hello, ML!", systemImage: "sparkles")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 14)
                        .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .transition(option.transition)
                        .id(option)
                }
            }
            .frame(height: 120)
            .clipped()

            Button(isShown ? "讓它消失" : "讓它出現", systemImage: isShown ? "eye.slash.fill" : "eye.fill") {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isShown.toggle()
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .font(.subheadline)
        .cardStyle()
    }
}

// MARK: - SF Symbol 動畫

private struct SymbolEffectLab: View {
    @State private var trigger = 0
    @State private var isActive = true

    private let columns = [GridItem(.adaptive(minimum: 92), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(index: "03", title: "SF Symbol 動畫", english: "symbolEffect")

            // 需求 8:bounce、pulse、variableColor、rotate、wiggle、breathe
            LazyVGrid(columns: columns, spacing: 12) {
                cell("bounce") {
                    Image(systemName: "heart.fill").symbolEffect(.bounce, value: trigger)
                }
                cell("wiggle") {
                    Image(systemName: "bell.fill").symbolEffect(.wiggle, value: trigger)
                }
                cell("pulse") {
                    Image(systemName: "waveform").symbolEffect(.pulse, isActive: isActive)
                }
                cell("variableColor") {
                    Image(systemName: "wifi").symbolEffect(.variableColor.iterative, isActive: isActive)
                }
                cell("rotate") {
                    Image(systemName: "gearshape.fill").symbolEffect(.rotate, isActive: isActive)
                }
                cell("breathe") {
                    Image(systemName: "sparkles").symbolEffect(.breathe, isActive: isActive)
                }
            }

            HStack {
                Button("觸發 bounce / wiggle", systemImage: "hand.tap.fill") {
                    trigger += 1
                }
                .buttonStyle(.borderedProminent)
                Spacer()
                Toggle("持續動畫", isOn: $isActive)
                    .fixedSize()
            }
        }
        .font(.subheadline)
        .cardStyle()
    }

    private func cell(_ name: String, @ViewBuilder icon: () -> some View) -> some View {
        VStack(spacing: 8) {
            icon()
                .font(.system(size: 34))
                .foregroundStyle(LinearGradient.brand)
                .frame(height: 44)
            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    LabView()
}
