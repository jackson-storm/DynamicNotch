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
                notchViewModel.send(.showLiveActivitiy(newValue))
            }
        )
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .center, spacing: 15) {
                activeContent
                Divider()
                temporaryContent
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
                Label("Music", systemImage: "music.note").tag(NotchContent.music(.none))
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
                    notchViewModel.send(.showTemporaryNotification(.battery(.charger), duration: 4))
                } label: {
                    Label("Charger", systemImage: "bolt.fill")
                }
                
                Button {
                    notchViewModel.send(.showTemporaryNotification(.battery(.lowPower), duration: 4))
                } label: {
                    Label("Low Power", systemImage: "battery.25")
                }
                
                Button {
                    notchViewModel.send(.showTemporaryNotification(.battery(.fullPower), duration: 5))
                } label: {
                    Label("Full Power", systemImage: "battery.100")
                }
                
                Button {
                    notchViewModel.send(.showTemporaryNotification(.onboarding, duration: .infinity))
                } label: {
                    Label("Onboarding", systemImage: "clipboard")
                }
                
                Button {
                    notchViewModel.send(.showTemporaryNotification(.vpn(.connected), duration: 5))
                } label: {
                    Label("Vpn Connected", systemImage: "network")
                }
                
                Button {
                    notchViewModel.send(.showTemporaryNotification(.vpn(.disconnected), duration: 5))
                } label: {
                    Label("Vpn Disconnected", systemImage: "network.slash")
                }
            }
            .controlGroupStyle(.automatic)
            
            ControlGroup {
                Button {
                    notchViewModel.send(.showTemporaryNotification(. bluetooth, duration: 5))
                } label: {
                    Label("Audio HW", systemImage: "headphones")
                }
                
                Button {
                    notchViewModel.send(.showTemporaryNotification(.systemHud(.volume), duration: 2))
                } label: {
                    Label("Volume", systemImage: "speaker.wave.3.fill")
                }
                
                Button {
                    notchViewModel.send(.showTemporaryNotification(.systemHud(.display), duration: 2))
                } label: {
                    Label("Display", systemImage: "sun.max.fill")
                }
                
                Button {
                    notchViewModel.send(.showTemporaryNotification(.systemHud(.keyboard), duration: 2))
                } label: {
                    Label("Keyboard", systemImage: "light.max")
                }
            }
            .controlGroupStyle(.automatic)
            
            HStack {
                Button {
                    notchViewModel.send(.hide)
                } label: {
                    Label("Hide temporary", systemImage: "eye.slash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
    }
}

#Preview {
    NotchControlPanel(notchViewModel: NotchViewModel())
        .frame(width: 600, height: 400)
}
