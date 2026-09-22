import Foundation

/// Serves canned responses so tests never hit the network.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    struct Response {
        var status = 200
        var json = "{}"
    }

    nonisolated(unsafe) static var handler: ((URLRequest) -> Response)?
    nonisolated(unsafe) static var requests: [URLRequest] = []

    static func session(_ handler: @escaping (URLRequest) -> Response) -> URLSession {
        self.handler = handler
        requests = []
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requests.append(request)
        let response = Self.handler?(request) ?? Response(status: 500)
        let http = HTTPURLResponse(url: request.url!, statusCode: response.status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(response.json.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
