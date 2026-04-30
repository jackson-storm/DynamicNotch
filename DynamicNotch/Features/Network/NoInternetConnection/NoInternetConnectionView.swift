//
//  NoInternetConnectionView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/29/26.
//

import SwiftUI

struct NoInternetConnectionView: View {
    let onDismiss: @MainActor () -> Void
    let onOpenNetworkSettings: @MainActor () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Spacer()

            HStack(spacing: 6) {
                image
                Spacer()
                titleAndDescription
            }
            .padding(.horizontal, 10)

            actionButton
        }
        .padding(.horizontal, 35)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var image: some View {
        ZStack {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 32))
                .foregroundStyle(.green.gradient)
        }
    }

    @ViewBuilder
    private var titleAndDescription: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: "No Internet Connection")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(verbatim: "Connect to Wi-Fi, Ethernet, or Personal Hotspot to continue.")
                .foregroundColor(.white.opacity(0.56))
                .font(.system(size: 11, weight: .medium))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var actionButton: some View {
        HStack(spacing: 10) {
            Button(action: {
                onDismiss()
            }) {
                Text(verbatim: "OK")
                    .font(.system(size: 14))
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
            .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .gray.opacity(0.2)))

            Button(action: {
                onOpenNetworkSettings()
                onDismiss()
            }) {
                Text(verbatim: "Settings")
                    .font(.system(size: 14))
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .blue.opacity(0.2)))
        }
    }
}
