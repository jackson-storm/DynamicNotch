import AppKit

extension NSColor {
    var isDark: Bool {
        guard let rgb = self.usingColorSpace(.deviceRGB) else { return false }
        let luminance = 0.2126 * rgb.redComponent + 0.7152 * rgb.greenComponent + 0.0722 * rgb.blueComponent
        return luminance < 0.5
    }
}
