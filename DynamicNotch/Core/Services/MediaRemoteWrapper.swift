//
//  MediaRemoteWrapper.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/16/26.
//

import Foundation
import Cocoa

typealias GetNowPlayingApplicationFunction = @convention(c) (DispatchQueue, @escaping (String?) -> Void) -> Void
typealias RegisterNotificationsFunction = @convention(c) (DispatchQueue) -> Void
typealias GetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping (CFDictionary?) -> Void) -> Void

struct MediaRemote {
    private static var handle: UnsafeMutableRawPointer?
    static var getNowPlayingApp: GetNowPlayingApplicationFunction?
    static var registerForNotifications: RegisterNotificationsFunction?
    static var getNowPlayingInfo: GetNowPlayingInfoFunction?

    static func load() {
        let path = "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote"
        handle = dlopen(path, RTLD_NOW)
        if let handle = handle {
            getNowPlayingApp = unsafeBitCast(dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationDisplayID"), to: GetNowPlayingApplicationFunction.self)
            registerForNotifications = unsafeBitCast(dlsym(handle, "MRMediaRemoteRegisterForNowPlayingNotifications"), to: RegisterNotificationsFunction.self)
            getNowPlayingInfo = unsafeBitCast(dlsym(handle, "MRMediaRemoteGetNowPlayingInfo"), to: GetNowPlayingInfoFunction.self)
            print("MediaRemote успешно загружен")
        }
    }
}

let kMRMediaRemoteNowPlayingInfoTitle = "kMRMediaRemoteNowPlayingInfoTitle"
let kMRMediaRemoteNowPlayingInfoArtist = "kMRMediaRemoteNowPlayingInfoArtist"
let kMRMediaRemoteNowPlayingInfoArtworkData = "kMRMediaRemoteNowPlayingInfoArtworkData"
let kMRMediaRemoteNowPlayingInfoDuration = "kMRMediaRemoteNowPlayingInfoDuration"
let kMRMediaRemoteNowPlayingInfoElapsedTime = "kMRMediaRemoteNowPlayingInfoElapsedTime"
let kMRMediaRemoteNowPlayingInfoPlaybackRate = "kMRMediaRemoteNowPlayingInfoPlaybackRate"
