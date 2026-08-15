import Foundation
import SwiftUI

enum TimerSound: String, CaseIterable, Identifiable {
    case radar
    case alarm
    case apex
    case beacon
    case bulletin
    case byTheSeaside
    case chimes
    case circuit
    case constellation
    case cosmic
    case crystals
    case hillside
    case illuminate
    case nightOwl
    case opening
    case playtime
    case presto
    case radiate
    case reflection
    case ripples
    case sencha
    case signal
    case silk
    case slowRise
    case stargaze
    case summit
    case twinkle
    case uplift
    case waves
    case marimba
    case ping

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .radar: return "Radar"
        case .alarm: return "Alarm"
        case .apex: return "Apex"
        case .beacon: return "Beacon"
        case .bulletin: return "Bulletin"
        case .byTheSeaside: return "By The Seaside"
        case .chimes: return "Chimes"
        case .circuit: return "Circuit"
        case .constellation: return "Constellation"
        case .cosmic: return "Cosmic"
        case .crystals: return "Crystals"
        case .hillside: return "Hillside"
        case .illuminate: return "Illuminate"
        case .nightOwl: return "Night Owl"
        case .opening: return "Opening"
        case .playtime: return "Playtime"
        case .presto: return "Presto"
        case .radiate: return "Radiate"
        case .reflection: return "Reflection"
        case .ripples: return "Ripples"
        case .sencha: return "Sencha"
        case .signal: return "Signal"
        case .silk: return "Silk"
        case .slowRise: return "Slow Rise"
        case .stargaze: return "Stargaze"
        case .summit: return "Summit"
        case .twinkle: return "Twinkle"
        case .uplift: return "Uplift"
        case .waves: return "Waves"
        case .marimba: return "Marimba"
        case .ping: return "Ping"
        }
    }

    var fileName: String {
        switch self {
        case .radar: return "Radar.m4r"
        case .alarm: return "Alarm.m4r"
        case .apex: return "Apex.m4r"
        case .beacon: return "Beacon.m4r"
        case .bulletin: return "Bulletin.m4r"
        case .byTheSeaside: return "By The Seaside.m4r"
        case .chimes: return "Chimes.m4r"
        case .circuit: return "Circuit.m4r"
        case .constellation: return "Constellation.m4r"
        case .cosmic: return "Cosmic.m4r"
        case .crystals: return "Crystals.m4r"
        case .hillside: return "Hillside.m4r"
        case .illuminate: return "Illuminate.m4r"
        case .nightOwl: return "Night Owl.m4r"
        case .opening: return "Opening.m4r"
        case .playtime: return "Playtime.m4r"
        case .presto: return "Presto.m4r"
        case .radiate: return "Radiate.m4r"
        case .reflection: return "Reflection.m4r"
        case .ripples: return "Ripples.m4r"
        case .sencha: return "Sencha.m4r"
        case .signal: return "Signal.m4r"
        case .silk: return "Silk.m4r"
        case .slowRise: return "Slow Rise.m4r"
        case .stargaze: return "Stargaze.m4r"
        case .summit: return "Summit.m4r"
        case .twinkle: return "Twinkle.m4r"
        case .uplift: return "Uplift.m4r"
        case .waves: return "Waves.m4r"
        case .marimba: return "Marimba.m4r"
        case .ping: return "Ping.aiff"
        }
    }

    var fileURL: URL? {
        if self == .ping {
            let systemSounds = [
                "/System/Library/Sounds/Ping.aiff",
                "/System/Library/Sounds/Glass.aiff"
            ]
            for path in systemSounds {
                if FileManager.default.fileExists(atPath: path) {
                    return URL(fileURLWithPath: path)
                }
            }
        }
        let ringtonesBase = "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones"
        let fullPath = "\(ringtonesBase)/\(fileName)"
        if FileManager.default.fileExists(atPath: fullPath) {
            return URL(fileURLWithPath: fullPath)
        }
        return nil
    }

    static func resolved(_ rawValue: String?) -> Self {
        rawValue.flatMap(Self.init(rawValue:)) ?? .radar
    }
}
