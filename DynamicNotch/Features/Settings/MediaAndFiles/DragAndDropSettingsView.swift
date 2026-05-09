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
            trayAppearance
        }
    }

    private var dragAndDropActivity: some View {
        SettingsCard(title: "Drag&Drop activity") {
            SettingsToggleRow(
                title: "Drag&Drop live activity",
                description: "Show AirDrop, Tray, and File Converter targets when you drag files over the notch.",
                systemImage: "tray.and.arrow.down.fill",
                color: .blue,
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
                color: .black,
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

            Divider().opacity(0.6)

            SettingsStrokeToggleRow(
                title: "Default stroke",
                description: "Use the standard white notch stroke instead of the Drag&Drop accent stroke.",
                isOn: $mediaSettings.isDragAndDropDefaultStrokeEnabled,
                accessibilityIdentifier: "settings.activities.live.drop.defaultStroke"
            )
            .disabled(isDefaultStrokeLocked)
            .opacity(isDefaultStrokeLocked ? 0.5 : 1)

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

    private var trayAppearance: some View {
        SettingsCard(title: "Tray appearance") {
            SettingsNotchPreview(
                width: 430,
                height: 148,
                previewHeight: 166,
                topCornerRadius: 24,
                bottomCornerRadius: 36,
                backgroundStyle: .black,
                showsStroke: appearanceSettings.isShowNotchStrokeEnabled,
                strokeColor: .white.opacity(0.2),
                strokeWidth: appearanceSettings.notchStrokeWidth,
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) {
                trayAppearancePreviewContent
            }

            Divider()
                .opacity(0.6)

            SettingsMenuRow(
                title: "Scroll direction",
                description: "Choose how files scroll inside the expanded Tray.",
                options: Array(FileTrayScrollDirection.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.activities.live.drop.trayScrollDirection",
                selection: $mediaSettings.fileTrayScrollDirection
            )

            Divider()
                .opacity(0.6)

            SettingsMenuRow(
                title: "Tray usage",
                description: "Choose whether Tray keeps file copies or moves originals into Tray storage.",
                options: Array(FileTrayUsageMode.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.activities.live.drop.trayUsage",
                selection: $mediaSettings.fileTrayUsageMode
            )

            if mediaSettings.fileTrayUsageMode == .moveOriginals {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.yellow)

                    Text("If the original is moved to the tray and deleted from there, you can restore it in the system trash.")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.secondary)
                }
            }

            Divider()
                .opacity(0.6)

            SettingsToggleRow(
                title: "Hide remove button",
                description: "Hide the x button on file cards in the expanded Tray.",
                systemImage: "xmark.circle.fill",
                color: .red,
                isOn: $mediaSettings.isFileTrayRemoveButtonHidden,
                accessibilityIdentifier: "settings.activities.live.drop.tray.hideRemoveButton"
            )
        }
    }

    @ViewBuilder
    private var trayAppearancePreviewContent: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 5) {
                HStack(spacing: 5) {
                    Image(systemName: "tray.full.fill")
                        .font(.system(size: 18))
                    AnimatedLevelText(level: trayPreviewItems.count, fontSize: 14)
                }
                .frame(width: 60, height: 30)

                Spacer()

                HStack(spacing: 5) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                    Text("All")
                        .font(.system(size: 14))
                }
                .frame(width: 60, height: 30)
            }
            .foregroundStyle(.white)

            Spacer()

            HStack(spacing: 10) {
                ForEach(trayPreviewItems) { item in
                    TrayAppearancePreviewItemView(
                        item: item,
                        showsRemoveButton: !mediaSettings.isFileTrayRemoveButtonHidden
                    )
                }
            }
        }
        .padding(.bottom, 15)
        .padding(.horizontal, 40)
        .padding(.top, 5)
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

        if appearanceSettings.isDefaultActivityStrokeEnabled || mediaSettings.isDragAndDropDefaultStrokeEnabled {
            return .white.opacity(0.2)
        }

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

    private var trayPreviewItems: [TrayAppearancePreviewItem] {
        [
            TrayAppearancePreviewItem(name: "Report.pdf", systemImage: "doc.richtext.fill", color: .red),
            TrayAppearancePreviewItem(name: "Photo.png", systemImage: "photo.fill", color: .indigo),
            TrayAppearancePreviewItem(name: "Designs", systemImage: "folder.fill", color: .accentColor),
            TrayAppearancePreviewItem(name: "Installer", systemImage: "opticaldiscdrive.fill", color: .white.opacity(0.8))
        ]
    }

    private struct TrayAppearancePreviewItem: Identifiable {
        let name: String
        let systemImage: String
        let color: Color

        var id: String { name }
    }

    private struct TrayAppearancePreviewItemView: View {
        let item: TrayAppearancePreviewItem
        let showsRemoveButton: Bool

        var body: some View {
            VStack(spacing: 7) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 34, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(item.color)
                    .frame(width: 55, height: 47)
                    .padding(.top, 4)

                Text(item.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 72, height: 28)
            }
            .frame(width: 80, height: 94)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.1))
            )
            .overlay(alignment: .topTrailing) {
                if showsRemoveButton {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.58))
                        .background(Circle().fill(.black.opacity(0.28)))
                        .padding(.top, 5)
                        .padding(.trailing, 5)
                }
            }
        }
    }
}
