//
//  LockScreenNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct LockScreenNotchView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    @ObservedObject var lockScreenManager: LockScreenManager
    @ObservedObject var faceIDService: FaceIDService = .shared

    private var isFaceIDActive: Bool {
        faceIDService.state.isActivelyEvaluating || faceIDService.state.isSuccess || lockScreenManager.didUnlockWithFaceID
    }

    private var scanMedia: ScanMedia {
        switch faceIDService.state {
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
        switch faceIDService.state {
        case .searching, .scanning, .success:
            return .green
        case .failed:
            return .white.opacity(0.2)
        default:
            return .green
        }
    }
    
    private var isNotchlessLeadingPadding: CGFloat {
        isFaceIDActive ? 12 : 8
    }
    
    private var leadingPadding: CGFloat {
        isFaceIDActive ? 19 : 14
    }

    var body: some View {
        HStack {
            Image(systemName: (lockScreenManager.didUnlockWithFaceID || faceIDService.state.isSuccess || !lockScreenManager.isShowingLockPresentation) ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .scaleEffect(isFaceIDActive ? 1.4 : 1.0)
            
            Spacer()

            if isFaceIDActive {
                ScanAnimationView(media: scanMedia, tintColor: headlineColor)
                    .frame(width: isNotchlessScreen ? 28 : 32, height: isNotchlessScreen ? 28 : 32)
            }
        }
        .animation(.spring(response: 0.47), value: isFaceIDActive)
        .padding(.leading, isNotchlessScreen ? isNotchlessLeadingPadding.scaled(by: scale) : leadingPadding.scaled(by: scale))
        .padding(.trailing, isNotchlessScreen ? 6.scaled(by: scale) : 14.scaled(by: scale))
    }
}

