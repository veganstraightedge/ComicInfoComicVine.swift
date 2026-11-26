//
// ComicVine.swift
// ComicInfoComicVine
//

import ComicInfo
import Foundation

/// Looks up comic details in [Comic Vine](https://comicvine.gamespot.com).
///
/// ```swift
/// let comicVine = ComicVine(apiKey: key, userAgent: "MyApp/1.0")
/// let matches = try await comicVine.matches(for: issue)
/// let found = try await comicVine.issue(for: matches[0])
/// let updated = issue.fillingBlanks(from: found)
/// ```
///
/// Comic Vine's terms: non-commercial use only, and whatever shows its data links back to it.
/// An API key comes with a free account: https://comicvine.gamespot.com/api/
public struct ComicVine: ComicInfo.MetadataSource {
  public let name = "Comic Vine"
  public let homeURL = URL(string: "https://comicvine.gamespot.com/")!

  private let client: Client

  /// - Parameters:
  ///   - apiKey: The account's Comic Vine API key.
  ///   - userAgent: Names the app, such as "MyApp/1.0". Comic Vine refuses generic HTTP clients.
  ///   - session: The URL session requests are made with.
  public init(apiKey: String, userAgent: String, session: URLSession = .shared) {
    client = Client(apiKey: apiKey, userAgent: userAgent, session: session)
  }

  public func missingDetails(for issue: ComicInfo.Issue) -> String? {
    guard Self.isBlank(issue.series) || Self.isBlank(issue.number) else { return nil }
    return "Comic Vine needs a Series and a Number to search for."
  }

  /// The issues with the issue's number in every series whose name matches its series.
  ///
  /// Comic Vine's search finds the best few series, and its list finds up to 100 more, newest
  /// first, so a recent series of a common name isn't missed.
  public func matches(for issue: ComicInfo.Issue) async throws -> [ComicInfo.Match] {
    let series = issue.series ?? ""
    let number = issue.number ?? ""
    async let searched = client.searchVolumes(series)
    async let listed = client.listVolumes(series)
    let (searchedVolumes, listedVolumes) = try await (searched, listed)

    var volumesByID: [Int: Responses.Volume] = [:]
    var searchedIDs: [Int] = []
    var listedIDs: [Int] = []
    for volume in searchedVolumes where volumesByID[volume.id] == nil {
      volumesByID[volume.id] = volume
      searchedIDs.append(volume.id)
    }
    for volume in listedVolumes where volumesByID[volume.id] == nil {
      volumesByID[volume.id] = volume
      listedIDs.append(volume.id)
    }

    // The issues list stops at 100 results, so the search's few, best series are asked about apart
    // from the list's many, and first.
    var issues: [Responses.IssueSummary] = []
    for ids in [searchedIDs, listedIDs] where !ids.isEmpty {
      issues += try await client.findIssues(inVolumes: ids, number: number)
    }

    var seen = Set<Int>()
    let matches = issues.filter { seen.insert($0.id).inserted }.map { found in
      Self.match(found, in: volumesByID[found.volume.id])
    }
    return matches.ranked(for: issue)
  }

  public func issue(for match: ComicInfo.Match) async throws -> ComicInfo.Issue {
    guard let id = Int(match.id) else { throw ComicVineError.api("No issue with the ID \(match.id)") }
    let found = try await client.issue(id)
    let volume = try await client.volume(found.volume.id)
    return IssueMapping(issue: found, volume: volume).issue
  }

  private static func match(_ found: Responses.IssueSummary, in volume: Responses.Volume?) -> ComicInfo.Match {
    let series = found.volume.name ?? volume?.name ?? ""
    let year = volume?.startYear.map { " (\($0))" } ?? ""
    let coverDate = "Cover date " + (nonBlank(found.coverDate) ?? "unknown")
    let details = [volume?.publisher?.name, coverDate].compactMap(nonBlank).joined(separator: " · ")
    return ComicInfo.Match(
      id: String(found.id),
      heading: "\(series)\(year) #\(found.issueNumber ?? "")",
      series: series,
      number: found.issueNumber,
      coverDate: found.coverDate,
      title: nonBlank(found.name),
      details: details,
      siteURL: found.siteDetailUrl.flatMap(URL.init(string:))
    )
  }

  static func nonBlank(_ text: String?) -> String? {
    guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
    return text
  }

  private static func isBlank(_ text: String?) -> Bool { nonBlank(text) == nil }
}
