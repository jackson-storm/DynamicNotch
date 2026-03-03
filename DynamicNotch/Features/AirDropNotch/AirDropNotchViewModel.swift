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
    @Published var isDraggingFile = false
    
    func handleDrop(providers: [NSItemProvider], point: NSPoint) {
        let group = DispatchGroup()
        var urls: [URL] = []
        
        for provider in providers {
            group.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    urls.append(url)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let _ = self else { return }
            if !urls.isEmpty, let view = NSApp.keyWindow?.contentView {
                shareViaAirDrop(urls: urls, point: point, view: view)
            } else if !urls.isEmpty {
                shareViaAirDrop(urls: urls, point: point, view: NSView())
            }
        }
    }
}
