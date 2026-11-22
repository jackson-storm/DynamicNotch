//
//  LockScreenFaceIDButtonView.swift
//  DynamicNotch
//

import SwiftUI

struct LockScreenFaceIDButtonView: View {
    let onActivate: () -> Void
    
    @ObservedObject var service: FaceIDService = .shared
    
    var body: some View {
        Button(action: onActivate) {
            Text(verbatim: "Face ID")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
        .modifier(FaceIDButtonAdaptiveStyle())
        .environment(\.controlActiveState, .active)
        .environment(\.colorScheme, .dark)
    }
}

private struct FaceIDButtonAdaptiveStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .buttonBorderShape(.capsule)
                .buttonStyle(.glass)
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                )
                .buttonStyle(.plain)
        }
    }
}
