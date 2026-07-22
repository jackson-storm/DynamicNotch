import SwiftUI

struct DragAndDropSettingsView: View {
    @ObservedObject var mediaSettings: MediaAndFilesSettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore

    var body: some View {
        SettingsPageScrollView {
            dragAndDropActivity
            dragAndDropMode
            subPageNavigation
        }
    }

    private var dragAndDropActivity: some View {
        SettingsCard(title: "Drag&Drop activity") {
            SettingsToggleRow(
                title: "Drag&Drop live activity",
                description: "Show AirDrop, Tray, and File Converter targets when you drag files over the notch.",
                systemImage: "tray.and.arrow.down.fill",
                color: .black,
                stroke: true,
                isOn: $mediaSettings.isDragAndDropLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.drop"
            )

            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, alignment: .trailing)

            SettingsToggleRow(
                title: "Tray live activity",
                description: "Show the pinned file tray after files are dropped into Tray.",
                systemImage: "tray.full.fill",
                color: .blue,
                isOn: $mediaSettings.isTrayLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.drop.tray"
            )

            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, alignment: .trailing)

            SettingsToggleRow(
                title: "File Converter live activity",
                description: "Show the File Converter live activity after a file is dropped for conversion.",
                systemImage: "arrow.trianglehead.2.clockwise.rotate.90.circle.fill",
                color: .green,
                isOn: $mediaSettings.isFileConverterLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.drop.fileConverter"
            )
        }
    }

    private var dragAndDropMode: some View {
        SettingsCard(title: "Drag&Drop target") {
            SettingsNotchPreview(
                width: dragAndDropPreviewWidth,
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

            Divider().opacity(0.6)

            SettingsMenuRow(
                title: "Target mode",
                description: "Choose which target appears while files are dragged over the notch.",
                options: Array(DragAndDropActivityMode.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.activities.live.drop.mode",
                selection: $mediaSettings.dragAndDropActivityMode
            )

            Divider().opacity(0.6)

            SettingsMenuRow(
                title: "Target colors",
                description: "Choose how Drag&Drop target zones are colored.",
                options: Array(DragAndDropTargetColorStyle.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.activities.live.drop.targetColors",
                selection: $mediaSettings.dragAndDropTargetColorStyle
            )

            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, alignment: .trailing)

            SettingsToggleRow(
                title: "Motion animation",
                description: "Play animation of cell movement when hovering a file over an area.",
                systemImage: "cursorarrow.motionlines",
                color: .pink,
                isOn: $mediaSettings.isDropMotionAnimationEnabled,
                accessibilityIdentifier: "settings.activities.live.drop.motionAnimation"
            )
        }
    }

    private var subPageNavigation: some View {
        SettingsCard(spacing: 0, padding: 0) {
            SettingsNavigationRowView(
                title: "settings.dragAndDrop.tray.title",
                description: "settings.dragAndDrop.tray.subtitle",
                systemImage: "tray.full.fill",
                color: .blue,
                accessibilityIdentifier: "settings.dragAndDrop.tray",
                position: .first,
                value: SettingsSubPage.fileTray
            )

            SettingsNavigationRowView(
                title: "settings.dragAndDrop.fileConverter.title",
                description: "settings.dragAndDrop.fileConverter.subtitle",
                systemImage: "arrow.trianglehead.2.clockwise.rotate.90.circle.fill",
                color: .green,
                accessibilityIdentifier: "settings.dragAndDrop.fileConverter",
                position: .last,
                value: SettingsSubPage.fileConverter
            )
        }
    }

    @ViewBuilder
    private var dragAndDropPreviewContent: some View {
        VStack {
            Spacer()

            HStack(spacing: AirDropDropZoneMetrics.combinedSpacing) {
                ForEach(mediaSettings.dragAndDropActivityMode.targets, id: \.self) { target in
                    dragAndDropPreviewTarget(target)
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

        let baseColor: Color
        if appearanceSettings.isDefaultActivityStrokeEnabled {
            baseColor = .white.opacity(0.2)
        } else {
            baseColor = dragAndDropPreviewBaseStrokeColor
        }
        return baseColor.opacity(appearanceSettings.notchStrokeOpacity)
    }

    private var dragAndDropPreviewBaseStrokeColor: Color {
        switch mediaSettings.dragAndDropTargetColorStyle {
        case .white:
            return .white.opacity(0.2)

        case .accent:
            return .accentColor.opacity(0.3)

        case .original:
            break
        }

        switch mediaSettings.dragAndDropActivityMode {
        case .tray:
            return DragAndDropTarget.tray.activityStrokeColor(for: .original)

        case .fileConverter:
            return DragAndDropTarget.fileConverter.activityStrokeColor(for: .original)

        case .airDrop:
            return DragAndDropTarget.airDrop.activityStrokeColor(for: .original)

        case .combined:
            return .white.opacity(0.2)
        }
    }

    private var dragAndDropPreviewWidth: CGFloat {
        mediaSettings.dragAndDropActivityMode.targets.count > 1 ? 430 : 280
    }

    private func dragAndDropPreviewTarget(_ target: DragAndDropTarget) -> some View {
        DragAndDropDropZoneContent(
            target: target,
            isTargeted: false,
            targetColorStyle: mediaSettings.dragAndDropTargetColorStyle
        )
            .frame(maxWidth: .infinity)
    }
}
