//
//  AirDropTransferInfo.swift
//  DynamicNotch
//

import Foundation

enum AirDropTransferStatus: Equatable {
    case transferring
    case completed
    case failed(String)
}

struct AirDropTransferInfo: Equatable, Identifiable {
    let id: UUID
    let urls: [URL]
    var status: AirDropTransferStatus
    var progress: Double = 0.0

    var percentage: Int {
        Int((max(0.0, min(1.0, progress)) * 100).rounded())
    }

    var fileName: String {
        if urls.count == 1, let first = urls.first {
            return first.lastPathComponent
        }
        return "\(urls.count) items"
    }

    var fileURL: URL? {
        urls.first
    }
}
