//
//  SettingsPageScrollView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/4/26.
//

import SwiftUI

struct SettingsPageScrollView<Content: View>: View {
    private let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        if #available(macOS 26.0, *) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    content
                }
                .padding(.vertical, 15)
                .padding(.horizontal, 5)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
            
        } else {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    content
                }
                .padding(.vertical, 15)
                .padding(.horizontal, 5)
            }
        }
    }
}
