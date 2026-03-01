//
//  DoNotDisturbViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/28/26.
//

import Foundation
import Combine

final class DoNotDisturbViewModel: ObservableObject {
    @Published var focusEvent: FocusEvent? = nil
    
    private let service = DoNotDisturbService()
    
    init() {
        service.onEvent = { [weak self] event in
            self?.focusEvent = event
        }
        service.start()
    }
}
