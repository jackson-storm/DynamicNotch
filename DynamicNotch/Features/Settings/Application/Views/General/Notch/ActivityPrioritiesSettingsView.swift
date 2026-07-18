//
//  ActivityPrioritiesSettingsView.swift
//  DynamicNotch
//

import SwiftUI

struct ActivityPrioritiesSettingsView: View {
    @ObservedObject var applicationSettings: ApplicationSettingsStore

    var body: some View {
        SettingsPageScrollView {
            prioritiesCard
        }
        .accessibilityIdentifier("settings.notch.priorities.root")
    }

    private var prioritiesCard: some View {
        SettingsCard() {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(NotchContentPriority.configurableKeys.enumerated()), id: \.element.id) { index, priorityKey in
                    priorityRow(for: priorityKey)
                    
                    if index < NotchContentPriority.configurableKeys.count - 1 {
                        Divider()
                            .opacity(0.6)
                            .padding(.leading, 43)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider().opacity(0.6)
            
            Text("settings.notch.priorities.customOrder.description")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func priorityRow(for priorityKey: NotchContentPriority.Key) -> some View {
        HStack(alignment: .center, spacing: 12) {
            priorityIcon(for: priorityKey)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(priorityKey.titleKey)
                
                Text(priorityDefaultText(for: priorityKey))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 12)
            
            Stepper(
                value: priorityBinding(for: priorityKey),
                in: NotchContentPriority.priorityRange
            ) {
                Text("\(applicationSettings.notchContentPriority(for: priorityKey))")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 22, alignment: .trailing)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.vertical, 1)
        .modifier(SettingsAccessibilityModifier(identifier: "settings.notch.priority.\(priorityKey.rawValue)"))
    }
    
    private func priorityBinding(for priorityKey: NotchContentPriority.Key) -> Binding<Int> {
        Binding(
            get: {
                applicationSettings.notchContentPriority(for: priorityKey)
            },
            set: { newValue in
                applicationSettings.setNotchContentPriority(newValue, for: priorityKey)
            }
        )
    }
    
    private func priorityDefaultText(for priorityKey: NotchContentPriority.Key) -> String {
        applicationSettings.appLanguage.locale.dnFormat(
            "settings.notch.priorities.row.default",
            fallback: "Default %lld",
            Int64(priorityKey.defaultValue)
        )
    }
    
    @ViewBuilder
    private func priorityIcon(for priorityPreset: NotchContentPriority.Key) -> some View {
        SettingsIconBadge(
            systemImage: priorityPreset.image,
            tint: priorityPreset.color,
            size: 30,
            iconSize: 14,
            cornerRadius: 9
        )
    }
}
