//
//  AirDropActiveNotchView.swift
//  DynamicNotch
//

import SwiftUI

struct AirDropActiveNotchView: View {
    @ObservedObject var airDropViewModel: AirDropNotchViewModel
    @Environment(\.notchScale) private var scale
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    
    @State private var isPulsing = false
    
    var body: some View {
        HStack {
            airDropIcon
            Spacer()
            statusIndicator
        }
        .padding(.vertical, 10)
        .padding(.leading, isNotchlessScreen ? 3.scaled(by: scale) : 13.scaled(by: scale))
        .padding(.trailing, isNotchlessScreen ? 4.scaled(by: scale) : 12.scaled(by: scale))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
    
    private var airDropIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: isNotchlessScreen ? 20 : 6)
                .fill(Color.blue.opacity(0.3))
                .opacity(isPulsing ? 1.0 : 0.7)
                .frame(width: isNotchlessScreen ? 20 : 25, height: isNotchlessScreen ? 20 : 25)
            
            Image("airdrop.white")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(Color.blue)
                .frame(width: isNotchlessScreen ? 16 : 18, height: isNotchlessScreen ? 16 : 18)
        }
    }
    
    @ViewBuilder
    private var statusIndicator: some View {
        if let transfer = airDropViewModel.activeTransfer {
            switch transfer.status {
            case .transferring:
                AirDropTransferProgressRingView(
                    progress: transfer.progress,
                    size: isNotchlessScreen ? 16 : 20,
                    lineWidth: isNotchlessScreen ? 2.0 : 2.5,
                    ringColor: .blue,
                    stopSquareSize: isNotchlessScreen ? 5 : 7
                )
                .padding(.trailing, 2)
                
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: isNotchlessScreen ? 14 : 20, weight: .semibold))
                    .foregroundStyle(Color.blue)
                
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: isNotchlessScreen ? 14 : 20, weight: .semibold))
                    .foregroundStyle(Color.red)
            }
        }
    }
}
