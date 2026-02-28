//
//  HudViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/28/26.
//

import SwiftUI
import Combine

@MainActor
final class HudViewModel: ObservableObject {
    @Published var displayLevel: Int = 0
    @Published var keyboardLevel: Int = 0
    @Published var volumeLevel: Int = 0

    @Published var event: HudEvent?
    private var cancellables = Set<AnyCancellable>()

    init(service: HudService = .shared) {
        service.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newEvent in
                self?.handleUpdate(newEvent)
            }
            .store(in: &cancellables)
    }

    private func handleUpdate(_ event: HudEvent) {
        switch event {
        case .display(let v): displayLevel = v
        case .keyboard(let v): keyboardLevel = v
        case .volume(let v): volumeLevel = v
        }
        self.event = event
    }
}
