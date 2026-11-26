//
// Client.swift
// ComicInfoComicVine
//

import Foundation

/// Calls the Comic Vine API with one API key.
struct Client: Sendable {
  static let baseURL = URL(string: "https://comicvine.gamespot.com/api/")!

  /// The fields asked for whenever a volume is read.
  private static let volumeFields = "count_of_issues,id,name,publisher,site_detail_url,start_year"

  /// The most volumes one list request returns.
  private static let volumeListLimit = 100

  let apiKey: String
  let userAgent: String
  let session: URLSession

  /// The series whose names match `query`, best first; Comic Vine stops at 10.
  func searchVolumes(_ query: String) async throws -> [Responses.Volume] {
    try await get(
      "search/",
      [
        "field_list": Self.volumeFields,
        "query": query,
        "resources": "volume",
      ])
  }

  /// Up to 100 volumes whose names contain `name`, newest first.
  ///
  /// Wider than `searchVolumes(_:)`, which can leave a recent series of a common name ("Archie") out.
  func listVolumes(_ name: String) async throws -> [Responses.Volume] {
    // The filter syntax separates filters with commas, so a name's own commas are left out of it.
    let filterName = name.replacingOccurrences(of: ",", with: " ")
    return try await get(
      "volumes/",
      [
        "field_list": Self.volumeFields,
        "filter": "name:\(filterName)",
        "limit": String(Self.volumeListLimit),
        "sort": "start_year:desc",
      ])
  }

  /// The issues numbered `number` in any of the volumes.
  func findIssues(inVolumes volumeIDs: [Int], number: String) async throws -> [Responses.IssueSummary] {
    let volumes = volumeIDs.map(String.init).joined(separator: "|")
    return try await get(
      "issues/",
      [
        "field_list": "cover_date,id,issue_number,name,site_detail_url,volume",
        "filter": "volume:\(volumes),issue_number:\(number)",
      ])
  }

  /// One issue, credits and all.
  func issue(_ id: Int) async throws -> Responses.Issue {
    try await get("issue/4000-\(id)/", [:])
  }

  /// One volume: its publisher, start year and issue count.
  func volume(_ id: Int) async throws -> Responses.Volume {
    try await get("volume/4050-\(id)/", ["field_list": Self.volumeFields])
  }

  /// Calls one API resource and decodes its results.
  private func get<Results: Decodable>(_ path: String, _ parameters: [String: String]) async throws -> Results {
    let parameters = parameters.merging(["api_key": apiKey, "format": "json"]) { _, added in added }
    var components = URLComponents(url: Self.baseURL.appending(path: path), resolvingAgainstBaseURL: false)!
    components.queryItems = parameters.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }

    var request = URLRequest(url: components.url!)
    request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
    let (data, response) = try await session.data(for: request)

    if let response = response as? HTTPURLResponse, response.statusCode != 200 {
      throw ComicVineError.httpStatus(response.statusCode)
    }
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    // The status is read first: an error response's results are an empty list, whatever was asked for.
    let status = try decoder.decode(Responses.Status.self, from: data)
    guard status.statusCode == 1 else { throw ComicVineError.api(status.error) }
    return try decoder.decode(Responses.Envelope<Results>.self, from: data).results
  }
}
