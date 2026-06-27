//
//  HomePageViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/18/26.
//

import Combine
import Foundation

@MainActor
final class HomePageViewModel: ObservableObject {
    @Published var event: HomePageEvent?
}
