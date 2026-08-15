import SwiftUI

struct NotchContextMenu: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        let locale = settingsViewModel.application.appLanguage.locale
        
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
        
        Button(action: { NSApp.terminate(nil) }) {
            Image(systemName: "rectangle.portrait.and.arrow.right")
            Text(locale.dn("menuBar.quit", fallback: "Quit"))
        }
    }
}
