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
        SettingsCard(title: "settings.drop.card.activity") {
            SettingsToggleRow(
                title: "settings.drop.dragAndDrop.title",
                description: "settings.drop.dragAndDrop.desc",
                systemImage: "tray.and.arrow.down.fill",
                color: .gray,
                stroke: true,
                isOn: $mediaSettings.isDragAndDropLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.drop"
            )

            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, alignment: .trailing)

            SettingsToggleRow(
                title: "settings.drop.airDrop.title",
                description: "settings.drop.airDrop.desc",
                imageName: "airdrop.white",
                color: .blue,
                isOn: $mediaSettings.isAirDropLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.drop.airdrop"
            )

            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, alignment: .trailing)

            SettingsToggleRow(
                title: "settings.drop.trayActivity.title",
                description: "settings.drop.trayActivity.desc",
                systemImage: "tray.full.fill",
                color: .black,
                stroke: true,
                isOn: $mediaSettings.isTrayLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.drop.tray"
            )
        }
    }

    private var dragAndDropMode: some View {
        SettingsCard(title: "settings.drop.card.target") {
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
                title: "settings.drop.targetMode.title",
                description: "settings.drop.targetMode.desc",
                options: Array(DragAndDropActivityMode.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.activities.live.drop.mode",
                selection: $mediaSettings.dragAndDropActivityMode
            )
        }
    }

    private var subPageNavigation: some View {
        SettingsCard(spacing: 0, padding: 0) {
            SettingsNavigationRowView(
                title: "settings.drop.tray.title",
                description: "settings.drop.tray.subtitle",
                systemImage: "tray.full.fill",
                color: .black,
                stroke: true,
                accessibilityIdentifier: "settings.dragAndDrop.tray",
                position: .single,
                value: SettingsSubPage.fileTray
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
        switch mediaSettings.dragAndDropActivityMode {
        case .tray:
            return DragAndDropTarget.tray.activityStrokeColor

        case .airDrop:
            return DragAndDropTarget.airDrop.activityStrokeColor

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
            isTargeted: false
        )
            .frame(maxWidth: .infinity)
    }
}
