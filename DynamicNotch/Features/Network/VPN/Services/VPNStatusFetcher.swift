//
//  VPNStatusFetcher.swift
//  DynamicNotch
//
//  Created by Antigravity on 6/19/26.
//

import Foundation
import SystemConfiguration

struct VPNConfiguration: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let isConnected: Bool
    let type: String
    let bundleID: String?
    var serverAddress: String? = nil
}

enum VPNStatusFetcher {
    nonisolated static func fetchVPNs() -> [VPNConfiguration] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/scutil")
        process.arguments = ["--nc", "list"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            
            if let output = String(data: data, encoding: .utf8) {
                return parseVPNList(from: output)
            }
        } catch {
            print("Failed to run scutil --nc list: \(error)")
        }
        return []
    }
    
    nonisolated static func fetchVPNConnectedAt(uuid: String) -> Date? {
        // First try native SystemConfiguration API to read the exact Date from ExtendedStatus
        if let conn = SCNetworkConnectionCreateWithServiceID(nil, uuid as CFString, { _, _, _ in }, nil),
           let ext = SCNetworkConnectionCopyExtendedStatus(conn) as? [String: Any] {
            if let date = ext["LastStatusChangeTime"] as? Date {
                return date
            }
        }
        
        // Fallback to scutil CLI output
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/scutil")
        process.arguments = ["--nc", "status", uuid]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            
            if let output = String(data: data, encoding: .utf8) {
                return parseLastStatusChangeTime(from: output)
            }
        } catch {
            print("Failed to run scutil --nc status: \(error)")
        }
        return nil
    }
    
    nonisolated static func fetchVPNServerAddress(uuid: String) -> String? {
        // First try native SystemConfiguration API
        if let conn = SCNetworkConnectionCreateWithServiceID(nil, uuid as CFString, { _, _, _ in }, nil),
           let ext = SCNetworkConnectionCopyExtendedStatus(conn) as? [String: Any] {
            if let ipv4 = ext["IPv4"] as? [String: Any],
               let sAddr = ipv4["ServerAddress"] as? String,
               !sAddr.isEmpty {
                return sAddr
            }
            if let vpn = ext["VPN"] as? [String: Any],
               let rAddr = vpn["RemoteAddress"] as? String,
               !rAddr.isEmpty {
                return rAddr
            }
        }
        
        // Fallback to scutil CLI output
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/scutil")
        process.arguments = ["--nc", "status", uuid]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            
            if let output = String(data: data, encoding: .utf8) {
                return parseServerAddress(from: output)
            }
        } catch {
            print("Failed to run scutil --nc status: \(error)")
        }
        return nil
    }
    
    nonisolated static func parseServerAddress(from output: String) -> String? {
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("ServerAddress :") {
                let parts = line.components(separatedBy: "ServerAddress :")
                if parts.count > 1 {
                    let addr = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if !addr.isEmpty { return addr }
                }
            }
            if line.contains("RemoteAddress :") {
                let parts = line.components(separatedBy: "RemoteAddress :")
                if parts.count > 1 {
                    let addr = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if !addr.isEmpty { return addr }
                }
            }
        }
        return nil
    }
    
    nonisolated static func fetchActiveVPNTuple() -> (uuid: String, connectedAt: Date?, serverAddress: String?)? {
        if let store = SCDynamicStoreCreate(nil, "DynamicNotch" as CFString, { _, _, _ in }, nil),
           let globalIPv4 = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString) as? [String: Any],
           let iface = globalIPv4["PrimaryInterface"] as? String,
           let serviceID = globalIPv4["PrimaryService"] as? String,
           (iface.hasPrefix("utun") || iface.hasPrefix("ipsec") || iface.hasPrefix("ppp")) {
            
            var date: Date? = nil
            var server: String? = nil
            
            if let conn = SCNetworkConnectionCreateWithServiceID(nil, serviceID as CFString, { _, _, _ in }, nil),
               let ext = SCNetworkConnectionCopyExtendedStatus(conn) as? [String: Any] {
                date = ext["LastStatusChangeTime"] as? Date
                if let ipv4 = ext["IPv4"] as? [String: Any] {
                    server = ipv4["ServerAddress"] as? String
                } else if let vpn = ext["VPN"] as? [String: Any] {
                    server = vpn["RemoteAddress"] as? String
                }
            }
            return (serviceID, date, server)
        }
        return nil
    }
    
    nonisolated static func fetchActiveVPNConnectedAt() -> Date? {
        // 1. Check dynamic store primary service directly
        if let active = fetchActiveVPNTuple(), let date = active.connectedAt {
            return date
        }
        
        // 2. Fall back to scanning the VPN list
        let list = fetchVPNs()
        guard let activeVPN = list.first(where: { $0.isConnected }) else {
            return nil
        }
        return fetchVPNConnectedAt(uuid: activeVPN.id)
    }
    
    /// `LastStatusChangeTime` comes in one of these forms. One formatter per form, built once and
    /// never mutated afterwards, so parses from concurrent refreshes can share them.
    private nonisolated static let lastStatusChangeTimeFormatters: [DateFormatter] = [
        "MM/dd/yyyy HH:mm:ss",
        "yyyy-MM-dd HH:mm:ss",
        "dd/MM/yyyy HH:mm:ss",
        "MM/dd/yy HH:mm:ss",
        "dd.MM.yyyy HH:mm:ss"
    ].map { format in
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .autoupdatingCurrent
        return formatter
    }

    nonisolated static func parseLastStatusChangeTime(from output: String) -> Date? {
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("LastStatusChangeTime :") {
                let parts = line.components(separatedBy: "LastStatusChangeTime :")
                if parts.count > 1 {
                    let dateStr = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    for formatter in lastStatusChangeTimeFormatters {
                        if let date = formatter.date(from: dateStr) {
                            return date
                        }
                    }
                }
            }
        }
        return nil
    }
    
    nonisolated static func parseVPNList(from output: String) -> [VPNConfiguration] {
        var vpns: [VPNConfiguration] = []
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            guard let uuidRange = line.range(of: "\\b[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\\b", options: .regularExpression) else {
                continue
            }
            let uuid = String(line[uuidRange])
            let isConnected = line.contains("(Connected)")
            
            var name = ""
            if let firstQuote = line.firstIndex(of: "\""),
               let lastQuote = line.lastIndex(of: "\""),
               firstQuote < lastQuote {
                let nextIndex = line.index(after: firstQuote)
                let parsedName = String(line[nextIndex..<lastQuote]).trimmingCharacters(in: .whitespacesAndNewlines)
                name = parsedName.isEmpty ? uuid : parsedName
            } else {
                name = uuid
            }
            
            var type = "VPN"
            if let firstQuote = line.firstIndex(of: "\""), uuidRange.upperBound < firstQuote {
                let typeStr = line[uuidRange.upperBound..<firstQuote].trimmingCharacters(in: .whitespacesAndNewlines)
                if !typeStr.isEmpty {
                    type = typeStr
                }
            }
            
            // Extract bundle ID if present (e.g. inside parentheses in the type after UUID)
            var bundleID: String? = nil
            let substringAfterUUID = String(line[uuidRange.upperBound...])
            if let openParen = substringAfterUUID.firstIndex(of: "("),
               let closeParen = substringAfterUUID.firstIndex(of: ")"),
               openParen < closeParen {
                let content = String(substringAfterUUID[substringAfterUUID.index(after: openParen)..<closeParen]).trimmingCharacters(in: .whitespacesAndNewlines)
                if content.contains(".") {
                    bundleID = content
                }
            }
            
            vpns.append(VPNConfiguration(id: uuid, name: name, isConnected: isConnected, type: type, bundleID: bundleID))
        }
        return vpns
    }
}
