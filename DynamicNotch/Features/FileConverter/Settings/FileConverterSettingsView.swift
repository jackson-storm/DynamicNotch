import SwiftUI

struct FileConverterSettingsView: View {
    @ObservedObject var mediaSettings: MediaAndFilesSettingsStore

    var body: some View {
        SettingsPageScrollView {
            fileConverterActivity
            fileConverterFiles
            fileConverterQuality
        }
    }

    private var fileConverterActivity: some View {
        SettingsCard(title: "settings.fileConverter.activity.sectionTitle") {
            SettingsToggleRow(
                title: "settings.fileConverter.activity.title",
                description: "settings.fileConverter.activity.description",
                systemImage: "arrow.trianglehead.2.clockwise.rotate.90",
                color: .blue,
                isOn: $mediaSettings.isFileConverterLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.drop.fileConverter"
            )
        }
    }

    private var fileConverterFiles: some View {
        SettingsCard(title: "settings.fileConverter.files.sectionTitle") {
            SettingsMenuRow(
                title: "settings.fileConverter.outputLocation.title",
                description: "settings.fileConverter.outputLocation.description",
                options: Array(FileConverterOutputLocation.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.activities.live.drop.fileConverter.outputLocation",
                selection: $mediaSettings.fileConverterOutputLocation
            )

            Divider().opacity(0.6)

            SettingsMenuRow(
                title: "settings.fileConverter.existingFiles.title",
                description: "settings.fileConverter.existingFiles.description",
                options: Array(FileConverterExistingFileBehavior.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.activities.live.drop.fileConverter.existingFiles",
                selection: $mediaSettings.fileConverterExistingFileBehavior
            )

            Divider().opacity(0.6)

            SettingsTextFieldRow(
                title: "settings.fileConverter.filenameSuffix.title",
                description: "settings.fileConverter.filenameSuffix.description",
                placeholder: "-converted",
                accessibilityIdentifier: "settings.activities.live.drop.fileConverter.filenameSuffix",
                text: $mediaSettings.fileConverterFilenameSuffix
            )
        }
    }

    private var fileConverterQuality: some View {
        SettingsCard(title: "settings.fileConverter.quality.sectionTitle") {
            SettingsSliderRow(
                title: "settings.fileConverter.imageQuality.title",
                description: "settings.fileConverter.imageQuality.description",
                range: 10...100,
                step: 1,
                fractionLength: 0,
                suffix: "%",
                accessibilityIdentifier: "settings.activities.live.drop.fileConverter.imageQuality",
                value: imageQualityPercent
            )

            Divider().opacity(0.6)

            SettingsMenuRow(
                title: "settings.fileConverter.videoQuality.title",
                description: "settings.fileConverter.videoQuality.description",
                options: Array(FileConverterVideoQuality.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.activities.live.drop.fileConverter.videoQuality",
                selection: $mediaSettings.fileConverterVideoQuality
            )

            Divider().opacity(0.6)

            SettingsMenuRow(
                title: "settings.fileConverter.audioQuality.title",
                description: "settings.fileConverter.audioQuality.description",
                options: Array(FileConverterAudioQuality.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.activities.live.drop.fileConverter.audioQuality",
                selection: $mediaSettings.fileConverterAudioQuality
            )
        }
    }

    private var imageQualityPercent: Binding<Double> {
        Binding(
            get: { mediaSettings.fileConverterImageQuality * 100 },
            set: { mediaSettings.fileConverterImageQuality = $0 / 100 }
        )
    }

    private struct SettingsTextFieldRow: View {
        let title: LocalizedStringKey
        let description: LocalizedStringKey
        let placeholder: String
        let accessibilityIdentifier: String?

        @Binding var text: String

        var body: some View {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                TextField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 132)
            }
            .modifier(SettingsAccessibilityModifier(identifier: accessibilityIdentifier))
        }
    }
}
