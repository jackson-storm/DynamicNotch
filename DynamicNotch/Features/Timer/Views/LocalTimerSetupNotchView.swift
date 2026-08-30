//
//  LocalTimerSetupNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/20/26.
//

import SwiftUI

struct LocalTimerSetupNotchView: View {
    @ObservedObject var localTimerViewModel: LocalTimerViewModel
    @State private var selectedPreset: LocalTimerPreset = .minutes45

    var body: some View {
        VStack(spacing: 22) {
            Picker("Focus duration", selection: $selectedPreset) {
                ForEach(LocalTimerPreset.allCases) { preset in
                    Text(verbatim: preset.title).tag(preset)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .controlSize(.large)
            .frame(width: 260)

            HStack {
                Spacer()

                Button {
                    localTimerViewModel.start(preset: selectedPreset)
                } label: {
                    Text(verbatim: "Start Focus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .buttonStyle(
                    PrimaryButtonStyle(
                        width: 160,
                        height: 38,
                        backgroundColor: .orange.opacity(0.8)
                    )
                )

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
