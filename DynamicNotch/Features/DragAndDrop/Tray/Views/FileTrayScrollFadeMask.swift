import SwiftUI

struct FileTrayScrollFadeMask: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .mask(horizontalFade)
            .mask(verticalFade)
    }

    private var horizontalFade: some View {
        LinearGradient(
            stops: horizontalFadeStops,
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var verticalFade: some View {
        LinearGradient(
            stops: verticalFadeStops,
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var horizontalFadeStops: [Gradient.Stop] {
        [
            .init(color: .clear, location: 0),
            .init(color: .black, location: 0.02),
            .init(color: .black, location: 0.98),
            .init(color: .clear, location: 1)
        ]
    }
    
    private var verticalFadeStops: [Gradient.Stop] {
        [
            .init(color: .clear, location: 0),
            .init(color: .black, location: 0.04),
            .init(color: .black, location: 0.96),
            .init(color: .clear, location: 1)
        ]
    }
}
