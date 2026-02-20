//
//  NotchController.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/15/26.
//

import SwiftUI

struct NotchControlPanel: View {
    @ObservedObject var notchViewModel: NotchViewModel
    
    private var bindingForActiveContent: Binding<NotchContent> {
        Binding<NotchContent>(
            get: { notchViewModel.state.activeContent },
            set: { newValue in
                notchViewModel.send(.showActive(newValue))
            }
        )
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .center, spacing: 15) {
                activeContent
                Divider()
                temporaryContent
                Divider()
                notchOutline
                Spacer()
            }
            .padding(8)
        }
        .padding()
        .buttonStyle(.bordered)
        .controlSize(.regular)
    }
    
    @ViewBuilder
    var activeContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Active", systemImage: "dot.radiowaves.left.and.right")
                .font(.headline)

            Picker("Active", selection: bindingForActiveContent) {
                Label("None", systemImage: "minus.circle").tag(NotchContent.none)
                Label("Music", systemImage: "music.note").tag(NotchContent.music)
            }
            .pickerStyle(.segmented)
            .help("Выберите постоянное содержимое нотча")
        }
    }
    
    @ViewBuilder
    var temporaryContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Temporary", systemImage: "bolt.badge.clock")
                .font(.headline)
            
            ControlGroup {
                Button {
                    notchViewModel.send(.showTemporary(.charger, duration: 4))
                } label: {
                    Label("Charger", systemImage: "bolt.fill")
                }
                
                Button {
                    notchViewModel.send(.showTemporary(.lowPower, duration: 4))
                } label: {
                    Label("Low Power", systemImage: "battery.25")
                }
                
                Button {
                    notchViewModel.send(.showTemporary(.fullPower, duration: 5))
                } label: {
                    Label("Full Power", systemImage: "battery.100")
                }
                
                Button {
                    notchViewModel.send(.showTemporary(.onboarding, duration: .infinity))
                } label: {
                    Label("Onboarding", systemImage: "clipboard")
                }
            }
            .controlGroupStyle(.automatic)
            
            ControlGroup {
                Button {
                    notchViewModel.send(.showTemporary(. bluetooth, duration: 5))
                } label: {
                    Label("Audio HW", systemImage: "headphones")
                }
                
                Menu {
                    Button {
                        notchViewModel.send(.showTemporary(.systemHud(.volume), duration: 5))
                    } label: {
                        Label("Volume", systemImage: "speaker.wave.3.fill")
                    }
                    Button {
                        notchViewModel.send(.showTemporary(.systemHud(.display), duration: 5))
                    } label: {
                        Label("Display", systemImage: "sun.max.fill")
                    }
                    Button {
                        notchViewModel.send(.showTemporary(.systemHud(.keyboard), duration: 5))
                    } label: {
                        Label("Keyboard", systemImage: "light.max")
                    }
                } label: {
                    Label("System HUD", systemImage: "display")
                }
            }
            .controlGroupStyle(.automatic)
            
            HStack {
                Button {
                    notchViewModel.send(.hideTemporary)
                } label: {
                    Label("Hide temporary", systemImage: "eye.slash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
    }
    
    @ViewBuilder
    var notchOutline: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notch outline", systemImage: "rectangle.inset.topleft.fill")
                .font(.headline)

            Toggle(isOn: $notchViewModel.showNotch) {
                Label("Show stroke", systemImage: "rectangle.and.pencil.and.ellipsis")
            }
            .toggleStyle(.switch)
        }
    }
}

#Preview {
    NotchControlPanel(notchViewModel: NotchViewModel())
        .frame(width: 600, height: 400)
}
