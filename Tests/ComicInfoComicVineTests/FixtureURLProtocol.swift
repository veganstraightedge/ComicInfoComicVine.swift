import Foundation

/// Answers Comic Vine API requests with the recorded responses in `Fixtures/`, as Comic Vine would.
///
/// A request without the test key gets Comic Vine's "Invalid API Key" response, and one without the
/// test User-Agent is refused, so a passing test shows both are sent.
final class FixtureURLProtocol: URLProtocol, @unchecked Sendable {
  static let apiKey = "test-key"
  static let userAgent = "ComicInfoComicVineTests/1.0"

  /// The fixture file each API path is answered with.
  private static let files = [
    "/api/issue/4000-140529/": "issue_detail",
    "/api/issues/": "issues_list",
    "/api/search/": "search_volumes",
    "/api/volume/4050-23437/": "volume_detail",
    "/api/volumes/": "volumes_list",
  ]

  /// A URL session whose requests are all answered here.
  static var session: URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [FixtureURLProtocol.self]
    return URLSession(configuration: configuration)
  }

  override class func canInit(with request: URLRequest) -> Bool { true }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    let (status, file) = answer()
    let body = file.flatMap(Self.fixture) ?? Data()
    let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: body)
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}

  private func answer() -> (status: Int, file: String?) {
    guard let url = request.url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      return (400, nil)
    }
    guard request.value(forHTTPHeaderField: "User-Agent") == Self.userAgent else { return (403, nil) }

    let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
    guard query["format"] == "json", query["api_key"] == Self.apiKey else { return (200, "invalid_key") }
    guard let file = Self.files[components.path] else { return (404, nil) }
    return (200, file)
  }

  private static func fixture(_ name: String) -> Data? {
    guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") else {
      return nil
    }
    return try? Data(contentsOf: url)
  }
}
