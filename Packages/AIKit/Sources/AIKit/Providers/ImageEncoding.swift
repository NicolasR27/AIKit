import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Turns whatever image bytes the app hands us (HEIC from Photos, PNG, huge JPEGs) into
/// something every provider accepts: an upright JPEG no larger than `maxPixelSize` on its long edge.
nonisolated enum ImageEncoding {
    /// Big enough to read a watch dial or a receipt, small enough to stay under every provider's size limit.
    static let maxPixelSize = 1568

    static func cgImage(from data: Data) throws -> CGImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                  kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceCreateThumbnailWithTransform: true,
                  kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
              ] as CFDictionary)
        else { throw ProviderError.unreadableImage }
        return image
    }

    static func jpegBase64(from data: Data) throws -> String {
        let image = try cgImage(from: data)
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil)
        else { throw ProviderError.unreadableImage }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw ProviderError.unreadableImage }
        return (output as Data).base64EncodedString()
    }
}
