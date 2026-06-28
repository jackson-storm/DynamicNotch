//
//  LocalTimerSetupNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/20/26.
//

import SwiftUI

struct LocalTimerSetupNotchView: View {
    @ObservedObject var localTimerViewModel: LocalTimerViewModel
    
    @State private var hours: String = ""
    @State private var minutes: String = ""
    @State private var seconds: String = ""
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                setupView
                button
            }
        }
        .padding(.horizontal, 5)
        .padding(.bottom, 3)
    }
    
    @ViewBuilder
    private var setupView: some View {
        HStack(spacing: 15) {
            timeInputField(title: "HR", value: $hours, maxVal: 23)
            
            Text(":")
                .font(.system(size: 32, weight: .semibold, design: .rounded)).foregroundColor(.gray)
                .padding(.top, 10)
            
            timeInputField(title: "MIN", value: $minutes, maxVal: 59)
            
            Text(":")
                .font(.system(size: 32, weight: .semibold, design: .rounded)).foregroundColor(.gray)
                .padding(.top, 10)
            
            timeInputField(title: "SEC", value: $seconds, maxVal: 59)
        }
    }
    
    @ViewBuilder
    private var button: some View {
        HStack {
            Button {
                hours = ""
                minutes = ""
                seconds = ""
            } label: {
                Text(verbatim: "Reset")
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
            .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .gray.opacity(0.2)))
            
            Button {
                let h = Int(hours) ?? 0
                let m = Int(minutes) ?? 0
                let s = Int(seconds) ?? 0
                localTimerViewModel.start(hours: h, minutes: m, seconds: s)
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.green)
            }
            .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .green.opacity(0.3)))
        }
    }
    
    private func timeInputField(title: String, value: Binding<String>, maxVal: Int) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
            
            TextField("00", text: value)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.orange)
                .multilineTextAlignment(.center)
                .frame(width: 55)
                .onChange(of: value.wrappedValue) { _, newValue in
                    let filtered = newValue.filter { "0123456789".contains($0) }
                    var finalValue = filtered
                    
                    if filtered.count > 2 {
                        finalValue = String(filtered.prefix(2))
                    }
                    
                    if let intValue = Int(finalValue), intValue > maxVal {
                        finalValue = String(maxVal)
                    }
                    
                    if finalValue != newValue {
                        value.wrappedValue = finalValue
                    }
                }
        }
    }
}
