//
//  AirDropViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/24/26.
//

import SwiftUI
import Combine

enum AirDropEvent: Equatable {
    case dragStarted
    case dragEnded
    case dropped
}

@MainActor
final class AirDropNotchViewModel: ObservableObject {
    @Published private(set) var event: AirDropEvent?
    @Published private(set) var isDraggingFile = false

    func setDraggingFile(_ isDraggingFile: Bool) {
        guard self.isDraggingFile != isDraggingFile else { return }

        self.isDraggingFile = isDraggingFile
        event = isDraggingFile ? .dragStarted : .dragEnded
    }

    func handleSuccessfulDrop() {
        isDraggingFile = false
        event = .dropped
    }
}
