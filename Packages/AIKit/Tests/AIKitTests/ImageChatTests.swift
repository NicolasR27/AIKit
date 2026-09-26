import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import AIKit

// Nested in NetworkTests for `.serialized`, like ChatTests.
extension NetworkTests {
@MainActor
@Suite struct ImageChatTests {
    /// A 4000×3000 PNG, so the tests also cover downscaling and PNG → JPEG conversion.
    private static let photo: Data = {
        let context = CGContext(data: nil, width: 4000, height: 3000, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: 4000, height: 3000))
        let output = NSMutableData()
        let destination = CGImageDestinationCreateWithData(output, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, context.makeImage()!, nil)
        CGImageDestinationFinalize(destination)
        return output as Data
    }()

    private func credentials(_ provider: AIProvider) -> AIProviderCredentials {
        AIProviderCredentials(provider: provider, model: "m", apiKey: "key", baseURL: provider.defaultAPIBaseURL)
    }

    @Test func imagesAreSentAsDownscaledJPEG() throws {
        let base64 = try ImageEncoding.jpegBase64(from: Self.photo)
        let jpeg = try #require(Data(base64Encoded: base64))
        #expect(jpeg.starts(with: [0xFF, 0xD8]))
        let image = try ImageEncoding.cgImage(from: jpeg)
        #expect(max(image.width, image.height) == ImageEncoding.maxPixelSize)
    }

    @Test func unreadableImageThrows() {
        #expect(throws: ProviderError.self) { try ImageEncoding.jpegBase64(from: Data("not an image".utf8)) }
    }

    @Test(arguments: [AIProvider.openAI, .mistral, .openRouter])
    func openAICompatibleSendsImageParts(provider: AIProvider) async throws {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"{"choices":[{"message":{"role":"assistant","content":"A Casio"}}]}"#)
        })

        let reply = try await client.chat([.user("What watch?", images: [Self.photo])], system: nil,
                                          credentials: credentials(provider), model: "m")

        #expect(reply == "A Casio")
        let messages = try #require(StubURLProtocol.bodies.first?["messages"] as? [[String: Any]])
        let parts = try #require(messages.first?["content"] as? [[String: Any]])
        #expect(parts.map { $0["type"] as? String } == ["image_url", "text"])
        let url = (parts.first?["image_url"] as? [String: String])?["url"]
        #expect(url?.hasPrefix("data:image/jpeg;base64,") == true)
        #expect(parts.last?["text"] as? String == "What watch?")
    }

    @Test func anthropicSendsBase64ImageBlock() async throws {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"{"content":[{"type":"text","text":"A Casio"}]}"#)
        })

        _ = try await client.chat([.user("What watch?", images: [Self.photo])], system: nil,
                                  credentials: credentials(.anthropic), model: "m")

        let messages = try #require(StubURLProtocol.bodies.first?["messages"] as? [[String: Any]])
        let blocks = try #require(messages.first?["content"] as? [[String: Any]])
        #expect(blocks.map { $0["type"] as? String } == ["image", "text"])
        let source = try #require(blocks.first?["source"] as? [String: String])
        #expect(source["type"] == "base64")
        #expect(source["media_type"] == "image/jpeg")
        #expect(source["data"]?.isEmpty == false)
    }

    @Test func geminiSendsInlineData() async throws {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"{"candidates":[{"content":{"role":"model","parts":[{"text":"A Casio"}]}}]}"#)
        })

        _ = try await client.chat([.user("What watch?", images: [Self.photo])], system: nil,
                                  credentials: credentials(.gemini), model: "m")

        let contents = try #require(StubURLProtocol.bodies.first?["contents"] as? [[String: Any]])
        let parts = try #require(contents.first?["parts"] as? [[String: Any]])
        let inline = try #require(parts.first?["inlineData"] as? [String: String])
        #expect(inline["mimeType"] == "image/jpeg")
        #expect(parts.last?["text"] as? String == "What watch?")
    }

    @Test func ollamaSendsImagesArray() async throws {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"{"message":{"role":"assistant","content":"A Casio"}}"#)
        })
        let local = AIProviderCredentials(provider: .ollama, model: "llava", apiKey: nil,
                                          baseURL: URL(string: "http://localhost:11434"))

        _ = try await client.chat([.user("What watch?", images: [Self.photo])], system: "Be brief",
                                  credentials: local, model: "llava")

        let messages = try #require(StubURLProtocol.bodies.first?["messages"] as? [[String: Any]])
        #expect(messages.first?["images"] == nil)
        #expect((messages.last?["images"] as? [String])?.count == 1)
    }

    @Test func oldSavedMessagesWithoutImagesStillDecode() throws {
        let message = try JSONDecoder().decode(AIMessage.self, from: Data(#"{"role":"user","content":"Hi"}"#.utf8))
        #expect(message == .user("Hi"))
    }
}
}
