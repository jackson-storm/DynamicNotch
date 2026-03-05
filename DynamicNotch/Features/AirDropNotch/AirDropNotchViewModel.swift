//
//  AirDropNotchViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/3/26.
//

import Combine
import AppKit
internal import UniformTypeIdentifiers

final class AirDropNotchViewModel: ObservableObject {
    @Published var event: AirDropEvent?
    
    @Published var isDraggingFile = false {
        didSet {
            if isDraggingFile {
                event = .dragStarted
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if !self.isDraggingFile {
                        self.event = .dragEnded
                    }
                }
            }
        }
    }
    
    func shareViaAirDrop(urls: [URL], point: NSPoint, view: NSView) {
        let sharingService = NSSharingService(named: .sendViaAirDrop)
        sharingService?.delegate = nil
        sharingService?.perform(withItems: urls)
    }

    func handleDrop(providers: [NSItemProvider], point: NSPoint) {
        let group = DispatchGroup()
        var urls: [URL] = []
        
        for provider in providers {
            group.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url { urls.append(url) }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if !urls.isEmpty {
                self.event = .dropped(urls: urls, point: point)
            }
        }
    }
}
