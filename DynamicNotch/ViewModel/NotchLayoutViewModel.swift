import Combine
import SwiftUI

protocol NotchPresentable {
    static var kind: NotchContentKind { get }
}

final class NotchLayoutViewModel: ObservableObject {
    @Published var state: NotchState = .compact
    @Published var dragScale: CGFloat = 1.0
    
    private let sizes: [NotchContentKind: [NotchState: NotchSize]] = [
        .defaultNotch: [
            .compact:  .init(width: 207, height: 38,  topCornerRadius: 9,  bottomCornerRadius: 13)
        ],
        
        .player: [
            .compact:  .init(width: 295, height: 38,  topCornerRadius: 9,  bottomCornerRadius: 13),
            .expanded: .init(width: 440, height: 200, topCornerRadius: 28, bottomCornerRadius: 38)
        ]
    ]
    
    func size(for kind: NotchContentKind) -> NotchSize {
        sizes[kind]?[state] ?? NotchSize(width: 224, height: 38, topCornerRadius: 9, bottomCornerRadius: 13)
    }
}
