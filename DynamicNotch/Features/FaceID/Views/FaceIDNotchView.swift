//
//  FaceIDNotchView.swift
//  DynamicNotch
//

import SwiftUI

struct FaceIDNotchView: View {
    var style: FaceIDPresentationStyle = .expanded
    
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    @Environment(\.notchScale) private var scale
    @ObservedObject var service: FaceIDService = .shared
    
    @State private var hasSucceeded: Bool = false
    
    private var scanMedia: ScanMedia {
        if hasSucceeded {
            return .success
        }
        switch service.state {
        case .idle:
            return .idle
        case .searching:
            return .searching
        case .scanning:
            return .scanning
        case .success:
            return .success
        case .failed:
            return .failure
        }
    }
    
    private var headlineColor: Color {
        switch service.state {
        case .searching, .scanning, .success:
            return .green
        case .failed:
            return hasSucceeded ? .green : .white.opacity(0.2)
        default:
            return .green
        }
    }
    
    var body: some View {
        VStack {
            ScanAnimationView(media: scanMedia, tintColor: headlineColor)
                .frame(width: isNotchlessScreen ? 100 : 110, height: isNotchlessScreen ? 100 : 110)
        }
        .onChange(of: service.state) { _, newState in
            if case .success = newState {
                hasSucceeded = true
            } else if case .searching = newState {
                hasSucceeded = false
            }
        }
    }
}

