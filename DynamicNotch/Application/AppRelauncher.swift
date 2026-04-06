//
//  AppRelauncher.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/5/26.
//

internal import AppKit

enum AppRelauncher {
    
    @MainActor
    static func restartApp() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [
            "-c",
                """
                sleep 0.5
                open -n "$1"
                """,
            "sh",
            Bundle.main.bundlePath
        ]
        
        do {
            try process.run()
            NSApp.terminate(nil)
        } catch {
            return
        }
    }
}
