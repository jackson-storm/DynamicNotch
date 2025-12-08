import SwiftUI
import AppKit

struct ContentView: View {
    let safeInsetsTop: CGFloat
    
    var body: some View {
        ZStack {
            NotchContainerView(width: 225, height: 38, topCornerRadius: 9, bottomCornerRadius: 13, safeInsetsTop: safeInsetsTop) {
                Text("Dynamic Notch")
                    .foregroundStyle(.white)
            }
        }
        .padding(.top, -1)
    }
}

struct NotchContainerView<Content: View>: View {
    let width: CGFloat
    let height: CGFloat
    let topCornerRadius: CGFloat
    let bottomCornerRadius: CGFloat
    let safeInsetsTop: CGFloat
    let content: () -> Content
    
    init(
        width: CGFloat,
        height: CGFloat,
        topCornerRadius: CGFloat,
        bottomCornerRadius: CGFloat,
        safeInsetsTop: CGFloat,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.width = width
        self.height = height
        self.topCornerRadius = topCornerRadius
        self.bottomCornerRadius = bottomCornerRadius
        self.safeInsetsTop = safeInsetsTop
        self.content = content
    }
    
    var body: some View {
        ZStack {
            content()
                .frame(width: width, height: height)
                .background(
                    ZStack {
                        NotchBorderWithoutTop(topCornerRadius: topCornerRadius, bottomCornerRadius: bottomCornerRadius)
                            .stroke(.gray.opacity(0.2), lineWidth: 4)
                        
                        NotchShape(topCornerRadius: topCornerRadius, bottomCornerRadius: bottomCornerRadius)
                            .fill(.black)
                    }
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

import SwiftUI

struct ScreenSafeAreaKey: PreferenceKey {
    static var defaultValue: EdgeInsets = .init()
    
    static func reduce(value: inout EdgeInsets, nextValue: () -> EdgeInsets) {
        value = nextValue()
    }
}

extension View {
    func readScreenSafeArea(_ handler: @escaping (EdgeInsets) -> Void) -> some View {
        background(
            GeometryReader { _ in
                Color.clear
                    .preference(
                        key: ScreenSafeAreaKey.self,
                        value: macScreenInsets()
                    )
            }
        )
        .onPreferenceChange(ScreenSafeAreaKey.self, perform: handler)
    }
}

private func macScreenInsets() -> EdgeInsets {
    guard let screen = NSScreen.main else { return .init() }
    let i = screen.safeAreaInsets
    return EdgeInsets(
        top: i.top,
        leading: i.left,
        bottom: i.bottom,
        trailing: i.right
    )
}
