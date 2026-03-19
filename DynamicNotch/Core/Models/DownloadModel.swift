//
//  DownloadModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/19/26.
//

import Foundation

struct DownloadModel: Equatable, Identifiable {
    let url: URL
    let displayName: String
    let directoryName: String
    let byteCount: Int64
    let progress: Double
    let startedAt: Date
    let lastUpdatedAt: Date
    let isTemporaryFile: Bool

    var id: String {
        url.standardizedFileURL.path
    }
}
