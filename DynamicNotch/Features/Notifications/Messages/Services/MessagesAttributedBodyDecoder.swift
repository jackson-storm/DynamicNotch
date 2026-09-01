import Foundation
import OSLog

struct MessagesAttributedBodyDecoder {

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "DynamicNotch", category: "MessagesAttributedBodyDecoder")

    func decode(text: String?, attributedBody: Data?) -> String? {
        if let text = normalized(text) {
            return text
        }

        guard let attributedBody, !attributedBody.isEmpty else { return nil }

        if let attributedString = decodeKeyedArchive(attributedBody) {
            return normalized(attributedString.string)
        }

        if let text = decodeTypedStream(attributedBody) {
            return text
        }

        logger.debug("Could not decode Messages attributed body")

        return nil
    }

    private func decodeKeyedArchive(_ data: Data) -> NSAttributedString? {
        try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: data)
    }

    private func decodeTypedStream(_ data: Data) -> String? {
        let bytes = [UInt8](data)
        let signature = Array("streamtyped".utf8)

        guard index(of: signature, in: bytes, from: 0) != nil else { return nil }

        let markers = [
            Array("NSString".utf8),
            Array("NSMutableString".utf8)
        ]

        for marker in markers {
            var searchIndex = 0

            while let markerIndex = index(of: marker, in: bytes, from: searchIndex) {
                let markerEndIndex = markerIndex + marker.count
                let payloadSearchEndIndex = min(markerEndIndex + 64, bytes.count)

                if let valueMarkerIndex = bytes[markerEndIndex..<payloadSearchEndIndex].firstIndex(of: 0x2B),
                   let payload = stringPayload(in: bytes, after: valueMarkerIndex),
                   let text = normalized(payload) {
                    return text
                }

                searchIndex = markerEndIndex
            }
        }

        return nil
    }

    private func stringPayload(in bytes: [UInt8], after markerIndex: Int) -> String? {
        guard let lengthValue = stringLength(in: bytes, at: markerIndex + 1) else { return nil }
        guard lengthValue.length <= bytes.count - lengthValue.startIndex else { return nil }

        let endIndex = lengthValue.startIndex + lengthValue.length

        return String(bytes: bytes[lengthValue.startIndex..<endIndex], encoding: .utf8)
    }

    private func stringLength(in bytes: [UInt8], at index: Int) -> (length: Int, startIndex: Int)? {
        guard index < bytes.count else { return nil }

        let marker = bytes[index]

        if marker <= 0x7F {
            return (Int(marker), index + 1)
        }

        let width: Int

        switch marker {
        case 0x81:
            width = 2
        case 0x82:
            width = 4
        case 0x83:
            width = 8
        default:
            return nil
        }

        let startIndex = index + 1

        guard width <= bytes.count - startIndex else { return nil }

        var length: UInt64 = 0

        for offset in 0..<width {
            length |= UInt64(bytes[startIndex + offset]) << (offset * 8)
        }

        guard length <= UInt64(Int.max) else { return nil }

        return (Int(length), startIndex + width)
    }

    private func index(of marker: [UInt8], in bytes: [UInt8], from startIndex: Int) -> Int? {
        guard !marker.isEmpty, bytes.count >= marker.count else { return nil }

        let lastIndex = bytes.count - marker.count

        guard startIndex <= lastIndex else { return nil }

        for index in startIndex...lastIndex {
            if bytes[index..<(index + marker.count)].elementsEqual(marker) {
                return index
            }
        }

        return nil
    }

    private func normalized(_ text: String?) -> String? {
        guard let text else { return nil }

        let normalizedText = text
            .replacingOccurrences(of: "\u{FFFC}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return normalizedText.isEmpty ? nil : normalizedText
    }
}
