import SwiftUI

struct FileConverterSettingsView: View {
    @ObservedObject var mediaSettings: MediaAndFilesSettingsStore

    var body: some View {
        SettingsPageScrollView {
            fileConverterFiles
            fileConverterQuality
        }
    }

    private var fileConverterFiles: some View {
        SettingsCard(title: "File Converter files") {
            SettingsMenuRow(
                title: "Output location",
                description: "Choose where converted files are saved.",
                options: Array(FileConverterOutputLocation.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.activities.live.drop.fileConverter.outputLocation",
                selection: $mediaSettings.fileConverterOutputLocation
            )

            Divider().opacity(0.6)

            SettingsMenuRow(
                title: "Existing files",
                description: "Choose what happens when a converted filename already exists.",
                options: Array(FileConverterExistingFileBehavior.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.activities.live.drop.fileConverter.existingFiles",
                selection: $mediaSettings.fileConverterExistingFileBehavior
            )

            Divider().opacity(0.6)

            SettingsTextFieldRow(
                title: "Filename suffix",
                description: "Add this suffix before the converted file extension.",
                placeholder: "-converted",
                accessibilityIdentifier: "settings.activities.live.drop.fileConverter.filenameSuffix",
                text: $mediaSettings.fileConverterFilenameSuffix
            )
        }
    }

    private var fileConverterQuality: some View {
        SettingsCard(title: "File Converter quality") {
            SettingsSliderRow(
                title: "Image quality",
                description: "Used for lossy image formats like JPEG, HEIC, WEBP, and AVIF.",
                range: 10...100,
                step: 1,
                fractionLength: 0,
                suffix: "%",
                accessibilityIdentifier: "settings.activities.live.drop.fileConverter.imageQuality",
                value: imageQualityPercent
            )

            Divider().opacity(0.6)

            SettingsMenuRow(
                title: "Video quality",
                description: "Choose the export preset used for video conversion.",
                options: Array(FileConverterVideoQuality.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.activities.live.drop.fileConverter.videoQuality",
                selection: $mediaSettings.fileConverterVideoQuality
            )

            Divider().opacity(0.6)

            SettingsMenuRow(
                title: "Audio quality",
                description: "Choose the bitrate target for compressed audio formats.",
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
