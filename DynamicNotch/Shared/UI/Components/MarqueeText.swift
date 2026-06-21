//
//  MarqueeText.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/19/26.
//

import SwiftUI

struct MarqueeText: View {
    private struct RestartKey: Equatable {
        let text: String
        let frameWidth: CGFloat
    }

    @Binding var text: String
    let font: Font
    let nsFont: NSFont.TextStyle
    let textColor: Color
    let backgroundColor: Color
    let minDuration: Double
    let frameWidth: CGFloat
    let shortTextAlignment: TextAlignment
    
    @State private var animate = false
    @State private var textSize: CGSize = .zero
    @State private var offset: CGFloat = 0
    
    init(
        _ text: Binding<String>,
        font: Font = .body,
        nsFont: NSFont.TextStyle = .body,
        textColor: Color = .primary,
        backgroundColor: Color = .clear,
        minDuration: Double = 3.0,
        frameWidth: CGFloat = 200,
        shortTextAlignment: TextAlignment = .leading
    ) {
        _text = text
        self.font = font
        self.nsFont = nsFont
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.minDuration = minDuration
        self.frameWidth = frameWidth
        self.shortTextAlignment = shortTextAlignment
    }
    
    private var needsScrolling: Bool {
        textSize.width > frameWidth
    }

    private var restartKey: RestartKey {
        RestartKey(text: text, frameWidth: frameWidth)
    }

    private var textOffset: CGFloat {
        guard !needsScrolling else {
            return animate ? offset : 0
        }

        switch shortTextAlignment {
        case .center:
            return max((frameWidth - textSize.width) / 2, 0)
        case .trailing:
            return max(frameWidth - textSize.width, 0)
        default:
            return 0
        }
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 20) {
                Text(text)
                    .modifier(MeasureSizeModifier())
                Text(text)
                    .opacity(needsScrolling ? 1 : 0)
            }
            .id(text)
            .font(font)
            .foregroundColor(textColor)
            .fixedSize(horizontal: true, vertical: false)
            .offset(x: textOffset)
            .background(backgroundColor)
            .onPreferenceChange(SizePreferenceKey.self) { size in
                textSize = size
            }
        }
        .frame(width: frameWidth, alignment: .leading)
        .clipped()
        .modifier(MarqueeMaskModifier(offset: textOffset, needsScrolling: needsScrolling))
        .animation(
            animate ?
                .linear(duration: Double(textSize.width / 30))
                .delay(minDuration)
                .repeatForever(autoreverses: false) : .none,
            value: animate
        )
        .task(id: restartKey) {
            animate = false
            offset = 0

            guard !text.isEmpty else { return }

            while textSize.width == 0 {
                try? await Task.sleep(for: .milliseconds(50))
                if Task.isCancelled { return }
            }

            guard needsScrolling else { return }

            animate = true
            offset = -(textSize.width + 20)
        }
        .frame(height: textSize.height * 1.3)
    }
}

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

private struct MarqueeMaskModifier: AnimatableModifier {
    var offset: CGFloat
    var needsScrolling: Bool
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func body(content: Content) -> some View {
        let leftAlpha: Double = {
            if !needsScrolling { return 1.0 }
            if offset >= 0 { return 1.0 }
            if offset <= -8 { return 0.0 }
            return 1.0 + Double(offset) / 8.0
        }()
        
        return content.mask(
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(leftAlpha), location: 0),
                    .init(color: .black, location: 0.05),
                    .init(color: .black, location: 0.9),
                    .init(color: needsScrolling ? .clear : .black, location: 1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}
