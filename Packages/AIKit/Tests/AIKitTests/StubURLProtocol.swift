import Foundation

/// Serves canned responses so tests never hit the network.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    struct Response {
        var status = 200
        var json = "{}"
    }

    nonisolated(unsafe) static var handler: ((URLRequest) -> Response)?
    nonisolated(unsafe) static var requests: [URLRequest] = []
    /// JSON bodies of POSTed requests (URLProtocol only sees them as streams).
    nonisolated(unsafe) static var bodies: [[String: Any]] = []

    static func session(_ handler: @escaping (URLRequest) -> Response) -> URLSession {
        self.handler = handler
        requests = []
        bodies = []
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requests.append(request)
        if let data = request.httpBody ?? request.httpBodyStream.map(Self.readAll),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            Self.bodies.append(json)
        }
        let response = Self.handler?(request) ?? Response(status: 500)
        let http = HTTPURLResponse(url: request.url!, statusCode: response.status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(response.json.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func readAll(_ stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}
