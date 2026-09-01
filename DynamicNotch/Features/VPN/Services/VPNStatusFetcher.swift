//
//  VPNStatusFetcher.swift
//  DynamicNotch
//
//  Created by Antigravity on 6/19/26.
//

import Foundation

struct VPNConfiguration: Identifiable, Hashable {
    let id: String
    let name: String
    let isConnected: Bool
    let type: String
    let bundleID: String?
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
    
    nonisolated static func fetchActiveVPNConnectedAt() -> Date? {
        let list = fetchVPNs()
        guard let activeVPN = list.first(where: { $0.isConnected }) else {
            return nil
        }
        return fetchVPNConnectedAt(uuid: activeVPN.id)
    }
    
    nonisolated static func parseLastStatusChangeTime(from output: String) -> Date? {
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("LastStatusChangeTime :") {
                let parts = line.components(separatedBy: "LastStatusChangeTime :")
                if parts.count > 1 {
                    let dateStr = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    return formatter.date(from: dateStr)
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
