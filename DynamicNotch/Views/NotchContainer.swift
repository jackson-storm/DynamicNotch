import SwiftUI

struct NotchContainer<Content: View>: View {
    @EnvironmentObject var layout: NotchLayoutViewModel
    @ViewBuilder var content: () -> Content
    
    let kind: NotchContentKind
    
    init(kind: NotchContentKind, @ViewBuilder content: @escaping () -> Content) {
        self.kind = kind
        self.content = content
    }
    
    var body: some View {
        let size = layout.size(for: kind)
        
        NotchShape(topCornerRadius: size.topCornerRadius, bottomCornerRadius: size.bottomCornerRadius)
            .fill(Color.black)
            .stroke(.black, lineWidth: 1)
            .frame(width: size.width, height: size.height)
            .overlay(content())
    }
}
