//
//  MarqueeText.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/19/26.
//

import SwiftUI

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private struct MeasureSizeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(GeometryReader { geometry in
            Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
        })
    }
}

struct MarqueeText: View {
    private struct RestartKey: Equatable {
        let text: String
        let textWidth: CGFloat
        let frameWidth: CGFloat
    }

    @Binding var text: String
    let font: Font
    let nsFont: NSFont.TextStyle
    let textColor: Color
    let backgroundColor: Color
    let minDuration: Double
    let frameWidth: CGFloat
    
    @State private var animate = false
    @State private var textSize: CGSize = .zero
    @State private var offset: CGFloat = 0
    
    init(_ text: Binding<String>, font: Font = .body, nsFont: NSFont.TextStyle = .body, textColor: Color = .primary, backgroundColor: Color = .clear, minDuration: Double = 3.0, frameWidth: CGFloat = 200) {
        _text = text
        self.font = font
        self.nsFont = nsFont
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.minDuration = minDuration
        self.frameWidth = frameWidth
    }
    
    private var needsScrolling: Bool {
        textSize.width > frameWidth
    }

    private var restartKey: RestartKey {
        RestartKey(text: text, textWidth: textSize.width, frameWidth: frameWidth)
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 20) {
                Text(text)
                Text(text)
                    .opacity(needsScrolling ? 1 : 0)
            }
            .id(text)
            .font(font)
            .foregroundColor(textColor)
            .fixedSize(horizontal: true, vertical: false)
            .offset(x: animate ? offset : 0)
            .animation(
                animate ?
                    .linear(duration: Double(textSize.width / 30))
                    .delay(minDuration)
                    .repeatForever(autoreverses: false) : .none,
                value: animate
            )
            .background(backgroundColor)
            .modifier(MeasureSizeModifier())
            .onPreferenceChange(SizePreferenceKey.self) { size in
                textSize = CGSize(
                    width: size.width / 2,
                    height: NSFont.preferredFont(forTextStyle: nsFont).pointSize
                )
            }
        }
        .frame(width: frameWidth, alignment: .leading)
        .clipped()
        .mask(
            LinearGradient(
                stops: [
                    .init(color: (animate && offset < 0) ? .clear : .black, location: 0),
                    .init(color: .black, location: 0.05),
                    .init(color: .black, location: 0.9),
                    .init(color: needsScrolling ? .clear : .black, location: 1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .animation(.easeInOut(duration: 0.5), value: animate)
        .task(id: restartKey) {
            animate = false
            offset = 0

            guard needsScrolling else { return }

            try? await Task.sleep(for: .milliseconds(20))
            guard !Task.isCancelled, needsScrolling else { return }

            animate = true
            offset = -(textSize.width + 20)
        }
        .onDisappear {
            animate = false
            offset = 0
        }
        .frame(height: textSize.height * 1.3)
    }
}

#Preview {
    @Previewable @State var text = "Honor Airbuds 2 lite"
    MarqueeText(
        $text,
        font: .system(size: 14),
        nsFont: .body,
        textColor: .white.opacity(0.8),
        backgroundColor: .clear,
        minDuration: 0,
        frameWidth: 80
    )
    .padding(20)
    .background(.black)
}
