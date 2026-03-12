//
//  GeneralSettingsViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/8/26.
//

import Combine
import SwiftUI
import ServiceManagement

final class GeneralSettingsViewModel: ObservableObject, NotchSettingsProviding {
    @AppStorage("isLaunchAtLoginEnabled") var isLaunchAtLoginEnabled: Bool = true {
        didSet {
            updateLaunchAtLogin()
        }
    }
    @AppStorage("notchWidth") var notchWidth: Int = 0 {
        didSet {
            notchSizeEvent.send(.width)
        }
    }

    @AppStorage("notchHeight") var notchHeight: Int = 0 {
        didSet {
            notchSizeEvent.send(.height)
        }
    }
    @AppStorage("isMenuBarIconVisible") var isMenuBarIconVisible: Bool = true
    @AppStorage("isShowNotchStrokeEnabled") var isShowNotchStrokeEnabled: Bool = false
    @AppStorage("isShowShadowEnabled") var isShowShadowEnabled: Bool = true
    @AppStorage("notchStrokeWidth") var notchStrokeWidth: Double = 1.5
    @AppStorage("displayLocation") private var storedDisplayLocationRaw: String = NotchDisplayLocation.main.rawValue
    
    @Published var displayLocation: NotchDisplayLocation
    
    let notchSizeEvent = PassthroughSubject<NotchSizeEvent, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let raw = UserDefaults.standard.string(forKey: "displayLocation") ?? NotchDisplayLocation.main.rawValue
        self.displayLocation = NotchDisplayLocation(rawValue: raw) ?? .main
        
        $displayLocation
            .sink { [weak self] newValue in
                self?.storedDisplayLocationRaw = newValue.rawValue
            }
            .store(in: &cancellables)
        
        updateLaunchAtLogin()
    }
    
    private func updateLaunchAtLogin() {
        let instance = SMAppService.mainApp
        
        do {
            if isLaunchAtLoginEnabled {
                try instance.register()
            } else {
                try instance.unregister()
            }
        } catch {
            print("Ошибка для \(instance.description): \(error)")
        }
    }
}
