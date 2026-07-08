//
//  HomePageSettingsStore.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/18/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class HomePageSettingsStore: SettingsStoreBase {
    @Published var isHomePageLiveActivityEnabled: Bool {
        didSet {
            persist(isHomePageLiveActivityEnabled, for: GeneralSettingsStorage.Keys.homePageLiveActivity)
        }
    }
    
    @Published var isHomePagePageIndicatorEnabled: Bool {
        didSet {
            persist(isHomePagePageIndicatorEnabled, for: GeneralSettingsStorage.Keys.homePagePageIndicator)
        }
    }
    
    @Published var homePageIndicatorSize: HomePageIndicatorSize {
        didSet {
            persist(homePageIndicatorSize.rawValue, for: GeneralSettingsStorage.Keys.homePageIndicatorSize)
        }
    }
    
    @Published var homePageOrder: [HomePages] {
        didSet {
            persist(homePageOrder.map { $0.rawValue }, for: GeneralSettingsStorage.Keys.homePageOrder)
        }
    }
    
    @Published var homePageDisabled: Set<HomePages> {
        didSet {
            persist(Array(homePageDisabled).map { $0.rawValue }, for: GeneralSettingsStorage.Keys.homePageDisabled)
            if homePageDisabled.count == HomePages.allCases.count {
                isHomePageLiveActivityEnabled = false
            } else if !isHomePageLiveActivityEnabled && oldValue.count == HomePages.allCases.count {
                isHomePageLiveActivityEnabled = true
            }
        }
    }
    
    func resetHomePage() {
        isHomePageLiveActivityEnabled = (GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.homePageLiveActivity] as? Bool) ?? true
        homePageOrder = HomePages.allCases
        homePageDisabled = Set<HomePages>()
        isHomePagePageIndicatorEnabled = (GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.homePagePageIndicator] as? Bool) ?? true
        homePageIndicatorSize = .medium
    }
    
    override init(defaults: UserDefaults) {
        defaults.register(defaults: GeneralSettingsStorage.defaultValues)
        self.isHomePageLiveActivityEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.homePageLiveActivity
        )
        self.isHomePagePageIndicatorEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.homePagePageIndicator
        )
        
        let savedSize = defaults.string(forKey: GeneralSettingsStorage.Keys.homePageIndicatorSize) ?? ""
        self.homePageIndicatorSize = HomePageIndicatorSize(rawValue: savedSize) ?? .medium
        
        let savedOrder = (defaults.array(forKey: GeneralSettingsStorage.Keys.homePageOrder) as? [String]) ?? 
            ((GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.homePageOrder] as? [String]) ?? [])
        var parsedOrder = savedOrder.compactMap { HomePages(rawValue: $0) }
        if parsedOrder.isEmpty {
            parsedOrder = HomePages.allCases
        } else {
            for page in HomePages.allCases {
                if !parsedOrder.contains(page) {
                    parsedOrder.append(page)
                }
            }
        }
        self.homePageOrder = parsedOrder
        
        let savedDisabled = (defaults.array(forKey: GeneralSettingsStorage.Keys.homePageDisabled) as? [String]) ??
            ((GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.homePageDisabled] as? [String]) ?? [])
        self.homePageDisabled = Set(savedDisabled.compactMap { HomePages(rawValue: $0) })
        
        super.init(defaults: defaults)
    }
    
    private static func resolvedBool(defaults: UserDefaults, key: String) -> Bool {
        if let currentValue = defaults.object(forKey: key) as? Bool {
            return currentValue
        }

        return (GeneralSettingsStorage.defaultValues[key] as? Bool) ?? false
    }
}
