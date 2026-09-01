//
//  MenuBarMenu.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 9/1/26.
//

import SwiftUI

struct MenuBarMenu: View {
    @ObservedObject private var updater = SparkleUpdater.shared
    @AppStorage(GeneralSettingsStorage.Keys.appLanguage) private var appLanguageRaw: String = DynamicNotchLanguage.system.rawValue

    private var locale: Locale {
        DynamicNotchLanguage.resolved(appLanguageRaw).locale
    }

    private var localizedVersionText: String {
        locale.dnFormat(
            "menuBar.version",
            fallback: "Version: %@",
            AppVersionText.appVersionText
        )
    }
    
    var body: some View {
        Group {
            Text(verbatim: localizedVersionText)
            
            Divider()
            
            Button {
                updater.checkForUpdates()
            } label: {
                Image(systemName: "arrow.down.circle")
                Text(locale.dn("menuBar.checkForUpdates", fallback: "Check for Updates"))
            }
            .disabled(!updater.canCheckForUpdates)
            
            Button {
                SettingsWindowController.shared.showWindow()
            } label: {
                Image(systemName: "gearshape")
                Text(locale.dn("menuBar.settings", fallback: "Settings"))
            }
            
            Divider()
            
            Button(action: { AppRelauncher.restartApp() }) {
                Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90")
                Text(locale.dn("menuBar.restart", fallback: "Restart"))
            }
            
            Button(action: { NSApplication.shared.terminate(nil) }) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text(locale.dn("menuBar.quit", fallback: "Quit"))
            }
        }
    }
}
