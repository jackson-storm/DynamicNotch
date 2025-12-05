import AppKit
import CoreGraphics

extension CGImage {
    func averageColor(downsampleWidth: Int = 8, downsampleHeight: Int = 8) -> NSColor? {
        let w = downsampleWidth
        let h = downsampleHeight

        guard let ctx = CGContext(
            data: nil,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.interpolationQuality = .low
        ctx.draw(self, in: CGRect(x: 0, y: 0, width: w, height: h))

        guard let data = ctx.data else { return nil }
        let ptr = data.bindMemory(to: UInt8.self, capacity: w * h * 4)

        var r = 0, g = 0, b = 0
        for i in stride(from: 0, to: w * h * 4, by: 4) {
            r += Int(ptr[i])
            g += Int(ptr[i + 1])
            b += Int(ptr[i + 2])
        }
        let count = w * h
        if count == 0 { return nil }
        return NSColor(
            red: CGFloat(r) / CGFloat(count) / 255.0,
            green: CGFloat(g) / CGFloat(count) / 255.0,
            blue: CGFloat(b) / CGFloat(count) / 255.0,
            alpha: 1.0
        )
    }
}
