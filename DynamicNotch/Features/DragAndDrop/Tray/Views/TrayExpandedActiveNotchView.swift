//
//  TrayExpandedActiveNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/26/26.
//

import SwiftUI
internal import AppKit

struct TrayExpandedActiveNotchView: View {
    @Environment(\.notchScale) private var scale
    @ObservedObject var fileTrayViewModel: FileTrayViewModel
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                header
                Spacer()
            }
            .padding(.top, 4.scaled(by: scale))
            .padding(.horizontal, 42)
            
            VStack(alignment: .leading) {
                Spacer()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(fileTrayViewModel.items) { item in
                            let isSelected = fileTrayViewModel.selectedItemIDs.contains(item.id)

                            TrayExpandedItemView(
                                item: item,
                                isSelected: isSelected,
                                draggedItems: {
                                    fileTrayViewModel.itemsForDrag(startingAt: item)
                                },
                                onSelect: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        fileTrayViewModel.toggleSelection(for: item)
                                    }
                                },
                                onRemove: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        fileTrayViewModel.remove(item)
                                    }
                                }
                            )
                            .transition(
                                .blurAndFade
                                    .combined(with: .scale)
                                    .combined(with: .opacity)
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.02),
                            .init(color: .black, location: 0.98),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            }
            .padding(.horizontal, 34)
            .padding(.bottom, 14)
        }
    }
    
    private var header: some View {
        HStack(spacing: 5) {
            Button {
                guard fileTrayViewModel.hasSelection else { return }

                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    fileTrayViewModel.clearSelection()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "tray.full.fill")
                        .font(.system(size: 18))
                    AnimatedLevelText(level: fileTrayViewModel.count, fontSize: 14)
                }
            }
            .buttonStyle(PressedButtonStyle(width: 60, height: 30))
            
            Spacer()
            
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    if fileTrayViewModel.hasSelection {
                        fileTrayViewModel.removeSelectedItems()
                    } else {
                        fileTrayViewModel.clear()
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                    if fileTrayViewModel.hasSelection {
                        AnimatedLevelText(level: fileTrayViewModel.selectedCount, fontSize: 14)
                    } else {
                        Text("All")
                            .font(.system(size: 14))
                    }
                }
            }
            .buttonStyle(PressedButtonStyle(width: 60, height: 30))
        }
        .foregroundStyle(.white)
    }
}

private struct TrayExpandedItemView: View {
    let item: FileTrayItem
    let isSelected: Bool
    let draggedItems: () -> [FileTrayItem]
    let onSelect: () -> Void
    let onRemove: () -> Void

    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 7) {
            Image(nsImage: item.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
                .padding(.top, 4)
                .frame(width: 55, height: 47)
            
            Text(item.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.86))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 72, height: 28)
        }
        .frame(width: 80, height: 94)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.4) : .white.opacity(0.1))
        )
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            TrayExpandedItemDragView(
                draggedItems: draggedItems,
                onSelect: onSelect,
                onPressedChange: { isPressed in
                    self.isPressed = isPressed
                }
            )
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .background(Circle().fill(.black.opacity(0.28)))
            }
            .buttonStyle(PressedButtonStyle(width: 18, height: 18))
            .padding(.top, 5)
            .padding(.trailing, 5)
        }
        .scaleEffect(isPressed ? 0.9 : 1)
        .animation(.spring(response: 0.22, dampingFraction: 0.58), value: isPressed)
        .help(item.url.path)
    }
}

private struct TrayExpandedItemDragView: NSViewRepresentable {
    let draggedItems: () -> [FileTrayItem]
    let onSelect: () -> Void
    let onPressedChange: (Bool) -> Void

    func makeNSView(context: Context) -> TrayExpandedItemDragNSView {
        let view = TrayExpandedItemDragNSView()
        view.draggedItems = draggedItems
        view.onSelect = onSelect
        view.onPressedChange = onPressedChange
        return view
    }

    func updateNSView(_ nsView: TrayExpandedItemDragNSView, context: Context) {
        nsView.draggedItems = draggedItems
        nsView.onSelect = onSelect
        nsView.onPressedChange = onPressedChange
    }
}

private final class TrayExpandedItemDragNSView: NSView, NSDraggingSource {
    var draggedItems: () -> [FileTrayItem] = { [] }
    var onSelect: () -> Void = {}
    var onPressedChange: (Bool) -> Void = { _ in }

    private var mouseDownEvent: NSEvent?
    private var didBeginDragging = false

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        if closeButtonHitRect.contains(point) {
            return nil
        }

        return super.hitTest(point)
    }

    override func mouseDown(with event: NSEvent) {
        mouseDownEvent = event
        didBeginDragging = false
        onPressedChange(true)
    }

    override func mouseDragged(with event: NSEvent) {
        guard didBeginDragging == false,
              let mouseDownEvent else {
            return
        }

        let startPoint = convert(mouseDownEvent.locationInWindow, from: nil)
        let currentPoint = convert(event.locationInWindow, from: nil)
        let distance = hypot(currentPoint.x - startPoint.x, currentPoint.y - startPoint.y)

        guard distance >= 3 else {
            return
        }

        didBeginDragging = true
        onPressedChange(false)
        beginDragging(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        onPressedChange(false)

        if didBeginDragging == false {
            onSelect()
        }

        mouseDownEvent = nil
        didBeginDragging = false
    }

    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        .copy
    }

    func ignoreModifierKeys(for session: NSDraggingSession) -> Bool {
        true
    }

    private func beginDragging(with event: NSEvent) {
        let items = draggedItems()
        guard items.isEmpty == false else {
            return
        }

        let point = convert(event.locationInWindow, from: nil)
        let draggingItems = items.enumerated().map { index, item in
            makeDraggingItem(for: item, index: index, at: point)
        }

        beginDraggingSession(with: draggingItems, event: event, source: self)
        mouseDownEvent = nil
    }

    private func makeDraggingItem(
        for item: FileTrayItem,
        index: Int,
        at point: NSPoint
    ) -> NSDraggingItem {
        let dragSize = NSSize(width: 48, height: 48)
        let offset = CGFloat(min(index, 4)) * 4
        let frame = NSRect(
            x: point.x - (dragSize.width / 2) + offset,
            y: point.y - (dragSize.height / 2) - offset,
            width: dragSize.width,
            height: dragSize.height
        )
        let draggingItem = NSDraggingItem(
            pasteboardWriter: FileTrayPasteboardWriter(url: item.url)
        )

        draggingItem.setDraggingFrame(frame, contents: dragImage(for: item, size: dragSize))
        return draggingItem
    }

    private func dragImage(for item: FileTrayItem, size: NSSize) -> NSImage {
        let image = (item.icon.copy() as? NSImage) ?? item.icon
        image.size = size
        return image
    }

    private var closeButtonHitRect: NSRect {
        NSRect(
            x: bounds.maxX - 30,
            y: bounds.maxY - 30,
            width: 30,
            height: 30
        )
    }
}
