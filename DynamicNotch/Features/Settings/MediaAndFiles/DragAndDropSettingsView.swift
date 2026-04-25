import SwiftUI

struct DragAndDropSettingsView: View {
    @ObservedObject var mediaSettings: MediaAndFilesSettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore

    private var isDefaultStrokeLocked: Bool {
        appearanceSettings.isDefaultActivityStrokeEnabled
    }
    
    var body: some View {
        SettingsPageScrollView {
            dragAndDropActivity
            dragAndDropMode
        }
    }
    
    private var dragAndDropActivity: some View {
        SettingsCard(title: "DragAndDrop activity") {
            SettingsToggleRow(
                title: "DragAndDrop live activity",
                description: "Show file drop targets when you drag files over the notch.",
                systemImage: "tray.and.arrow.down.fill",
                color: .blue,
                isOn: $mediaSettings.isDragAndDropLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.dragAndDrop"
            )

            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            SettingsStrokeToggleRow(
                title: "Default stroke",
                description: "Use the standard white notch stroke instead of the drag-and-drop accent stroke.",
                isOn: $mediaSettings.isDragAndDropDefaultStrokeEnabled,
                accessibilityIdentifier: "settings.activities.live.dragAndDrop.defaultStroke"
            )
            .disabled(isDefaultStrokeLocked)
            .opacity(isDefaultStrokeLocked ? 0.5 : 1)
        }
    }

    private var dragAndDropMode: some View {
        SettingsCard(title: "Drop target") {
            SettingsNotchPreview(
                width: dragAndDropPreviewNotchWidth,
                height: 148,
                previewHeight: 166,
                topCornerRadius: 24,
                bottomCornerRadius: 36,
                backgroundStyle: .black,
                showsStroke: appearanceSettings.isShowNotchStrokeEnabled,
                strokeColor: dragAndDropPreviewStrokeColor,
                strokeWidth: appearanceSettings.notchStrokeWidth,
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) {
                dragAndDropPreviewContent
            }

            Divider()
                .opacity(0.6)

            SettingsMenuRow(
                title: "Target mode",
                description: "Choose which target appears while files are dragged over the notch.",
                options: Array(DragAndDropActivityMode.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.activities.live.dragAndDrop.mode",
                selection: $mediaSettings.dragAndDropActivityMode
            )
        }
    }

    private var dragAndDropPreviewNotchWidth: CGFloat {
        mediaSettings.dragAndDropActivityMode == .combined ? 460 : 280
    }

    @ViewBuilder
    private var dragAndDropPreviewContent: some View {
        VStack {
            Spacer()

            HStack(spacing: AirDropDropZoneMetrics.combinedSpacing) {
                if mediaSettings.dragAndDropActivityMode.showsAirDrop {
                    dragAndDropPreviewTarget(.airDrop)
                }

                if mediaSettings.dragAndDropActivityMode.showsTray {
                    dragAndDropPreviewTarget(.tray)
                }
            }
            .frame(height: AirDropDropZoneMetrics.height)
        }
        .padding(.horizontal, AirDropDropZoneMetrics.horizontalPadding)
        .padding(.vertical, AirDropDropZoneMetrics.verticalPadding)
    }

    private var dragAndDropPreviewStrokeColor: Color {
        guard appearanceSettings.isShowNotchStrokeEnabled else {
            return .clear
        }

        if appearanceSettings.isDefaultActivityStrokeEnabled || mediaSettings.isDragAndDropDefaultStrokeEnabled {
            return .white.opacity(0.2)
        }

        return mediaSettings.dragAndDropActivityMode == .tray ? .white.opacity(0.2) : Color.accentColor.opacity(0.3)
    }

    private func dragAndDropPreviewTarget(_ target: DragAndDropTarget) -> some View {
        DragAndDropDropZoneContent(target: target, isTargeted: false)
            .frame(maxWidth: .infinity)
    }
}
