import SwiftUI

struct ClipboardSettingsView: View {
    @ObservedObject var settings: MediaAndFilesSettingsStore
    @ObservedObject var viewModel: ClipboardHistoryViewModel

    @State private var isConfirmingClear = false

    private let historyLimits = [5, 10, 20, 30, 50]

    var body: some View {
        SettingsPageScrollView {
            SettingsCard(title: "Clipboard history") {
                SettingsToggleRow(
                    title: "Recent clips in the notch",
                    description: "Keep a short, in-memory history so older copied items can be selected again from the home notch.",
                    systemImage: "doc.on.clipboard.fill",
                    color: .mint,
                    isOn: $settings.isClipboardHistoryEnabled,
                    accessibilityIdentifier: "settings.clipboard.historyEnabled"
                )

                Divider().opacity(0.6)

                SettingsToggleRow(
                    title: "Show copy feedback",
                    description: "Briefly show the copied item type in the notch. Copying never interrupts an expanded activity.",
                    systemImage: "checkmark.circle.fill",
                    color: .mint,
                    isOn: $settings.isClipboardFeedbackEnabled,
                    accessibilityIdentifier: "settings.clipboard.feedbackEnabled"
                )
                .disabled(!settings.isClipboardHistoryEnabled)
                .opacity(settings.isClipboardHistoryEnabled ? 1 : 0.5)

                Divider().opacity(0.6)

                SettingsMenuRow(
                    title: "History size",
                    description: "Limit the number of recent clips kept in memory.",
                    options: historyLimits,
                    optionTitle: { LocalizedStringKey("\($0) items") },
                    accessibilityIdentifier: "settings.clipboard.historyLimit",
                    selection: $settings.clipboardHistoryLimit
                )
                .disabled(!settings.isClipboardHistoryEnabled)
                .opacity(settings.isClipboardHistoryEnabled ? 1 : 0.5)
            }

            SettingsCard(title: "Privacy") {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.mint)
                        .frame(width: 30, height: 30)
                        .background(Color.mint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(verbatim: "Local and temporary")
                            .font(.system(size: 13, weight: .semibold))

                        Text(verbatim: "History is never saved to disk and clears when DynamicNotch quits, your Mac sleeps or locks, or clipboard history is turned off. Password-manager and concealed clipboard items are ignored. Large items are skipped and total memory is capped at 32 MB.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }

                Divider().opacity(0.6)

                SettingsButtonRow(
                    title: "Clear recent clips",
                    description: "Remove every saved clip without changing the item currently on the system clipboard.",
                    systemImage: "trash.fill",
                    color: .red,
                    buttonTitle: "Clear",
                    isButtonDisabled: viewModel.items.isEmpty,
                    accessibilityIdentifier: "settings.clipboard.clearHistory"
                ) {
                    isConfirmingClear = true
                }
            }
        }
        .alert("Clear clipboard history?", isPresented: $isConfirmingClear) {
            Button("Clear", role: .destructive) {
                viewModel.clearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every recent clip from DynamicNotch. Your current system clipboard is not changed.")
        }
    }
}
